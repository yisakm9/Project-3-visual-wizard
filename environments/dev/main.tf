# --- S3 BUCKET MODULE ---
module "image_bucket" {
  source = "../../modules/s3"

  bucket_name = var.image_bucket_name
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

# --- DYNAMODB TABLE MODULE ---
module "labels_table" {
  source = "../../modules/dynamodb"

  table_name        = var.labels_table_name
  partition_key     = "ImageKey"
  gsi_name          = "LabelIndex"
  gsi_partition_key = "Label"
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

# --- SQS QUEUE POLICY DEFINITION ---
# This data source defines the permission for S3 to send messages to SQS.
# It depends on the bucket and queue, which will be created below.
data "aws_iam_policy_document" "sqs_queue_policy_doc" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [module.image_processing_queue.queue_arn] # Depends on the SQS queue
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.image_bucket.bucket_arn] # Depends on the S3 bucket
    }
  }
}

# --- SQS QUEUE MODULE ---
# The module now receives the fully-resolved policy document.
module "image_processing_queue" {
  source = "../../modules/sqs"

  queue_name = "visual-wizard-image-processing-queue-dev"
  policy     = data.aws_iam_policy_document.sqs_queue_policy_doc.json
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

# --- S3 BUCKET NOTIFICATION ---
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.image_bucket.bucket_name

  queue {
    queue_arn     = module.image_processing_queue.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".jpg"
  }
  queue {
    queue_arn     = module.image_processing_queue.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".png"
  }
}


# --- IAM & LAMBDA RESOURCES ---

# IAM Role for the Lambda
module "image_processing_lambda_iam_role" {
  source    = "../../modules/iam"
  role_name = "visual-wizard-image-processing-role-dev"
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

# IAM Policy for the Lambda
data "aws_iam_policy_document" "image_processing_lambda_policy_doc" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.image_bucket.bucket_arn}/*"]
  }
  statement {
    actions   = ["rekognition:DetectLabels"]
    resources = ["*"]
  }
  statement {
    actions   = ["dynamodb:PutItem", "dynamodb:BatchWriteItem"]
    resources = [module.labels_table.table_arn]
  }
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [module.image_processing_queue.queue_arn]
  }
}

resource "aws_iam_policy" "image_processing_policy" {
  name   = "visual-wizard-image-processing-policy-dev"
  policy = data.aws_iam_policy_document.image_processing_lambda_policy_doc.json
}

# Policy Attachments
resource "aws_iam_role_policy_attachment" "custom" {
  role       = module.image_processing_lambda_iam_role.role_name
  policy_arn = aws_iam_policy.image_processing_policy.arn
}
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = module.image_processing_lambda_iam_role.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
module "image_processing_lambda" {
  source = "../../modules/lambda_function"

  function_name = "visual-wizard-image-processing-dev"
  handler       = "image_processing.handler"
  runtime       = "python3.9"
  source_path   = "../../src/image_processing"
  iam_role_arn  = module.image_processing_lambda_iam_role.role_arn
  environment_variables = {
    LABELS_TABLE_NAME = module.labels_table.table_name
  }
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

# Lambda Trigger
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = module.image_processing_queue.queue_arn
  function_name    = module.image_processing_lambda.function_arn
}