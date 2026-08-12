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

  block_public_acls       = !var.enable_public_read
  block_public_policy     = !var.enable_public_read
  ignore_public_acls      = !var.enable_public_read
  restrict_public_buckets = !var.enable_public_read
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Statement = concat(
      var.enable_public_read ? [{
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Principal = "*"
        Resource  = "${aws_s3_bucket.site.arn}/*"
        Sid       = "PublicReadGetObject"
      }] : [],
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
      }],
      length(var.reader_principal_arns) == 0 ? [] : [{
        Action = "s3:ListBucket"
        Effect = "Allow"
        Principal = {
          AWS = var.reader_principal_arns
        }
        Resource = aws_s3_bucket.site.arn
        Sid      = "AllowPrivateReadersToList"
        }, {
        Action = "s3:GetObject"
        Effect = "Allow"
        Principal = {
          AWS = var.reader_principal_arns
        }
        Resource = "${aws_s3_bucket.site.arn}/*"
        Sid      = "AllowPrivateReadersToGetObjects"
      }]
    )
    Version = "2012-10-17"
  })

  depends_on = [aws_s3_bucket_public_access_block.site]

  lifecycle {
    precondition {
      condition     = var.enable_public_read || var.cloudfront_distribution_arn != null || length(var.reader_principal_arns) > 0
      error_message = "At least one S3 object reader must be configured."
    }
  }
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
