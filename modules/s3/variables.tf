# variables.tf for S3

variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, prod)."
  type        = string
}

#variable "sqs_queue_arn" {
#  description = "The ARN of the SQS queue to send notifications to."
#  type        = string
#}