# modules/api_gateway/main.tf

# Create an HTTP API, which is simpler and cheaper than a REST API for this use case.
resource "aws_apigatewayv2_api" "search_api" {
  name          = "${var.project_name}-search-api"
  protocol_type = "HTTP"
}

# Create the integration between the API and the search Lambda function.
resource "aws_apigatewayv2_integration" "search_lambda_integration" {
  api_id           = aws_apigatewayv2_api.search_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.search_lambda_invoke_arn
}

# Define the route for search requests (e.g., GET /search).
resource "aws_apigatewayv2_route" "search_route" {
  api_id    = aws_apigatewayv2_api.search_api.id
  route_key = "GET /search"
  target    = "integrations/${aws_apigatewayv2_integration.search_lambda_integration.id}"
}

# Create a deployment stage for the API.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.search_api.id
  name        = "$default"
  auto_deploy = true
}

# ADD THIS NEW RESOURCE to grant API Gateway permission to invoke the Lambda
resource "aws_lambda_permission" "allow_api_gateway_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.search_lambda_function_name # Use function name here
  principal     = "apigateway.amazonaws.com"
  
  # This source_arn correctly links the permission to your specific API Gateway
  source_arn    = "${aws_apigatewayv2_api.search_api.execution_arn}/*/*"
}