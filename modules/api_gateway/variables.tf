# variables.tf for API Gateway

variable "api_name" {
  description = "The name of the REST API."
  type        = string
}

variable "environment" {
  description = "The deployment stage name (e.g., dev)."
  type        = string
}

variable "search_lambda_invoke_arn" {
  description = "The ARN to be used for invoking the search Lambda function."
  type        = string
}

variable "search_lambda_function_name" {
  description = "The name of the search Lambda function."
  type        = string
}