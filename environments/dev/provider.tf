# environments/dev/providers.tf

terraform {
  # ADD THIS required_version ATTRIBUTE
  required_version = "~>  1.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}