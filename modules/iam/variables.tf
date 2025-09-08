# modules/iam/variables.tf

variable "project_name" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}
variable "kms_key_arn" {
  description = "The ARN of the KMS key to grant permissions to."
  type        = string
}