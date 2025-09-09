# variables.tf for DynamoDB

variable "table_name" {
  description = "The name of the DynamoDB table."
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, prod)."
  type        = string
}