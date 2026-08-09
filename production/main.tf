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

output "cloudfront_domain_name" {
  value = module.cloudfront.domain_name
}
