output "queue_arn" {
  description = "The ARN of the SQS queue."
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "The URL of the SQS queue."
  value       = aws_sqs_queue.this.id
}