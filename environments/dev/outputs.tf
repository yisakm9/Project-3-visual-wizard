# environments/dev/outputs.tf

output "s3_bucket_name" {
  description = "The name of the S3 bucket to upload images to."
  value       = module.s3_storage.bucket_id
}

output "api_search_invoke_url" {
  description = "The URL to invoke the search API."
  value       = module.api_search.invoke_url
}