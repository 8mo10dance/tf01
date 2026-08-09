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

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
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

  depends_on = [aws_s3_bucket_public_access_block.site]
}

output "bucket_id" {
  value = aws_s3_bucket.site.id
}
