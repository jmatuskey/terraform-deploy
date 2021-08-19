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


# -------------------------------------------------------------------------
#                     Networking config

variable vpc_name {
   description = "Name of unmanaged VPC, e.g. created by IT department."
   type = string
}

variable private_subnet_names {
   description = "Patterns applied to Name tag to select unmanaged private subnets from the unmanaged vpc"
   type = list(string)
   default = ["*DMZ*"]
}

variable public_subnet_names {
   description = "Patterns applied to Name tag to select unmanaged public subnets from the unmanaged vpc"
   type = list(string)
   default = ["*Public*"]
}
