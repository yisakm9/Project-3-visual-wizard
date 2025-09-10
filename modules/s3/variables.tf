variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "sqs_queue_arn_for_notifications" {
  description = "The ARN of the SQS queue to send notifications to."
  type        = string
  default     = null
}