resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = var.partition_key
    type = "S"
  }

  attribute {
    name = var.gsi_partition_key
    type = "S"
  }

  hash_key = var.partition_key

  global_secondary_index {
    name            = var.gsi_name
    hash_key        = var.gsi_partition_key
    projection_type = "ALL"
  }

  tags = var.tags
}