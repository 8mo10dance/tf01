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

module "site" {
  source = "../modules/s3-static-site"

  bucket_name                 = "my-bucket-949926374137-ap-northeast-1-an"
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
}

module "cloudfront" {
  source = "../modules/cloudfront"

  aws_region  = "ap-northeast-1"
  bucket_name = "my-bucket-949926374137-ap-northeast-1-an"
}

module "ec2" {
  source = "../modules/ec2"
}

import {
  to = module.site.aws_s3_bucket.site
  id = "my-bucket-949926374137-ap-northeast-1-an"
}

import {
  to = module.site.aws_s3_bucket_website_configuration.site
  id = "my-bucket-949926374137-ap-northeast-1-an"
}

import {
  to = module.site.aws_s3_bucket_public_access_block.site
  id = "my-bucket-949926374137-ap-northeast-1-an"
}

import {
  to = module.site.aws_s3_bucket_policy.site
  id = "my-bucket-949926374137-ap-northeast-1-an"
}

import {
  to = module.cloudfront.aws_cloudfront_origin_access_control.site
  id = "E1067EAO0E6YUA"
}

import {
  to = module.cloudfront.aws_cloudfront_distribution.site
  id = "E27L9ZCVF9GWVN"
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

output "cloudfront_domain_name" {
  value = module.cloudfront.domain_name
}
