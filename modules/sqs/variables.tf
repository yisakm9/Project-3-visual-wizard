variable "queue_name" {
  description = "The name of the SQS queue."
  type        = string
}

variable "policy" {
  description = "An IAM policy document to attach to the SQS queue."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the queue."
  type        = map(string)
  default     = {}
}