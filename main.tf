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

# Import the existing static website bucket and its related settings.
import {
  to = aws_s3_bucket.site
  id = "my-bucket-949926374137-ap-northeast-1-an"
}

import {
  to = aws_s3_bucket_website_configuration.site
  id = "my-bucket-949926374137-ap-northeast-1-an"
}

import {
  to = aws_s3_bucket_public_access_block.site
  id = "my-bucket-949926374137-ap-northeast-1-an"
}

import {
  to = aws_s3_bucket_policy.site
  id = "my-bucket-949926374137-ap-northeast-1-an"
}

resource "aws_s3_bucket" "site" {
  bucket              = "my-bucket-949926374137-ap-northeast-1-an"
  bucket_namespace    = "account-regional"
  force_destroy       = false
  object_lock_enabled = false
  region              = "ap-northeast-1"
  tags                = {}
  tags_all            = {}
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  region = "ap-northeast-1"

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  region                  = "ap-northeast-1"
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  region = "ap-northeast-1"
  policy = jsonencode({
    Statement = [{
      Action    = "s3:GetObject"
      Effect    = "Allow"
      Principal = "*"
      Resource  = "${aws_s3_bucket.site.arn}/*"
      Sid       = "PublicReadGetObject"
    }]
    Version = "2012-10-17"
  })
}
