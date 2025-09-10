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

# --- SQS QUEUE MODULE ---
module "image_processing_queue" {
  source = "../../modules/sqs"

  queue_name = "visual-wizard-image-processing-queue-dev"
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

# --- S3 BUCKET NOTIFICATION RESOURCE ---
# This resource links the S3 bucket to the SQS queue directly.
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


# --- IAM RESOURCES FOR IMAGE PROCESSING LAMBDA ---

module "image_processing_lambda_iam_role" {
  source = "../../modules/iam"
  role_name = "visual-wizard-image-processing-role-dev"
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

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
    actions   = ["dynamodb:PutItem"]
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

resource "aws_iam_role_policy_attachment" "custom" {
  role       = module.image_processing_lambda_iam_role.role_name
  policy_arn = aws_iam_policy.image_processing_policy.arn
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = module.image_processing_lambda_iam_role.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}