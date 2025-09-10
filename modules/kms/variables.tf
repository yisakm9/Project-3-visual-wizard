variable "key_alias_name" {
  description = "The alias for the KMS key."
  type        = string
}

variable "deletion_window_in_days" {
  description = "The waiting period in days before a key is permanently deleted."
  type        = number
  default     = 7
}

variable "tags" {
  description = "A map of tags to assign to the key."
  type        = map(string)
  default     = {}
}