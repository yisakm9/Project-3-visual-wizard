variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue to send notifications to."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}