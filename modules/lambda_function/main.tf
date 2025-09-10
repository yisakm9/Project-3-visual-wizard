resource "aws_lambda_function" "this" {
  function_name = var.function_name
  handler       = var.handler
  runtime       = var.runtime
  role          = var.iam_role_arn

  # The filename and hash are now passed in directly
  filename         = var.filename
  source_code_hash = var.source_code_hash

  timeout = 30 # seconds

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}