variable "role_name" {
  description = "The name for the IAM role."
  type        = string
}

variable "custom_policy_document" {
  description = "A custom IAM policy document in JSON format."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "A list of ARNs for AWS managed policies to attach."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}