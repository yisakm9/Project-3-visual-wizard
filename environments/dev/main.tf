module "image_bucket" {
  source = "../../modules/s3"

  bucket_name = var.image_bucket_name
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}

data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "image_processing_lambda_iam_role" {
  source = "../../modules/iam"

  role_name  = "visual-wizard-image-processing-role-dev"
  policy_arn = data.aws_iam_policy.lambda_basic_execution.arn
  tags = {
    Project     = "VisualWizard"
    Environment = "Dev"
  }
}