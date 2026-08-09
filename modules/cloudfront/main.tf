resource "aws_cloudfront_origin_access_control" "site" {
  description                       = "Created by CloudFront"
  name                              = "oac-${var.bucket_name}.s3.ap-n-mslhh3qm5qc"
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
    domain_name              = "${var.bucket_name}.s3.${var.aws_region}.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
    origin_id                = "${var.bucket_name}.s3.${var.aws_region}.amazonaws.com-mslhgml95x7"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    target_origin_id       = "${var.bucket_name}.s3.${var.aws_region}.amazonaws.com-mslhgml95x7"
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

output "distribution_arn" {
  value = aws_cloudfront_distribution.site.arn
}

output "domain_name" {
  value = aws_cloudfront_distribution.site.domain_name
}
