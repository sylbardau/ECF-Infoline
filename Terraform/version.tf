# versions.tf
terraform {
  required_version = ">= 1.15" # [À VÉRIFIER - Source : https://developer.hashicorp.com/terraform/downloads]
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.50" # [À VÉRIFIER - Source : https://registry.terraform.io/providers/hashicorp/aws/latest]
    }
  }
}

provider "aws" {
  region = "eu-west-3" # [Région Paris pour haute disponibilité]
}