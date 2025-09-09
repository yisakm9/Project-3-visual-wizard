# outputs.tf for API Gateway

output "api_invoke_url" {
  description = "The base URL for the deployed API stage."
  # Correct: The invoke_url is an attribute of the stage, not the deployment.
  value       = aws_api_gateway_stage.api_stage.invoke_url
}