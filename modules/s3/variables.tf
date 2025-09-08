# modules/s3/variables.tf

variable "project_name" {
  description = "The name of the project, used as a prefix for resources."
  type        = string
}

variable "image_processing_lambda_arn" {
  description = "The ARN of the Lambda function that processes image uploads."
  type        = string
}

variable "lambda_s3_permission" {
  description = "A placeholder to ensure the Lambda permission is created before the notification."
  type        = any
  default     = null
}

variable "force_destroy_s3_bucket" {
  description = "Whether to allow the S3 bucket to be destroyed even if it's not empty."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for S3 bucket encryption."
  type        = string
}