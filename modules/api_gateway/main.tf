resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "API for the Visual Wizard project"

  # The 'body' attribute is a JSON representation of the entire API structure.
  # We will use its hash to detect changes.
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = var.api_name
      version = "1.0"
    }
    paths = {
      "/search" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "aws_proxy"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.lambda_invoke_arn}/invocations"
          }
        }
      }
    }
  })

  tags = var.tags
}

data "aws_region" "current" {}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # IMPORTANT: This 'triggers' block tells Terraform to create a new deployment
  # whenever the API's structure (its body) changes.
  triggers = {
    redeployment = sha1(aws_api_gateway_rest_api.this.body)
  }

  # This lifecycle block prevents downtime. It creates the new deployment
  # before destroying the old one.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "v1" # You can still name your stage 'v1'
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_invoke_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}