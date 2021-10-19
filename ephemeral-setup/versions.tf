terraform {
   backend "s3" {  
     # backend file expected to fill in here, vars not allowed 
   }
   required_version = "~> 1.0.3"
   required_providers {
      aws = {
          source  = "hashicorp/aws"
          version = "~> 3.63.0"
      }
      template = {
          source  = "hashicorp/template"
          version = "~> 2.2.0"
      }
      kubernetes = {
          source  = "hashicorp/kubernetes"
          version = "~> 2.3.2"
      }
      cloudinit = {
	  source = "hashicorp/cloudinit"
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
      http = {
          source = "terraform-aws-modules/http"
          version = "~> 2.4.1"
      }
   }
}

provider "aws" {
  region  = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  #load_config_file       = false
}

provider "helm" {
  kubernetes {
     host                   = data.aws_eks_cluster.cluster.endpoint
     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
     token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
