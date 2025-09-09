variable "aws_region" {
  description = "The AWS region to deploy the resources in."
  type        = string
}

variable "project_name" {
  description = "The name of the project, used as a prefix for resource names."
  type        = string
}

variable "environment" {
  description = "The name of the environment (e.g., dev, prod)."
  type        = string
}