variable "ecr_repository_arn" {
  description = "ARN of the ECR repository that the EC2 instance can pull from"
  type        = string
}

variable "nginx_image_uri" {
  description = "Digest-pinned URI of the nginx image to run"
  type        = string

  validation {
    condition     = can(regex("^.+@sha256:[0-9a-f]{64}$", var.nginx_image_uri))
    error_message = "nginx_image_uri must be pinned to a sha256 digest."
  }
}
