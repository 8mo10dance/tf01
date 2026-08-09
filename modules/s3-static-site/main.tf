resource "aws_s3_bucket" "site" {
  bucket           = var.bucket_name
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
      var.cloudfront_distribution_arn == null ? [] : [{
        Action = "s3:GetObject"
        Condition = {
          ArnLike = {
            "AWS:SourceArn" = var.cloudfront_distribution_arn
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

output "bucket_arn" {
  value = aws_s3_bucket.site.arn
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.site.bucket_regional_domain_name
}
