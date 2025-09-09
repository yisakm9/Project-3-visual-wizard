# modules/dynamodb/main.tf

resource "aws_dynamodb_table" "image_labels_table" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "image_key"
  range_key      = "label"

  attribute {
    name = "image_key"
    type = "S"
  }

  attribute {
    name = "label"
    type = "S"
  }

  global_secondary_index {
    name            = var.gsi_name
    hash_key        = "label"
    projection_type = "KEYS_ONLY"
  }

  tags = var.tags
}