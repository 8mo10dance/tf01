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
  source = "../modules/static-site"
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
