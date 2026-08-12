variable "aws_region" {
  description = "AWS Region containing the S3 bucket"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket mounted and served by nginx"
  type        = string
}
