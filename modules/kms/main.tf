data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "key_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.s3_source_bucket_arn != null ? [1] : []
    content {
      sid    = "AllowS3ToUseKMSKeyForSQSEncryption"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }
      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]
      resources = ["*"] # In a key policy, "*" refers to the key itself.
      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = [var.s3_source_bucket_arn]
      }
    }
  }

  # --- ADD THIS NEW DYNAMIC STATEMENT ---
  dynamic "statement" {
    for_each = length(var.lambda_role_arns_for_decrypt) > 0 ? var.lambda_role_arns_for_decrypt : []
    content {
      sid    = "AllowLambdaToDecryptMessages"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = [statement.value] # The role ARN from the list
      }
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"] # In a key policy, "*" refers to the key itself
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "KMS key for ${var.key_alias_name}"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.key_policy.json
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.key_alias_name}"
  target_key_id = aws_kms_key.this.id
}