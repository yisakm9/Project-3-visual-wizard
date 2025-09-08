# modules/lambda_function/outputs.tf

output "function_name" {
  value = aws_lambda_function.function.function_name
}

output "function_arn" {
  value = aws_lambda_function.function.arn
}

output "invoke_arn" {
  value = aws_lambda_function.function.invoke_arn
}

output "s3_permission" {
  # This output is used as a dependency to ensure permissions are set before notifications.
  value = aws_lambda_permission.allow_s3
}