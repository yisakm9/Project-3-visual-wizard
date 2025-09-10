output "queue_arn" {
  description = "The ARN of the SQS queue."
  value       = aws_sqs_queue.this.arn
}

output "queue_id" {
  description = "The ID (URL) of the SQS queue."
  value       = aws_sqs_queue.this.id
}