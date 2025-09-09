variable "api_name" {
  description = "The name for the API Gateway."
  type        = string
}

variable "search_lambda_invoke_arn" {
  description = "The invoke ARN of the search Lambda function."
  type        = string
}

variable "search_lambda_function_name" {
  description = "The name of the search Lambda function for setting permissions."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the API Gateway."
  type        = map(string)
  default     = {}
}