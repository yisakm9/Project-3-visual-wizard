data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "custom" {
  # Create this custom policy only if a document is provided
  count = var.custom_policy_document != null ? 1 : 0

  name   = "${var.role_name}-custom-policy"
  role   = aws_iam_role.this.id
  policy = var.custom_policy_document
}

resource "aws_iam_role_policy_attachment" "managed" {
  # Loop through the list of managed policy ARNs and attach each one
  count = length(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.managed_policy_arns[count.index]
}