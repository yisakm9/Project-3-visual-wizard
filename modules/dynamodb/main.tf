resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  # --- CORRECTED ATTRIBUTE DEFINITIONS ---
  # Define all attributes that will be used as keys anywhere in the table (primary or GSI)
  attribute {
    name = var.partition_key
    type = "S"
  }

  attribute {
    name = var.gsi_partition_key
    type = "S"
  }
  
  # The sort_key attribute is the same as the GSI partition key in our case.
  # If they were different, we would need another attribute block.
  
  # --- PRIMARY KEY DEFINITION ---
  hash_key  = var.partition_key
  # Conditionally set the sort key (range_key) for the primary key
  range_key = var.sort_key

  # --- GSI DEFINITION ---
  global_secondary_index {
    name            = var.gsi_name
    hash_key        = var.gsi_partition_key
    projection_type = "ALL"
  }

  tags = var.tags
}