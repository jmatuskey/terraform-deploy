terraform {
  backend "s3" {
    # backend file expected to fill in here, vars not allowed
  }
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
  }
}

provider "aws" {
  region  = var.region
}

resource "aws_codecommit_repository" "secrets_repo" {
  repository_name = "${var.cluster_name}-secrets"
  description     = "kms encrypted secrets for JupyterHub deployment"
  tags            = {
    Owner = var.owner_tag,
    Terraform = "True"
  }
}
