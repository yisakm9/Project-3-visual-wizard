variable "queue_name" {
  description = "The name of the SQS queue."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the queue."
  type        = map(string)
  default     = {}
}