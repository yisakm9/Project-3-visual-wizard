# modules/lambda_function/main.tf

# Data source to create a ZIP archive of the Python source code.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_path
  output_path = var.output_path
}

# Create the Lambda function resource.
resource "aws_lambda_function" "function" {
  function_name    = "${var.project_name}-${var.function_name}"
  handler          = var.handler
  runtime          = var.runtime
  role             = var.iam_role_arn
  memory_size      = var.memory_size
  timeout          = var.timeout

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = var.environment_variables
  }
}

# Permission for S3 to invoke this Lambda function (if triggered by S3).
#resource "aws_lambda_permission" "allow_s3" {
#  # Only create this if an s3_bucket_arn is provided.
#  count = var.s3_bucket_arn != null ? 1 : 0

#  statement_id  = "AllowExecutionFromS3Bucket"
 # action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.function.function_name
#  principal     = "s3.amazonaws.com"
#  source_arn    = var.s3_bucket_arn
#}

# Permission for API Gateway to invoke this Lambda function (if triggered by API GW).
#resource "aws_lambda_permission" "allow_api_gateway" {
  # Only create this if an api_gateway_execution_arn is provided.
#  count = var.api_gateway_execution_arn != null ? 1 : 0

#  statement_id  = "AllowExecutionFromAPIGateway"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.function.function_name
# principal     = "apigateway.amazonaws.com"
#  source_arn    = var.api_gateway_execution_arn
#}