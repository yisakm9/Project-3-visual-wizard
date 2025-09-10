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

# --- IAM RESOURCES FOR IMAGE PROCESSING LAMBDA ---

# 1. Define the policy content, referencing resources that will be created.
data "aws_iam_policy_document" "image_processing_lambda_policy_doc" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.image_bucket.bucket_arn}/*"]
  }
  statement {
    actions   = ["rekognition:DetectLabels"]
    resources = ["*"]
  }
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [module.labels_table.table_arn]
  }
}

# 2. Create a standalone, managed IAM policy from the document.
resource "aws_iam_policy" "image_processing_policy" {
  name   = "visual-wizard-image-processing-policy-dev"
  policy = data.aws_iam_policy_document.image_processing_lambda_policy_doc.json
}

# AWS managed policy for basic Lambda logging
data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. Create the role and attach both the basic execution policy and our new custom policy.
module "image_processing_lambda_iam_role" {
  source = "../../modules/iam"

  role_name = "visual-wizard-image-processing-role-dev"
  managed_policy_arns = [
    data.aws_iam_policy.lambda_basic_execution.arn,
    aws_iam_policy.image_processing_policy.arn
  ]
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}