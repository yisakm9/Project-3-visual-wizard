# modules/api_gateway/variables.tf

variable "project_name" {
  type = string
}

variable "search_lambda_invoke_arn" {
  description = "The invoke ARN of the search_by_label Lambda function."
  type        = string
}