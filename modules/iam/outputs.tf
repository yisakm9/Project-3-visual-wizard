output "image_processing_lambda_role_arn" {
  description = "The ARN of the IAM role for the image processing Lambda."
  value       = aws_iam_role.image_processing_lambda_role.arn
}

output "search_by_label_lambda_role_arn" {
  description = "The ARN of the IAM role for the search by label Lambda."
  value       = aws_iam_role.search_by_label_lambda_role.arn
}