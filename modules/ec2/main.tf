data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
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

resource "aws_iam_role_policy" "s3_read" {
  name = "s3-read-${var.bucket_name}"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "s3:ListBucket"
      Effect   = "Allow"
      Resource = "arn:aws:s3:::${var.bucket_name}"
      }, {
      Action   = "s3:GetObject"
      Effect   = "Allow"
      Resource = "arn:aws:s3:::${var.bucket_name}/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "tf01-front"
  role = aws_iam_role.ec2.name
}

resource "aws_default_vpc" "ec2" {
  tags = {}
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
    cidr_blocks      = []
    description      = "Allow HTTP from CloudFront"
    from_port        = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = [data.aws_ec2_managed_prefix_list.cloudfront.id]
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
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  instance_type               = "t3.micro"
  key_name                    = "tf01-front"
  private_ip                  = "172.31.25.63"
  source_dest_check           = true
  subnet_id                   = aws_default_subnet.ec2.id
  user_data                   = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf install -y nginx mount-s3
    mkdir -p /var/www/site /etc/systemd/system/nginx.service.d
    sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf

    cat >/etc/systemd/system/mount-s3.service <<'UNIT'
    [Unit]
    Description=Mount the static site S3 bucket
    Wants=network-online.target
    After=network-online.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/mount-s3 ${var.bucket_name} /var/www/site --read-only --allow-other --foreground --region ${var.aws_region}
    ExecStop=/usr/bin/umount /var/www/site
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    UNIT

    cat >/etc/nginx/nginx.conf <<'NGINX'
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log notice;
    pid /run/nginx.pid;

    events {
      worker_connections 1024;
    }

    http {
      include /etc/nginx/mime.types;
      default_type application/octet-stream;
      sendfile on;

      server {
        listen 80 default_server;
        server_name _;
        root /var/www/site;
        index index.html;

        location / {
          try_files $uri $uri/ /index.html;
        }
      }
    }
    NGINX

    cat >/etc/systemd/system/nginx.service.d/mount-s3.conf <<'UNIT'
    [Unit]
    Requires=mount-s3.service
    After=mount-s3.service
    UNIT

    systemctl daemon-reload
    systemctl enable --now mount-s3.service nginx.service
  EOF
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]

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

output "instance_id" {
  value = aws_instance.front.id
}

output "public_dns" {
  value = aws_instance.front.public_dns
}

output "role_arn" {
  value = aws_iam_role.ec2.arn
}
