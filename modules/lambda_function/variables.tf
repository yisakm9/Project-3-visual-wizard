# variables.tf for Lambda Function

variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "iam_role_arn" {
  description = "The ARN of the IAM role for the Lambda function."
  type        = string
}

variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue."
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table."
  type        = string
}

variable "source_path" {
  description = "The path to the source code directory."
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, prod)."
  type        = string
}