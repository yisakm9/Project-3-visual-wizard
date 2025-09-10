variable "api_name" {
  description = "The name of the API Gateway."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "The ARN of the Lambda function to invoke."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the API Gateway."
  type        = map(string)
  default     = {}
}