variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "test-cluster-change-name"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)
  default = [ ]
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = [
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
  ]
}

variable "username" {
  description = "The name of the primary deployment role"
  type = string
}

#variable "workers_additional_policies" {
#  description = "Additional policies to be added to workers"  
#  type = list(string)
#  default     = ["aws_iam_policy.cluster_autoscaler.arn"]
#}

# -------------------------------------------------------------------------
#                     Networking config

variable vpc_name {
   description = "Name of unmanaged VPC, e.g. created by IT department."
   type = string
}

variable private_subnet_names {
   description = "Patterns applied to Name tag to select unmanaged private subnets from the unmanaged vpc"
   type = list(string)
   default = ["*Private*"]
}

variable public_subnet_names {
   description = "Patterns applied to Name tag to select unmanaged public subnets from the unmanaged vpc"
   type = list(string)
   default = ["*Public*"]
}

variable cluster_sg_name {
   description = "Group added to EKS cluster granting access to API endpoint 443 to members of worker sg."
   type = string
}

variable worker_sg_name {
   description = "Group added to unmanaged workers.  Gives workers access to cluster 443 via the above, cluster access to workers, workers to workers."
   type = string
}

# ========================================================================

variable notebook_instance_type {
   description = "EC2 instance type used for notebook sessions."
   type = string
   default = "r5.xlarge"
}

variable notebook_desired_capacity {
   description = "Initial setting of autoscaler desired instance count for notebook nodes,  autoscaler periodically adjusts for current load."
   type = number
   default = 1
}

variable notebook_min_capacity {
   description = "Minimum number of notebook nodes,  autoscaler won't drop below this regardless of usage."
   type = number
   default = 1
}

variable notebook_max_capacity {
   description = "Maximum number of notebook nodes,  autoscaler won't exceed this regardless of usage."
   type = number
   default = 10
}


# ========================================================================
variable allowed_roles {
    default = []
}

variable cluster_version {
    description = "Kubernetes version used by the EKS module."
    default = "1.21"
    type = string
}
