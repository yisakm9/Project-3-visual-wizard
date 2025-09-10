module "encryption_key" {
  source = "../../modules/kms"

  key_alias_name = "visual-wizard-dev-key"
  s3_source_bucket_arn = module.image_bucket.bucket_arn
  lambda_role_arns_for_decrypt = [module.image_processing_lambda_iam_role.role_arn]
  tags           = { Project = "VisualWizard", Environment = "Dev" }
}

#  S3 BUCKET  MODULE 
module "image_bucket" {
  source = "../../modules/s3"

  bucket_name = var.image_bucket_name
  kms_key_arn = module.encryption_key.key_arn # Pass the key ARN
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
    ManagedBy   = "GitHub-Actions"
  }
}

# --- DYNAMODB TABLE MODULE ---
module "labels_table" {
  source = "../../modules/dynamodb"

  table_name        = var.labels_table_name
  partition_key     = "ImageKey"
  sort_key          = "Label" 
  gsi_name          = "LabelIndex"
  gsi_partition_key = "Label"
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

# --- SQS QUEUE MODULE ---
# Creates the queue, but does not configure its policy.
module "image_processing_queue" {
  source = "../../modules/sqs"

  queue_name = "visual-wizard-image-processing-queue-dev"
  kms_key_id = module.encryption_key.key_arn # Pass the key ARN
  
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

# --- SQS QUEUE POLICY (Defined in the root) ---
# This policy grants the S3 service permission to send messages to our queue.
resource "aws_sqs_queue_policy" "s3_to_sqs_policy" {
  queue_url = module.image_processing_queue.queue_id

  policy = data.aws_iam_policy_document.sqs_queue_policy_doc.json
}

data "aws_iam_policy_document" "sqs_queue_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [module.image_processing_queue.queue_arn]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.image_bucket.bucket_arn]
    }
  }
}

# --- S3 BUCKET NOTIFICATION (Defined in the root) ---
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

  # This tells Terraform to wait until the SQS policy is created before creating this notification.
  depends_on = [aws_sqs_queue_policy.s3_to_sqs_policy]
}

# --- IAM & LAMBDA RESOURCES ---

# IAM Role for the Lambda
module "image_processing_lambda_iam_role" {
  source    = "../../modules/iam"
  role_name = "visual-wizard-image-processing-role-dev"
  tags      = { Project = "VisualWizard", Environment = "Dev" }
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
  source        = "../../modules/lambda_function"
  function_name = "visual-wizard-image-processing-dev"
  handler       = "image_processing.handler"
  runtime       = "python3.9"
  iam_role_arn  = module.image_processing_lambda_iam_role.role_arn
  filename         = "${path.root}/image-processing.zip"
  source_code_hash = filebase64sha256("${path.root}/image-processing.zip")
  environment_variables = {
    LABELS_TABLE_NAME = module.labels_table.table_name
  }
  tags = { Project = "VisualWizard", Environment = "Dev" }
}

# Lambda Trigger
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = module.image_processing_queue.queue_arn
  function_name    = module.image_processing_lambda.function_arn
}

# --- IAM & LAMBDA RESOURCES FOR SEARCH ---

module "search_by_label_lambda_iam_role" {
  source    = "../../modules/iam"
  role_name = "visual-wizard-search-by-label-role-dev"
  tags      = { Project = "VisualWizard", Environment = "Dev" }
}

data "aws_iam_policy_document" "search_lambda_policy_doc" {
  statement {
    actions   = ["dynamodb:Query"]
    # Allow querying both the table and the specific GSI
    resources = [
      module.labels_table.table_arn,
      "${module.labels_table.table_arn}/index/${module.labels_table.gsi_name}"
    ]
  }
}

resource "aws_iam_policy" "search_policy" {
  name   = "visual-wizard-search-by-label-policy-dev"
  policy = data.aws_iam_policy_document.search_lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "search_custom" {
  role       = module.search_by_label_lambda_iam_role.role_name
  policy_arn = aws_iam_policy.search_policy.arn
}

resource "aws_iam_role_policy_attachment" "search_basic_execution" {
  role       = module.search_by_label_lambda_iam_role.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "search_by_label_lambda" {
  source        = "../../modules/lambda_function"
  function_name = "visual-wizard-search-by-label-dev"
  handler       = "search_by_label.handler"
  runtime       = "python3.9"
  iam_role_arn  = module.search_by_label_lambda_iam_role.role_arn
  filename         = "${path.root}/search-by-label.zip"
  source_code_hash = filebase64sha256("${path.root}/search-by-label.zip")
  environment_variables = {
    LABELS_TABLE_NAME = module.labels_table.table_name,
    GSI_NAME          = module.labels_table.gsi_name
  }
  tags = { Project = "VisualWizard", Environment = "Dev" }
}

# --- API GATEWAY MODULE ---

module "search_api" {
  source = "../../modules/api_gateway"

  api_name        = "visual-wizard-api-dev"
  lambda_invoke_arn = module.search_by_label_lambda.function_arn
  tags            = { Project = "VisualWizard", Environment = "Dev" }
}