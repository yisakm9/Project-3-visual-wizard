variable "role_name" {
  description = "The name for the IAM role."
  type        = string
}

variable "policy_arn" {
  description = "The ARN of the IAM policy to attach to the role."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}