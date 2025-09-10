resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_notification" "this" {
  # Create this notification only if a queue ARN is provided
  count = var.sqs_queue_arn_for_notifications != null ? 1 : 0

  bucket = aws_s3_bucket.this.id

  queue {
    queue_arn     = var.sqs_queue_arn_for_notifications
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".jpg"
  }

  queue {
    queue_arn     = var.sqs_queue_arn_for_notifications
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".png"
  }
}