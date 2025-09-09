# variables.tf for SQS

variable "queue_name" {
  description = "The name of the SQS queue."
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, prod)."
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket that will send notifications to the queue."
  type        = string
}