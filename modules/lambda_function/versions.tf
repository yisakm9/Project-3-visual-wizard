terraform {
  # ADD THIS required_version ATTRIBUTE
  required_version = "~>  1.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.3"
    }
  }
  
}
