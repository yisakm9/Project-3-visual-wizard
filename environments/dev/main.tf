# ------------------------------------------------------------------------------
# DATA SOURCES - Prepare Lambda deployment packages
# ------------------------------------------------------------------------------

data "archive_file" "image_processing_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/image_processing"
  output_path = "${path.module}/dist/image_processing.zip"
}

data "archive_file" "search_by_label_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/search_by_label"
  output_path = "${path.module}/dist/search_by_label.zip"
}

# ------------------------------------------------------------------------------
# CORE INFRASTRUCTURE MODULES
# ------------------------------------------------------------------------------

module "s3" {
  source        = "../../modules/s3"
  bucket_name   = "${var.project_name}-images-${var.environment}"
  
  tags          = var.common_tags
}

module "sqs" {
  source         = "../../modules/sqs"
  queue_name     = "${var.project_name}-queue-${var.environment}"
  tags           = var.common_tags
}

# --- FIX 1: Create the S3 Bucket Notification EXPLICITLY HERE ---
resource "aws_s3_bucket_notification" "image_uploads" {
  bucket = module.s3.bucket_id

  queue {
    queue_arn     = module.sqs.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
  depends_on = [aws_sqs_queue_policy.s3_notification_policy]
}

resource "aws_sqs_queue_policy" "s3_notification_policy" {
  queue_url = module.sqs.queue_url
  policy    = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "s3.amazonaws.com" },
      Action    = "SQS:SendMessage",
      Resource  = module.sqs.queue_arn,
      Condition = { ArnEquals = { "aws:SourceArn" = module.s3.bucket_arn } }
    }]
  })
}


module "dynamodb" {
  source     = "../../modules/dynamodb"
  table_name = "${var.project_name}-labels-${var.environment}"
  hash_key   = "image_key"
  tags       = var.common_tags
}

# ------------------------------------------------------------------------------
# IAM ROLES AND POLICIES
# ------------------------------------------------------------------------------

module "image_processing_iam" {
  source             = "../../modules/iam"
  role_name          = "${var.project_name}-image-processor-role-${var.environment}"
  policy_name        = "${var.project_name}-image-processor-policy-${var.environment}"
  s3_bucket_arn      = module.s3.bucket_arn
  sqs_queue_arn      = module.sqs.queue_arn
  dynamodb_table_arn = module.dynamodb.table_arn
  tags               = var.common_tags
}

# IAM role for the search-by-label Lambda function
module "search_iam" {
  source             = "../../modules/iam"
  role_name          = "${var.project_name}-search-role-${var.environment}"
  policy_name        = "${var.project_name}-search-policy-${var.environment}"
  dynamodb_table_arn = module.dynamodb.table_arn
  
  # Ensure these are null for the search role
  s3_bucket_arn      = null 
  sqs_queue_arn      = null
  
  tags               = var.common_tags
}

# ------------------------------------------------------------------------------
# LAMBDA FUNCTION MODULES
# ------------------------------------------------------------------------------

module "image_processing_lambda" {
  source           = "../../modules/lambda_function"
  function_name    = "${var.project_name}-image-processor-${var.environment}"
  handler          = "image_processing.handler"
  runtime          = "python3.9"
  iam_role_arn     = module.image_processing_iam.role_arn
  sqs_queue_arn    = module.sqs.queue_arn
  source_code_path = data.archive_file.image_processing_lambda.output_path
  source_code_hash = data.archive_file.image_processing_lambda.output_base64sha256
  environment_variables = {
    DYNAMODB_TABLE_NAME = module.dynamodb.table_name
  }
  tags = var.common_tags
}

# Lambda function for searching by label, triggered by API Gateway
module "search_lambda" {
  source           = "../../modules/lambda_function"
  function_name    = "${var.project_name}-search-by-label-${var.environment}"
  handler          = "search_by_label.handler"
  runtime          = "python3.9"
  iam_role_arn     = module.search_iam.role_arn
  source_code_path = data.archive_file.search_by_label_lambda.output_path
  source_code_hash = data.archive_file.search_by_label_lambda.output_base64sha256
  api_gateway_execution_arn = module.api_gateway.execution_arn
  # Ensure this is null for the search lambda
  sqs_queue_arn    = null 
  
  environment_variables = {
    DYNAMODB_TABLE_NAME = module.dynamodb.table_name
  }
  tags = var.common_tags
}
# ------------------------------------------------------------------------------
# API GATEWAY MODULE
# ------------------------------------------------------------------------------

module "api_gateway" {
  source                   = "../../modules/api_gateway"
  api_name                 = "${var.project_name}-api-${var.environment}"
  search_lambda_invoke_arn = module.search_lambda.function_invoke_arn
  tags                     = var.common_tags
}