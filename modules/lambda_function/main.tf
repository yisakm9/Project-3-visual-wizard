# main.tf for Lambda Function

# Archives the Python source code into a zip file
data "archive_file" "image_processing_zip" {
  type        = "zip"
  source_dir  = var.source_path
  output_path = "${path.module}/image_processing.zip"
}

# Creates the Lambda function for image processing
resource "aws_lambda_function" "image_processing_lambda" {
  function_name    = var.function_name
  handler          = "image_processing.handler"
  runtime          = "python3.9"
  role             = var.iam_role_arn
  
  filename         = data.archive_file.image_processing_zip.output_path
  source_code_hash = data.archive_file.image_processing_zip.output_base64sha256

  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
    }
  }

  tags = {
    Name        = var.function_name
    Project     = "Visual-Wizard"
    Environment = var.environment
  }
}

# Creates the event source mapping between SQS and Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.image_processing_lambda.arn
  batch_size       = 5 # Process up to 5 messages at a time
}