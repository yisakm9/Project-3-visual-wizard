# modules/dynamodb/outputs.tf

output "table_name" {
  description = "The name of the DynamoDB table."
  value       = aws_dynamodb_table.image_metadata.name
}

output "table_arn" {
  description = "The ARN of the DynamoDB table."
  value       = aws_dynamodb_table.image_metadata.arn
}

output "labels_index_name" {
  description = "The name of the Global Secondary Index for labels."
  value       = "LabelsIndex"
}