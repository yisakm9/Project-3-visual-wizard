resource "aws_kms_key" "this" {
description = "KMS key for ${var.key_alias_name}"
deletion_window_in_days = var.deletion_window_in_days
enable_key_rotation = true
tags = var.tags
}
resource "aws_kms_alias" "this" {
name = "alias/${var.key_alias_name}"
target_key_id = aws_kms_key.this.id
}