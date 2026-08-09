variable "bucket_name" {
  description = "Name of the S3 bucket used for the static site"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution allowed to read objects"
  type        = string
  default     = null
  nullable    = true
}

variable "force_destroy" {
  description = "Whether to delete all objects when destroying the S3 bucket"
  type        = bool
  default     = false
}
