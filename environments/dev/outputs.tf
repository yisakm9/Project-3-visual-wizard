output "s3_bucket_name" {
  description = "The name of the S3 bucket where images should be uploaded."
  value       = module.s3.bucket_name
}

output "sqs_queue_url" {
  description = "The URL of the SQS queue that receives notifications."
  value       = module.sqs.queue_url
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table storing image labels."
  value       = module.dynamodb.table_name
}


output "s3_upload_bucket_name" {
  description = "The name of the S3 bucket where new images should be uploaded."
  value       = module.s3.bucket_name
}

output "api_search_url_example" {
  description = "Example URL to search for images. Replace 'car' with your desired label."
  value       = "${module.api_gateway.api_endpoint}/search?label=car"
}



output "image_processing_lambda_function_name" {
  description = "The name of the Lambda function that processes uploaded images."
  value       = module.image_processing_lambda.function_name
}

output "search_by_label_lambda_function_name" {
  description = "The name of the Lambda function that handles search queries from the API."
  value       = module.search_lambda.function_name
}