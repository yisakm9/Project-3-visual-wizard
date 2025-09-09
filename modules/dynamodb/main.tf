# main.tf for DynamoDB

# Creates the DynamoDB table to store image labels
resource "aws_dynamodb_table" "image_labels_table" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ImageKey"

  attribute {
    name = "ImageKey"
    type = "S"
  }

  tags = {
    Name        = var.table_name
    Project     = "Visual-Wizard"
    Environment = var.environment
  }
}