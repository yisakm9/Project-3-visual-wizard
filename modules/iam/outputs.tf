# outputs.tf for IAM

output "role_arn" {
  value = aws_iam_role.lambda_execution_role.arn
}