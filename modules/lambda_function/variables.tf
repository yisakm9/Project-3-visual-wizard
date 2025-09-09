variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your code."
  type        = string
}

variable "runtime" {
  description = "The identifier of the function's runtime."
  type        = string
}

variable "iam_role_arn" {
  description = "The ARN of the IAM role for the Lambda function."
  type        = string
}

variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue to be used as a trigger."
  type        = string
}

variable "source_code_path" {
  description = "The path to the zipped source code file."
  type        = string
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the source code file."
  type        = string
}

variable "environment_variables" {
  description = "A map of environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to the function."
  type        = map(string)
  default     = {}
}