output "invoke_url" {
  description = "The invoke URL for the deployed API stage."
  value       = "${aws_api_gateway_stage.this.invoke_url}/search"
}