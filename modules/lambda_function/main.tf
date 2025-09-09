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
  # --- FIX: Change the condition from != "" to != null ---
  # This will correctly evaluate to '0' when sqs_queue_arn is null.
  count = var.sqs_queue_arn != null ? 1 : 0

  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = 1
}

# --- FIX: ADD THE LAMBDA PERMISSION RESOURCE HERE ---
# This resource creates the API Gateway trigger permission
resource "aws_lambda_permission" "api_gateway" {
  # Only create this permission if an API Gateway ARN is provided
  count = var.api_gateway_execution_arn != null ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}