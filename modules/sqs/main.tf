resource "aws_sqs_queue" "this" {
  name = var.queue_name
  tags = var.tags
}