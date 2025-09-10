variable "table_name" {
  description = "The name of the DynamoDB table."
  type        = string
}

variable "partition_key" {
  description = "The name of the partition key attribute."
  type        = string
}

variable "sort_key" {
  description = "The name of the sort key attribute."
  type        = string
  default     = null
}

variable "gsi_name" {
  description = "The name of the Global Secondary Index."
  type        = string
}

variable "gsi_partition_key" {
  description = "The name of the GSI partition key attribute."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the table."
  type        = map(string)
  default     = {}
}