# modules/kms/main.tf

resource "aws_kms_key" "main_key" {
  description             = "KMS key for ${var.project_name} project resources"
  deletion_window_in_days = 7 # Use a short window for dev, 30 for prod
  enable_key_rotation   = true

  tags = {
    Project = var.project_name
  }
}

resource "aws_kms_alias" "main_key_alias" {
  name          = "alias/${var.project_name}-main-key"
  target_key_id = aws_kms_key.main_key.key_id
}