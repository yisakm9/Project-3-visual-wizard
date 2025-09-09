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

output "lambda_function_name" {
  description = "The name of the image processing Lambda function."
  value       = module.lambda_function.function_name
}

output "iam_role_arn" {
  description = "The ARN of the IAM role used by the Lambda function."
  value       = module.iam.role_arn
}