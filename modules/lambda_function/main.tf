resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  handler          = var.handler
  runtime          = var.runtime
  role             = var.iam_role_arn
  filename         = var.source_code_path
  source_code_hash = var.source_code_hash
  timeout          = 30

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "this" {
  count            = var.sqs_queue_arn != "" ? 1 : 0 # Only create if SQS ARN is provided
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = 1
}

