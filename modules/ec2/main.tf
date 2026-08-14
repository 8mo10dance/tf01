variable "nginx_image_uri" {
  type = string
}

resource "aws_default_vpc" "ec2" {
  tags = {}
}

resource "aws_iam_role" "ec2" {
  name = "tf01-front"

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

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "tf01-front"
  role = aws_iam_role.ec2.name
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
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = true
    to_port          = 0
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
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = "tf01-front"
  private_ip                  = "172.31.25.63"
  source_dest_check           = true
  subnet_id                   = aws_default_subnet.ec2.id
  user_data                   = <<-EOF
    #!/bin/bash
    dnf install -y docker
    systemctl enable --now docker
    aws ecr get-login-password --region ap-northeast-1 \
      | docker login --username AWS --password-stdin 949926374137.dkr.ecr.ap-northeast-1.amazonaws.com
    docker pull ${var.nginx_image_uri}
    docker run --detach \
      --name nginx \
      --publish 80:80 \
      --restart unless-stopped \
      ${var.nginx_image_uri}
  EOF
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  depends_on = [aws_iam_role_policy_attachment.ecr_read_only]

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
