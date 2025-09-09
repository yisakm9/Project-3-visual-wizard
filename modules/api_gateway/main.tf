# main.tf for API Gateway

# Creates the REST API
resource "aws_api_gateway_rest_api" "search_api" {
  name        = var.api_name
  description = "API for searching images by labels"
  
  # The body is a JSON representation of the API, which will change
  # when resources, methods, or integrations are modified.
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
            payloadFormatVersion = "2.0"
            type                 = "aws_proxy"
            uri                  = var.search_lambda_invoke_arn
          }
        }
      }
    }
  })
}

# --- FIX #1: REMOVE stage_name AND ADD triggers ---
# This resource now creates a new deployment ONLY when the API configuration changes.
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.search_api.id

  # The 'triggers' argument forces a new deployment when its value changes.
  # We use the hash of the REST API's configuration as the trigger.
  triggers = {
    redeployment = sha1(aws_api_gateway_rest_api.search_api.body)
  }

  # This lifecycle block is crucial. It tells Terraform that a new
  # deployment resource should be created before the old one is destroyed.
  lifecycle {
    create_before_destroy = true
  }
}

# --- FIX #2: CREATE A SEPARATE STAGE RESOURCE ---
# This creates a stable stage (e.g., 'dev') and points it to the latest deployment.
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.search_api.id
  stage_name    = var.environment
}

# Grants API Gateway permission to invoke the search Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayToInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.search_lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # The source ARN should reference the stage and method for better security
  source_arn = "${aws_api_gateway_rest_api.search_api.execution_arn}/${aws_api_gateway_stage.api_stage.stage_name}/GET/search"
}