# modules/api_gateway/outputs.tf

output "invoke_url" {
  description = "The base URL to invoke the API."
  value       = aws_apigatewayv2_api.search_api.api_endpoint
}

output "execution_arn" {
  description = "The execution ARN for the API Gateway to be used in Lambda permissions."
  value       = "${aws_apigatewayv2_api.search_api.execution_arn}/*/*"
}