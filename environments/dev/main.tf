# environments/dev/main.tf
module "kms" {
  source       = "../../modules/kms"
  project_name = var.project_name
}

# Create the S3  bucket
module "s3_storage" {
  source                        = "../../modules/s3"
  project_name                  = var.project_name
  image_processing_lambda_arn   = module.lambda_image_processing.function_arn
  # lambda_s3_permission          = module.lambda_image_processing.s3_permission
  force_destroy_s3_bucket       = true # Safe for dev environment
  kms_key_arn                   = module.kms.key_arn 
}

# Create the DynamoDB  table
module "dynamodb_metadata" {
  source       = "../../modules/dynamodb"
  project_name = var.project_name
}

# Create the IAM roles
module "iam_roles" {
  source             = "../../modules/iam"
  project_name       = var.project_name
  s3_bucket_arn      = module.s3_storage.bucket_arn
  dynamodb_table_arn = module.dynamodb_metadata.table_arn
  kms_key_arn        = module.kms.key_arn 
}

# Create the API Gateway
module "api_search" {
  source                   = "../../modules/api_gateway"
  project_name             = var.project_name
  search_lambda_invoke_arn = module.lambda_search_by_label.invoke_arn
  search_lambda_function_name   = module.lambda_search_by_label.function_name # Pass the function name
}

# Deploy the image processing Lambda function
module "lambda_image_processing" {
  source      = "../../modules/lambda_function"
  project_name  = var.project_name
  function_name = "image-processing"
  source_path   = "../../src/image_processing/"
  handler       = "image_processing.handler"
  runtime       = "python3.9"
  iam_role_arn  = module.iam_roles.image_processing_lambda_role_arn
  timeout       = 60
  #s3_bucket_arn = module.s3_storage.bucket_arn
  environment_variables = {
    DYNAMODB_TABLE_NAME = module.dynamodb_metadata.table_name
  }
}

# Deploy the search by label Lambda function
module "lambda_search_by_label" {
  source                    = "../../modules/lambda_function"
  project_name              = var.project_name
  function_name             = "search-by-label"
  source_path               = "../../src/search_by_label/"
  handler                   = "search_by_label.handler"
  runtime                   = "python3.9"
  iam_role_arn              = module.iam_roles.search_by_label_lambda_role_arn
  #api_gateway_execution_arn = module.api_search.execution_arn
  environment_variables = {
    DYNAMODB_TABLE_NAME = module.dynamodb_metadata.table_name
    DYNAMODB_INDEX_NAME = module.dynamodb_metadata.labels_index_name
  }
}