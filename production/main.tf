terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "alb" {
  source = "../modules/alb"

  name               = "tf01-alb"
  security_group_ids = ["sg-05d17250f04417930"]
  subnet_ids         = ["subnet-07368c60eaae5e97e", "subnet-09bbd3f41c9d0d432"]
  target_id          = module.ec2.instance_id
  target_group_name  = "tf01-tg"
  vpc_id             = "vpc-0042c5c5b7d045878"
}

module "ec2" {
  source = "../modules/ec2"

  ecr_repository_arn = module.ecr.repository_arn
  nginx_image_uri    = "949926374137.dkr.ecr.ap-northeast-1.amazonaws.com/tf01-nginx@sha256:5cea44c96902b665b4b700523e269f17e055164601290ca5d8cd63cd7cb9534d"
}

module "ecr" {
  source = "../modules/ecr"

  repository_name = "tf01-nginx"
}

module "github_actions_ecr" {
  source = "../modules/github-actions-ecr"

  ecr_repository_arn = module.ecr.repository_arn
  github_owner       = "8mo10dance"
  github_repository  = "tf01"
  role_name          = "tf01-github-actions-ecr-push"
}

import {
  to = module.ecr.aws_ecr_repository.nginx
  id = "tf01-nginx"
}

import {
  to = module.ecr.aws_ecr_lifecycle_policy.nginx
  id = "tf01-nginx"
}

import {
  to = module.ec2.aws_default_vpc.ec2
  id = "vpc-0042c5c5b7d045878"
}

import {
  to = module.ec2.aws_default_subnet.ec2
  id = "subnet-07368c60eaae5e97e"
}

import {
  to = module.ec2.aws_security_group.ec2
  id = "sg-09eabd6cce4fa75f2"
}

import {
  to = module.ec2.aws_instance.front
  id = "i-0a2b09a199de5febc"
}

import {
  to = module.alb.aws_lb_target_group_attachment.ec2
  identity = {
    account_id        = "949926374137"
    availability_zone = null
    port              = 80
    quic_server_id    = null
    region            = "ap-northeast-1"
    target_group_arn  = "arn:aws:elasticloadbalancing:ap-northeast-1:949926374137:targetgroup/tf01-tg/175cdbdfc044666b"
    target_id         = "i-015bae88afca3cc87"
  }
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "github_actions_ecr_role_arn" {
  value = module.github_actions_ecr.role_arn
}
