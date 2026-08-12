variable "bucket_name" {
  description = "Name used by the retained S3 origin access control"
  type        = string
}

variable "origin_domain_name" {
  description = "DNS name of the nginx origin"
  type        = string
}
