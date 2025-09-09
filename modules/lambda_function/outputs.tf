output "lambda_function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "lambda_invoke_arn" {
  description = "The Invoke ARN of the Lambda function, used by API Gateway."
  value       = aws_lambda_function.this.invoke_arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}
