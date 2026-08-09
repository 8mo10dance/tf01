resource "aws_s3_bucket" "site" {
  bucket           = "my-bucket-949926374137-ap-northeast-1-an"
  bucket_namespace = "account-regional"
  force_destroy    = var.force_destroy
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_cloudfront_origin_access_control" "site" {
  description                       = "Created by CloudFront"
  name                              = "oac-my-bucket-949926374137-ap-northeast-1-an.s3.ap-n-mslhh3qm5qc"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  tags = {
    Name = "my-cloud-front"
  }

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
    origin_id                = "my-bucket-949926374137-ap-northeast-1-an.s3.ap-northeast-1.amazonaws.com-mslhgml95x7"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    target_origin_id       = "my-bucket-949926374137-ap-northeast-1-an.s3.ap-northeast-1.amazonaws.com-mslhgml95x7"
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Statement = concat(
      [{
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Principal = "*"
        Resource  = "${aws_s3_bucket.site.arn}/*"
        Sid       = "PublicReadGetObject"
      }],
      [{
        Action = "s3:GetObject"
        Condition = {
          ArnLike = {
            "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Resource = "${aws_s3_bucket.site.arn}/*"
        Sid      = "AllowCloudFrontServicePrincipal"
      }]
    )
    Version = "2012-10-17"
  })

  depends_on = [aws_s3_bucket_public_access_block.site]
}

output "bucket_id" {
  value = aws_s3_bucket.site.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.site.domain_name
}
