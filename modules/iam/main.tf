# A locals block to define our conditional policy statements
locals {
  # This list will contain the S3 policy statement ONLY if var.s3_bucket_arn is not null.
  # Otherwise, it will be an empty list.
  s3_policy_statement = var.s3_bucket_arn != null ? [
    {
      Effect   = "Allow",
      Action   = ["s3:GetObject"],
      Resource = "${var.s3_bucket_arn}/*"
    }
  ] : []

  # This list will contain the SQS policy statement ONLY if var.sqs_queue_arn is not null.
  sqs_policy_statement = var.sqs_queue_arn != null ? [
    {
      Effect   = "Allow",
      Action   = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      Resource = var.sqs_queue_arn
    }
  ] : []

  # This list will contain the DynamoDB policy statement ONLY if var.dynamodb_table_arn is not null.
  dynamodb_policy_statement = var.dynamodb_table_arn != null ? [
    {
      Effect   = "Allow",
      # Note: Added Read permissions for the search lambda
      Action   = ["dynamodb:PutItem", "dynamodb:Scan"], 
      Resource = var.dynamodb_table_arn
    }
  ] : []
}

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
    # We use concat() to merge the required statements with our conditional ones.
    # If an optional statement list is empty, concat simply ignores it.
    Statement = concat(
      [
        # --- REQUIRED STATEMENTS ---
        # Basic CloudWatch Logs permissions (always included)
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
        }
      ],
      # --- OPTIONAL STATEMENTS ---
      local.s3_policy_statement,
      local.sqs_policy_statement,
      local.dynamodb_policy_statement
    )
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}