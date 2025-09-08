# modules/iam/outputs.tf

output "image_processing_lambda_role_arn" {
  value = aws_iam_role.image_processing_lambda_role.arn
}

output "search_by_label_lambda_role_arn" {
  value = aws_iam_role.search_by_label_lambda_role.arn
}