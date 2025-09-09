variable "role_name" {
  description = "The name of the IAM role."
  type        = string
}

variable "policy_name" {
  description = "The name of the IAM policy."
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket to allow read access."
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue to allow read access."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table to allow write access."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the IAM role."
  type        = map(string)
  default     = {}
}