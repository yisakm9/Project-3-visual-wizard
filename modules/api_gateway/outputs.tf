output "invoke_url" {
  description = "The invoke URL for the deployed API stage."
  # Manually construct the URL from its component parts to ensure the region is included.
  value = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${data.aws_region.current.id}.amazonaws.com/${aws_api_gateway_stage.this.stage_name}/search"
}