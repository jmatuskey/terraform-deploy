variable "region" {
  default = "us-east-1"
}

variable "rolename" {
  description = "The name of the primary deployment role"
  type = string
}

variable "lambda_rolearn" {
  description = "The ARN of the lambda execution role"
  type = string
}

variable "user_home_efs_id" {
  description = "ID of the user home data EFS volume"
  type = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type = string
}

variable "efs_threshold" {
  description = "EFS size threshold in bytes"
  type = string
}

# -------------------
# SNS Topic variables




