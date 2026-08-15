variable "name" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "target_id" {
  type = string
}

variable "target_group_name" {
  type = string
}

variable "vpc_id" {
  type = string
}
