# environments/dev/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "project_name" {
  description = "A unique name for the project."
  type        = string
}