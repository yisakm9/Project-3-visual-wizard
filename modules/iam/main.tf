resource "aws_iam_role" "this" {
  name = var.role_name
  tags = var.tags

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "this" {
  name   = var.policy_name
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      # Basic Lambda execution permissions (always included)
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      # Rekognition permissions (always included for this project)
      {
        Effect   = "Allow",
        Action   = "rekognition:DetectLabels",
        Resource = "*"
      },
      # --- FIX 1: DYNAMIC BLOCK FOR S3 ---
      # This S3 statement is now only created if var.s3_bucket_arn is not null.
      if var.s3_bucket_arn != null ? {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = "${var.s3_bucket_arn}/*"
      } : null,
      
      # --- FIX 2: DYNAMIC BLOCK FOR SQS ---
      # This SQS statement is now only created if var.sqs_queue_arn is not null.
      if var.sqs_queue_arn != null ? {
        Effect   = "Allow",
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = var.sqs_queue_arn
      } : null,

      # --- FIX 3: DYNAMIC BLOCK FOR DYNAMODB ---
      # This DynamoDB statement is now only created if var.dynamodb_table_arn is not null.
      if var.dynamodb_table_arn != null ? {
        Effect   = "Allow",
        Action   = "dynamodb:PutItem",
        Resource = var.dynamodb_table_arn
      } : null
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}