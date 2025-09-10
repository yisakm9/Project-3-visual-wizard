module "image_bucket" {
  source = "../../modules/s3"

  bucket_name = var.image_bucket_name
  sqs_queue_arn_for_notifications = module.image_processing_queue.queue_arn

  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}
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


module "image_processing_queue" {
  source = "../../modules/sqs"

  queue_name = "visual-wizard-image-processing-queue-dev"
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}
# --- IAM RESOURCES FOR IMAGE PROCESSING LAMBDA ---

# 1. Create the role using our simplified module
module "image_processing_lambda_iam_role" {
  source = "../../modules/iam"

  role_name = "visual-wizard-image-processing-role-dev"
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

# 2. Define the policy content, which depends on the bucket and table modules
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
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [module.image_processing_queue.queue_arn]
  }
}

# 3. Create a standalone, managed IAM policy from the document
resource "aws_iam_policy" "image_processing_policy" {
  name   = "visual-wizard-image-processing-policy-dev"
  policy = data.aws_iam_policy_document.image_processing_lambda_policy_doc.json
}

# 4. Attach our new custom policy to the role
resource "aws_iam_role_policy_attachment" "custom" {
  role       = module.image_processing_lambda_iam_role.role_name
  policy_arn = aws_iam_policy.image_processing_policy.arn
}

# 5. Attach the AWS-managed basic execution policy to the role
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = module.image_processing_lambda_iam_role.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}