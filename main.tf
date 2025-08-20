# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Configure the S3 backend for remote state storage
terraform {
  backend "s3" {
    bucket       = "ysak-terraform-state-bucket"
    key          = "voicevault/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    dynamodb_table = "terraform-state-bucket"
  }
}

  terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" 
    }
  }
}

variable "project_name" {
  description = "The name of the project"
  default     = "visual-wizard"
}

# --- Lambda Function Packaging ---
data "archive_file" "image_processing_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_functions/image_processing/image_processing.py"
  output_path = "${path.module}/dist/image_processing.zip"
}

data "archive_file" "search_by_label_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_functions/search_by_label/search_by_label.py"
  output_path = "${path.module}/dist/search_by_label.zip"
}

# --- AWS Resources (IAM, S3, DynamoDB, Lambda, API Gateway) ---

# S3 Bucket for Image Uploads
resource "aws_s3_bucket" "image_bucket" {
  bucket = "${var.project_name}-image-bucket"
}

# DynamoDB Table to Store Image Labels
resource "aws_dynamodb_table" "image_labels" {
  name         = "${var.project_name}-image-labels"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "image_name"

  attribute {
    name = "image_name"
    type = "S"
  }
}

# IAM Role and Policy for Image Processing Lambda
resource "aws_iam_role" "image_processing_lambda_role" {
  name = "${var.project_name}-image-proc-lambda-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "image_processing_lambda_policy" {
  name   = "${var.project_name}-image-proc-lambda-policy"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = ["s3:GetObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.image_bucket.arn}/*"
      },
      {
        Action   = ["rekognition:DetectLabels"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = ["dynamodb:PutItem"],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.image_labels.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "image_processing_lambda_attachment" {
  role       = aws_iam_role.image_processing_lambda_role.name
  policy_arn = aws_iam_policy.image_processing_lambda_policy.arn
}

# Lambda Function for Image Processing
resource "aws_lambda_function" "image_processing_lambda" {
  function_name = "${var.project_name}-image-processing"
  role          = aws_iam_role.image_processing_lambda_role.arn
  handler       = "image_processing.lambda_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.image_processing_zip.output_path
  source_code_hash = data.archive_file.image_processing_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.image_labels.name
    }
  }
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.image_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processing_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processing_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.image_bucket.arn
}

# --- Resources for the Search API ---

# IAM Role and Policy for Search Lambda
resource "aws_iam_role" "search_lambda_role" {
  name = "${var.project_name}-search-lambda-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "search_lambda_policy" {
  name   = "${var.project_name}-search-lambda-policy"
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
        Resource = aws_dynamodb_table.image_labels.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "search_lambda_attachment" {
  role       = aws_iam_role.search_lambda_role.name
  policy_arn = aws_iam_policy.search_lambda_policy.arn
}

# Lambda Function for Searching
resource "aws_lambda_function" "search_lambda" {
  function_name = "${var.project_name}-search-by-label"
  role          = aws_iam_role.search_lambda_role.arn
  handler       = "search_by_label.lambda_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.search_by_label_zip.output_path
  source_code_hash = data.archive_file.search_by_label_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.image_labels.name
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "api_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.search_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /search"
  target    = "integrations/${aws_apigatewayv2_integration.api_integration.id}"
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.search_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# --- Outputs ---
output "api_endpoint" {
  description = "The URL endpoint for the search API"
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/search"
} 