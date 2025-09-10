variable "queue_name" {
  description = "The name of the SQS queue."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the queue."
  type        = map(string)
  default     = {}
}

variable "s3_notification_source_arn" {
  description = "The ARN of the S3 bucket that is allowed to send messages. If provided, a policy will be created."
  type        = string
  default     = null
}