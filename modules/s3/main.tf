# main.tf for S3

# Creates the S3 bucket for storing images
resource "aws_s3_bucket" "image_storage" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Project     = "Visual-Wizard"
    Environment = var.environment
  }
}

# Configures the S3 bucket to send notifications to the SQS queue
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.image_storage.id

  queue {
    queue_arn     = var.sqs_queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
}