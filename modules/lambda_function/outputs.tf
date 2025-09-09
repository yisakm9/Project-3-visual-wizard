# outputs.tf for Lambda Function

output "function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.image_processing_lambda.function_name
}

output "function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.image_processing_lambda.arn
}

output "function_invoke_arn" {
  description = "The ARN to be used for invoking the Lambda function."
  value       = aws_lambda_function.image_processing_lambda.invoke_arn
}