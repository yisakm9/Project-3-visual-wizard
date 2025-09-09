# modules/iam/main.tf

# Role for the Image Processing Lambda
resource "aws_iam_role" "image_processing_lambda_role" {
  name = "${var.function_name_prefix}-image-processing-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "image_processing_lambda_policy" {
  name        = "${var.function_name_prefix}-image-processing-policy"
  description = "Policy for image processing Lambda"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = "rekognition:DetectLabels"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "dynamodb:PutItem"
        Effect   = "Allow"
        Resource = var.dynamodb_table_arn
      },
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "image_processing_attachment" {
  role       = aws_iam_role.image_processing_lambda_role.name
  policy_arn = aws_iam_policy.image_processing_lambda_policy.arn
}


# Role for the Search by Label Lambda
resource "aws_iam_role" "search_by_label_lambda_role" {
  name = "${var.function_name_prefix}-search-by-label-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "search_by_label_lambda_policy" {
  name        = "${var.function_name_prefix}-search-by-label-policy"
  description = "Policy for search by label Lambda"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = "dynamodb:Query"
        Effect   = "Allow"
        Resource = "${var.dynamodb_table_arn}/index/${var.dynamodb_gsi_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "search_by_label_attachment" {
  role       = aws_iam_role.search_by_label_lambda_role.name
  policy_arn = aws_iam_policy.search_by_label_lambda_policy.arn
}