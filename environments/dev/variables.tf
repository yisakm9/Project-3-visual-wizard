variable "image_bucket_name" {
  description = "The name for the S3 bucket to store images."
  type        = string
}

variable "labels_table_name" {
  description = "The name for the DynamoDB table to store image labels."
  type        = string
}
