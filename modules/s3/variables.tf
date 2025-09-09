variable "bucket_name" {
  description = "The name of the S3 bucket to create for image uploads."
  type        = string
}

variable "image_processing_lambda_arn" {
  description = "The ARN of the Lambda function that processes images."
  type        = string
}

variable "lambda_permission_for_s3" {
  description = "A resource to depend on, ensuring the Lambda permission is created before the S3 notification."
  type        = any
}

variable "tags" {
  description = "A map of tags to apply to the S3 bucket."
  type        = map(string)
  default     = {}
}