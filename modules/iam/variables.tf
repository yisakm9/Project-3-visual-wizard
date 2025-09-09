# variables.tf for IAM

variable "role_name" {
  description = "The name for the IAM role."
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue."
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table."
  type        = string
}