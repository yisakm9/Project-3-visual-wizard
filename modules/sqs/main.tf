# main.tf for SQS

# Creates the Dead-Letter Queue (DLQ) to hold failed messages
resource "aws_sqs_queue" "dlq" {
  name = "${var.queue_name}-dlq"

  tags = {
    Name        = "${var.queue_name}-dlq"
    Project     = "Visual-Wizard"
    Environment = var.environment
  }
}

# Creates the main SQS queue for image processing notifications
resource "aws_sqs_queue" "image_processing_queue" {
  name                       = var.queue_name
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 86400 # 1 day
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 300   # 5 minutes

  # Configure the redrive policy to use the DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3 # After 3 failed attempts, send to DLQ
  })

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