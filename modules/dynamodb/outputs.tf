output "dynamodb_table_name" {
  description = "The name of the DynamoDB table."
  value       = aws_dynamodb_table.image_labels_table.name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table."
  value       = aws_dynamodb_table.image_labels_table.arn
}

output "dynamodb_gsi_name" {
  description = "The name of the Global Secondary Index."
  value       = var.gsi_name
}