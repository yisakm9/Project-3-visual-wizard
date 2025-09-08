# modules/dynamodb/main.tf

# Create the DynamoDB table to store image metadata and labels.
resource "aws_dynamodb_table" "image_metadata" {
  name         = "${var.project_name}-image-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ImageKey"

  attribute {
    name = "ImageKey"
    type = "S" # String
  }

  # Global Secondary Index (GSI) to allow efficient searching by labels.
  # This is the key to our search functionality.
  global_secondary_index {
    name            = "LabelsIndex"
    hash_key        = "Label"
    projection_type = "ALL" # Include all attributes in the index
  }

  attribute {
    name = "Label"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}