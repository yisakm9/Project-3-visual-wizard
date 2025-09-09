# main.tf for dev environment

# DynamoDB Module for image labels table
module "dynamodb" {
  source      = "../../modules/dynamodb"
  table_name  = "${var.project_name}-image-labels-${var.environment}"
  environment = var.environment
}

# SQS Module for image processing queue
# This module depends on the S3 bucket's ARN for its IAM policy.
module "sqs" {
  source        = "../../modules/sqs"
  queue_name    = "${var.project_name}-image-processing-queue-${var.environment}"
  environment   = var.environment
  s3_bucket_arn = module.s3.bucket_arn
}

# S3 Module for image storage
# This module depends on the SQS queue's ARN for its notification configuration.
module "s3" {
  source        = "../../modules/s3"
  bucket_name   = "${var.project_name}-images-${var.environment}"
  environment   = var.environment
  sqs_queue_arn = module.sqs.queue_arn
}

# IAM Module for Lambda execution role
# This module depends on the ARNs from the S3, SQS, and DynamoDB modules.
module "iam" {
  source             = "../../modules/iam"
  role_name          = "${var.project_name}-lambda-role-${var.environment}"
  sqs_queue_arn      = module.sqs.queue_arn
  s3_bucket_arn      = module.s3.bucket_arn
  dynamodb_table_arn = module.dynamodb.table_arn
}

# Lambda Function Module for image processing
# This module depends on the IAM role, SQS queue, and DynamoDB table.
module "lambda_function" {
  source              = "../../modules/lambda_function"
  function_name       = "${var.project_name}-image-processor-${var.environment}"
  iam_role_arn        = module.iam.role_arn
  sqs_queue_arn       = module.sqs.queue_arn
  dynamodb_table_name = module.dynamodb.table_name
  source_path         = "../../src/image_processing"
  environment         = var.environment

  # Explicitly state that this module depends on the IAM role being fully created.
  depends_on = [module.iam]
}