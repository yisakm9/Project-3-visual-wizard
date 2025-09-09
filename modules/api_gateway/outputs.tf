output "api_invoke_url" {
  description = "The invoke URL for the API Gateway."
  value       = aws_apigatewayv2_stage.default.invoke_url
}