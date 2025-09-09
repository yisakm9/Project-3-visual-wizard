# outputs.tf for API Gateway

output "api_invoke_url" {
  description = "The URL to invoke the API."
  value       = aws_api_gateway_deployment.api_deployment.invoke_url
}