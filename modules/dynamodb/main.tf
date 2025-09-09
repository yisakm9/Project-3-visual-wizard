# modules/dynamodb/main.tf

resource "aws_dynamodb_table" "image_metadata" {
  name         = "${var.project_name}-image-metadata"
  billing_mode = "PAY_PER_REQUEST"
  
  # --- CORRECTED: Define a Composite Primary Key ---
  hash_key  = "ImageKey"
  range_key = "Label"

  attribute {
    name = "ImageKey"
    type = "S"
  }
  
  attribute {
    name = "Label"
    type = "S"
  }

  # The GSI is still needed to search by 'Label' across all images.
  global_secondary_index {
    name            = "LabelsIndex"
    hash_key        = "Label"
    projection_type = "ALL"
  }

  tags = {
    Project = var.project_name
  }
}