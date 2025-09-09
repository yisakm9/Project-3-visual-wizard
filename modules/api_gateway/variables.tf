variable "api_name" {
  description = "The name of the API Gateway."
  type        = string
}

variable "search_lambda_invoke_arn" {
  description = "The ARN to be used for invoking the search Lambda function."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the API Gateway."
  type        = map(string)
  default     = {}
}