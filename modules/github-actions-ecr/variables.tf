variable "ecr_repository_arn" {
  description = "ARN of the ECR repository that GitHub Actions can push to"
  type        = string
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_owner_id" {
  description = "Numeric GitHub repository owner ID"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
}

variable "github_repository_id" {
  description = "Numeric GitHub repository ID"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions"
  type        = string
}
