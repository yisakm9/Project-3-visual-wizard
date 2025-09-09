variable "table_name" {
  description = "The name of the DynamoDB table."
  type        = string
}

variable "gsi_name" {
  description = "The name of the Global Secondary Index for querying by label."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the DynamoDB table."
  type        = map(string)
  default     = {}
}