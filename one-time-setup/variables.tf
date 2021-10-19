variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the deployment, e.g. tike, roman, jwebbinar, ..."
  type = string
}

variable "environment" {
  description = "Name of the deployment, e.g. sandbox, dev, test, prod, ..."
  type = string
}

variable "owner_tag" {
  description = "This is for ITSD to track ownership"
  type = string
}
