variable "aws_region" {
  description = "The AWS region where the resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project, used as a prefix for all resources."
  type        = string
  default     = "visual-wizard"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources."
  type        = map(string)
  default = {
    Project     = "VisualWizard"
    ManagedBy   = "Terraform"
  }
}