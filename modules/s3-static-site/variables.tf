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

variable "reader_principal_arns" {
  description = "IAM principal ARNs allowed to read the private bucket"
  type        = list(string)
  default     = []
}

variable "enable_public_read" {
  description = "Whether to allow anonymous reads of objects in the bucket"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Whether to delete all objects when destroying the S3 bucket"
  type        = bool
  default     = false
}
