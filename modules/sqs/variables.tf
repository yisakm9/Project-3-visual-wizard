variable "queue_name" {
  description = "The name of the SQS queue."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the queue."
  type        = map(string)
  default     = {}
}

variable "kms_key_id" {
  description = "The ID of the KMS key to use for queue encryption."
  type        = string
  default     = null # Make it optional
}