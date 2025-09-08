# modules/kms/outputs.tf

output "key_arn" {
  description = "The ARN of the KMS key."
  value       = aws_kms_key.main_key.arn
}

output "key_id" {
  description = "The ID of the KMS key."
  value       = aws_kms_key.main_key.key_id
}