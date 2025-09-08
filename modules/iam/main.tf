# modules/iam/main.tf

# IAM Role for the Image Processing Lambda
resource "aws_iam_role" "image_processing_lambda_role" {
  name = "${var.project_name}-image-processing-lambda-role"

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

# IAM Policy for the Image Processing Lambda
resource "aws_iam_policy" "image_processing_lambda_policy" {
  name        = "${var.project_name}-image-processing-lambda-policy"
  description = "Policy for the image processing Lambda function."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = "s3:GetObject",
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect   = "Allow",
        Action   = "rekognition:DetectLabels",
        Resource = "*" # Rekognition actions don't support resource-level permissions for this API
      },
      {
        Effect   = "Allow",
        Action   = "dynamodb:PutItem",
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "image_processing_attachment" {
  role       = aws_iam_role.image_processing_lambda_role.name
  policy_arn = aws_iam_policy.image_processing_lambda_policy.arn
}

# ---

# IAM Role for the Search by Label Lambda
resource "aws_iam_role" "search_by_label_lambda_role" {
  name = "${var.project_name}-search-by-label-lambda-role"
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

# IAM Policy for the Search by Label Lambda
resource "aws_iam_policy" "search_by_label_lambda_policy" {
  name        = "${var.project_name}-search-by-label-lambda-policy"
  description = "Policy for the search by label Lambda function."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = "dynamodb:Query",
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*" # Permission to query the GSI
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "search_by_label_attachment" {
  role       = aws_iam_role.search_by_label_lambda_role.name
  policy_arn = aws_iam_policy.search_by_label_lambda_policy.arn
}