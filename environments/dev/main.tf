# --- DATA SOURCES ---

# AWS managed policy for basic Lambda logging to CloudWatch
data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# This policy defines the specific permissions our Lambda needs
data "aws_iam_policy_document" "image_processing_lambda_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.image_bucket.bucket_arn}/*"]
  }
  statement {
    actions   = ["rekognition:DetectLabels"]
    resources = ["*"]
  }
  statement {
    actions   = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
    resources = [module.labels_table.table_arn]
  }
}

# --- MODULES ---

module "image_bucket" {
  source = "../../modules/s3"

  bucket_name = var.image_bucket_name
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

module "labels_table" {
  source = "../../modules/dynamodb"

  table_name        = var.labels_table_name
  partition_key     = "ImageKey"
  gsi_name          = "LabelIndex"
  gsi_partition_key = "Label"
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

module "image_processing_lambda_iam_role" {
  source = "../../modules/iam"

  role_name             = "visual-wizard-image-processing-role-dev"
  custom_policy_document = data.aws_iam_policy_document.image_processing_lambda_policy.json
  managed_policy_arns   = [data.aws_iam_policy.lambda_basic_execution.arn]
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}