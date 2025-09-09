# outputs.tf for DynamoDB

output "table_name" {
  value = aws_dynamodb_table.image_labels_table.name
}

output "table_arn" {
  value = aws_dynamodb_table.image_labels_table.arn
}