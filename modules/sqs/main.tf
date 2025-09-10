resource "aws_sqs_queue" "this" {
  name = var.queue_name
  tags = var.tags

  kms_master_key_id      = var.kms_key_id
  kms_data_key_reuse_period_seconds = 300 # 5 minutes
}