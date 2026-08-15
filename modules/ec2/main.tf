resource "aws_default_vpc" "ec2" {
  tags = {}
}

resource "aws_iam_role" "ecr_pull" {
  name = "tf01-front-ecr-pull"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "ecr_pull" {
  name = "ecr-pull"
  role = aws_iam_role.ecr_pull.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["ecr:GetAuthorizationToken"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]
      Effect   = "Allow"
      Resource = var.ecr_repository_arn
    }]
  })
}

resource "aws_iam_instance_profile" "ecr_pull" {
  name = "tf01-front-ecr-pull"
  role = aws_iam_role.ecr_pull.name
}

resource "aws_default_subnet" "ec2" {
  availability_zone       = "ap-northeast-1d"
  map_public_ip_on_launch = true
  tags                    = {}
}

resource "aws_security_group" "ec2" {
  name        = "default"
  description = "default VPC security group"
  vpc_id      = aws_default_vpc.ec2.id

  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow HTTP"
    from_port        = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 80
    }, {
    cidr_blocks      = []
    description      = ""
    from_port        = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = ["sg-05d17250f04417930"]
    self             = false
    to_port          = 80
  }]

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
}

resource "aws_instance" "front" {
  ami                         = "ami-0b4d2909a55ed2c78"
  associate_public_ip_address = true
  availability_zone           = "ap-northeast-1d"
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.ecr_pull.name
  instance_type               = "t3.micro"
  key_name                    = "tf01-front"
  private_ip                  = "172.31.25.63"
  source_dest_check           = true
  subnet_id                   = aws_default_subnet.ec2.id
  user_data                   = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf install -y docker
    systemctl enable --now docker

    for login_attempt in $(seq 1 12); do
      if aws ecr get-login-password --region ap-northeast-1 \
        | docker login --username AWS --password-stdin 949926374137.dkr.ecr.ap-northeast-1.amazonaws.com; then
        break
      fi

      if [ "$login_attempt" -eq 12 ]; then
        exit 1
      fi

      sleep 5
    done

    docker pull ${var.nginx_image_uri}
    docker run --detach \
      --name nginx \
      --publish 80:80 \
      --restart unless-stopped \
      ${var.nginx_image_uri}
  EOF
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  depends_on = [aws_iam_role_policy.ecr_pull]

  tags = {
    Name = "tf01-front"
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    iops                  = 3000
    throughput            = 125
    volume_size           = 8
    volume_type           = "gp3"
  }
}
