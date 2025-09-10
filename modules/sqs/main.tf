resource "aws_sqs_queue" "this" {
  name = var.queue_name
  tags = var.tags
}

# This policy document defines the permissions
data "aws_iam_policy_document" "queue_policy_doc" {
  # Only create this if the s3_notification_source_arn is provided
  count = var.s3_notification_source_arn != null ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.s3_notification_source_arn]
    }
  }
}

# This attaches the policy to the queue
resource "aws_sqs_queue_policy" "this" {
  # Only create this if the s3_notification_source_arn is provided
  count = var.s3_notification_source_arn != null ? 1 : 0

  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.queue_policy_doc[0].json
}