# environments/dev/outputs.tf

output "s3_bucket_name" {
  description = "The name of the S3 bucket where images should be uploaded."
  value       = module.s3.bucket_name
}

output "sqs_queue_url" {
  description = "The URL of the SQS queue."
  value       = module.sqs.queue_url
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table storing image labels."
  value       = module.dynamodb.table_name
}

output "image_processing_lambda_name" {
  description = "The name of the image processing Lambda function."
  value       = module.lambda_function.function_name
}

output "search_lambda_name" {
  description = "The name of the search Lambda function."
  value       = module.search_lambda_function.function_name
}

output "api_search_endpoint_url" {
  description = "The full URL for the image search endpoint."
  value       = "${module.api_gateway.api_invoke_url}/search"
}