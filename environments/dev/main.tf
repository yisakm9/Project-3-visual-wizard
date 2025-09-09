# main.tf for dev environment

# --- EXISTING RESOURCES (NO CHANGES) ---
module "dynamodb" {
  source      = "../../modules/dynamodb"
  table_name  = "${var.project_name}-image-labels-${var.environment}"
  environment = var.environment
}
module "sqs" {
  source        = "../../modules/sqs"
  queue_name    = "${var.project_name}-image-processing-queue-${var.environment}"
  environment   = var.environment
  s3_bucket_arn = module.s3.bucket_arn
}
module "s3" {
  source        = "../../modules/s3"
  bucket_name   = "${var.project_name}-images-${var.environment}"
  environment   = var.environment
  #sqs_queue_arn = module.sqs.queue_arn
}

# --- NEW RESOURCE TO CREATE THE S3->SQS LINK ---
# This resource now lives in the parent module, breaking the circular dependency.
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.s3.bucket_id # Use bucket_id from the S3 module output

  queue {
    queue_arn     = module.sqs.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }

  # This is crucial: It tells Terraform to wait until the SQS module,
  # including its policy, is fully created before attempting to set up this notification.
  depends_on = [module.sqs]
}

module "iam" {
  source             = "../../modules/iam"
  role_name          = "${var.project_name}-processing-lambda-role-${var.environment}"
  sqs_queue_arn      = module.sqs.queue_arn
  s3_bucket_arn      = module.s3.bucket_arn
  dynamodb_table_arn = module.dynamodb.table_arn
}
module "lambda_function" {
  source              = "../../modules/lambda_function"
  function_name       = "${var.project_name}-image-processor-${var.environment}"
  iam_role_arn        = module.iam.role_arn
  sqs_queue_arn       = module.sqs.queue_arn
  dynamodb_table_name = module.dynamodb.table_name
  source_path         = "../../src/image_processing"
  environment         = var.environment
  create_sqs_trigger  = true
  depends_on          = [module.iam]
}

# --- NEW RESOURCES FOR SEARCH FUNCTIONALITY ---

# Create a new IAM Role specifically for the Search Lambda
resource "aws_iam_role" "search_lambda_role" {
  name = "${var.project_name}-search-lambda-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Create and attach the policy for the Search Lambda's permissions
resource "aws_iam_role_policy_attachment" "search_lambda_policy_attachment" {
  role       = aws_iam_role.search_lambda_role.name
  policy_arn = aws_iam_policy.search_lambda_permissions.arn
}

resource "aws_iam_policy" "search_lambda_permissions" {
  name   = "${var.project_name}-search-lambda-policy-${var.environment}"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = ["dynamodb:Scan"],
        Effect   = "Allow",
        Resource = module.dynamodb.table_arn
      }
    ]
  })
}

# Create the Search Lambda function by instantiating the module again
module "search_lambda_function" {
  source              = "../../modules/lambda_function"
  function_name       = "${var.project_name}-search-by-label-${var.environment}"
  iam_role_arn        = aws_iam_role.search_lambda_role.arn
  dynamodb_table_name = module.dynamodb.table_name
  source_path         = "../../src/search_by_label"
  environment         = var.environment
  create_sqs_trigger  = false
  # We don't need the SQS trigger for this one, but the variable requires a value
  #sqs_queue_arn       = module.sqs.queue_arn 
  depends_on          = [aws_iam_role.search_lambda_role]
}

# API Gateway Module, now connected to the new Search Lambda
module "api_gateway" {
  source                      = "../../modules/api_gateway"
  api_name                    = "${var.project_name}-search-api-${var.environment}"
  environment                 = var.environment
  search_lambda_invoke_arn    = module.search_lambda_function.function_invoke_arn # Make sure to add 'function_invoke_arn' to lambda_function outputs
  search_lambda_function_name = module.search_lambda_function.function_name
}