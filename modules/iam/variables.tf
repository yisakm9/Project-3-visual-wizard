variable "function_name_prefix" {
  description = "A prefix for the IAM role and policy names to ensure they are unique."
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket to grant read permissions to."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table to grant permissions to."
  type        = string
}

variable "dynamodb_gsi_name" {
  description = "The name of the Global Secondary Index for the DynamoDB table."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the IAM resources."
  type        = map(string)
  default     = {}
}