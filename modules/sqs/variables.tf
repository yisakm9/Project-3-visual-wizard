variable "queue_name" {
  description = "The name of the SQS queue."
  type        = string
}



variable "delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed."
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it."
  type        = number
  default     = 262144
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message."
  type        = number
  default     = 345600
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive."
  type        = number
  default     = 10
}

variable "tags" {
  description = "A map of tags to assign to the queue."
  type        = map(string)
  default     = {}
}