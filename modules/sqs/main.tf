# main.tf for SQS

# Creates the SQS queue for image processing notifications
resource "aws_sqs_queue" "image_processing_queue" {
  name                       = var.queue_name
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 86400 # 1 day
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 300   # 5 minutes, allowing ample time for the Lambda to process

  tags = {
    Name        = var.queue_name
    Project     = "Visual-Wizard"
    Environment = var.environment
  }
}

# Applies a policy to the SQS queue to allow S3 to send messages
resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.image_processing_queue.id
  policy    = data.aws_iam_policy_document.sqs_policy_document.json
}

# Defines the IAM policy document for the SQS queue
data "aws_iam_policy_document" "sqs_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["SQS:SendMessage"]
    resources = [aws_sqs_queue.image_processing_queue.arn]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.s3_bucket_arn]
    }
  }
}