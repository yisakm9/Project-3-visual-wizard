output "api_endpoint" {
  description = "The invocation URL for the API Gateway."
  value       = aws_apigatewayv2_api.this.api_endpoint
}