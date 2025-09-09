# environments/dev/main.tf
# CORRECTED AND VERIFIED - NO DUPLICATE RESOURCES

# Define local tags for consistent resource tagging
locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --- Module Definitions ---

module "dynamodb" {
  source     = "../../modules/dynamodb"
  table_name = "${var.project_name}-table-${var.environment}"
  gsi_name   = "label-index"
  tags       = local.tags
}

module "image_processing_lambda" {
  source = "../../modules/lambda_function"

  function_name = "${var.project_name}-image-processing-${var.environment}"
  handler       = "image_processing.handler"
  source_path   = "../../src/image_processing/"
  role_arn      = module.iam.image_processing_lambda_role_arn
  timeout       = 60

  environment_variables = {
    DYNAMODB_TABLE_NAME = module.dynamodb.dynamodb_table_name
  }
  tags = local.tags
}

# This permission MUST be defined before the S3 and IAM modules are called
# because they both depend on it or its dependencies.
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.image_processing_lambda.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3.s3_bucket_arn
}

module "s3" {
  source = "../../modules/s3"

  bucket_name                 = "${var.project_name}-images-${var.environment}"
  image_processing_lambda_arn = module.image_processing_lambda.lambda_function_arn
  lambda_permission_for_s3    = aws_lambda_permission.allow_s3_invoke # This passes the dependency
  tags                        = local.tags
}

module "iam" {
  source = "../../modules/iam"

  function_name_prefix = "${var.project_name}-${var.environment}"
  s3_bucket_arn        = module.s3.s3_bucket_arn
  dynamodb_table_arn   = module.dynamodb.dynamodb_table_arn
  dynamodb_gsi_name    = module.dynamodb.dynamodb_gsi_name
  tags                 = local.tags
}

module "search_by_label_lambda" {
  source = "../../modules/lambda_function"

  function_name = "${var.project_name}-search-by-label-${var.environment}"
  handler       = "search_by_label.handler"
  source_path   = "../../src/search_by_label/"
  role_arn      = module.iam.search_by_label_lambda_role_arn

  environment_variables = {
    DYNAMODB_TABLE_NAME = module.dynamodb.dynamodb_table_name
    DYNAMODB_INDEX_NAME = module.dynamodb.dynamodb_gsi_name
  }
  tags = local.tags
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  api_name                    = "${var.project_name}-api-${var.environment}"
  search_lambda_invoke_arn    = module.search_by_label_lambda.lambda_invoke_arn
  search_lambda_function_name = module.search_by_label_lambda.lambda_function_name
  tags                        = local.tags
}