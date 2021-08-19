terraform {
   required_version = "~> 1.0.3"
   required_providers {
      aws = {
          source  = "hashicorp/aws"
          version = "~> 3.51.0"
      }
      template = {
          source  = "hashicorp/template"
          version = "~> 2.2.0"
      }
      helm = {
          source  = "hashicorp/helm"
          version = "~> 2.2.0"
      }
      null = {
          source  = "hashicorp/null"
          version = "~> 3.1.0"
      }
      local = {
          source = "hashicorp/local"
          version = "~> 2.1.0"
      }
   }
}

provider "aws" {
  region  = var.region
}
