# modules/s3/main.tf

# Create a unique, private S3 bucket to store the images.
resource "aws_s3_bucket" "photo_storage" {
  # Bucket names must be globally unique. We use a random suffix to ensure this.
  bucket_prefix = "${var.project_name}-photo-storage-"

  # Enforce private access at the bucket level as a security best practice.
  # We will grant access via IAM policies and bucket policies.
  force_destroy = var.force_destroy_s3_bucket # Useful for dev environments to allow easy cleanup.
}

# Block all public access to the S3 bucket.
resource "aws_s3_bucket_public_access_block" "photo_storage_public_access" {
  bucket = aws_s3_bucket.photo_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure server-side encryption for data at rest.
resource "aws_s3_bucket_server_side_encryption_configuration" "photo_storage_encryption" {
  bucket = aws_s3_bucket.photo_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Configure event notifications to trigger the image processing Lambda.
resource "aws_s3_bucket_notification" "photo_upload_notification" {
  bucket = aws_s3_bucket.photo_storage.id

  lambda_function {
    lambda_function_arn = var.image_processing_lambda_arn
    events              = ["s3:ObjectCreated:*"]
  }

  # This depends on the Lambda permission being created first.
  depends_on = [var.lambda_s3_permission]
}