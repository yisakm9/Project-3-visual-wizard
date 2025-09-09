output "s3_bucket_name" {
  description = "The name of the S3 bucket where images should be uploaded."
  value       = module.s3.s3_bucket_id
}

output "api_search_url" {
  description = "The URL to the search endpoint. Use with a query parameter, e.g., ?label=dog"
  value       = "${module.api_gateway.api_invoke_url}/search"
}