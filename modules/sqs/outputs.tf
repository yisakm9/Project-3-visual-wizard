# outputs.tf for SQS

output "queue_name" {
  value = aws_sqs_queue.image_processing_queue.name
}

output "queue_arn" {
  value = aws_sqs_queue.image_processing_queue.arn
}

output "queue_url" {
  value = aws_sqs_queue.image_processing_queue.id
}

output "dlq_arn" {
  description = "The ARN of the Dead-Letter Queue."
  value       = aws_sqs_queue.dlq.arn
}