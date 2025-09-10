variable "role_name" {
  description = "The name for the IAM role."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the role."
  type        = map(string)
  default     = {}
}