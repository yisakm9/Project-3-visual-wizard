resource "aws_sqs_queue" "this" {
  name = var.queue_name
  tags = var.tags
}

resource "aws_sqs_queue_policy" "this" {
  # Only create this resource if a policy is actually passed in
  count = var.policy != null ? 1 : 0

  queue_url = aws_sqs_queue.this.id
  policy    = var.policy
}