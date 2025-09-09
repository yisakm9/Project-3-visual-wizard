output "api_endpoint" {
  description = "The invocation URL for the API Gateway."
  value       = aws_apigatewayv2_api.this.api_endpoint
}
output "execution_arn" {
  description = "The execution ARN of the API Gateway to be used in Lambda permissions."
  value       = aws_apigatewayv2_api.this.execution_arn
}