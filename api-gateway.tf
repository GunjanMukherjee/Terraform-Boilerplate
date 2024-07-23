# Create Amazon API Gateway for Operational Health Dashboard(OHD)
resource "aws_api_gateway_rest_api" "ohd_api" {
  name        = "OHD-api"
  description = "API Gateway for Operational Health Dashboard"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Amazon API Gateway Resources
resource "aws_api_gateway_resource" "ohd_api_resource" {
  parent_id   = aws_api_gateway_rest_api.ohd_api.root_resource_id
  path_part   = "demo-path" # Need to be change.
  rest_api_id = aws_api_gateway_rest_api.ohd_api.id
}

# Method type
resource "aws_api_gateway_method" "ohd_method" {
  resource_id   = aws_api_gateway_resource.ohd_api_resource.id
  rest_api_id   = aws_api_gateway_rest_api.ohd_api.id
  http_method   = "POST"
  authorization = "NONE" ##
}

# Integration type
resource "aws_api_gateway_integration" "lambda_integration" {
  http_method             = aws_api_gateway_method.ohd_method.http_method # POST
  resource_id             = aws_api_gateway_resource.ohd_api_resource.id
  rest_api_id             = aws_api_gateway_rest_api.ohd_api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"                                    # AWS_PROXY or AWS (Custom response)
  uri                     = aws_lambda_function.lambda_function.invoke_arn #Lambda Function
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.ohd_api.id
  stage_name  = "dev"


  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.ohd_api_resource.id,
      aws_api_gateway_method.ohd_method.id,
      aws_api_gateway_integration.lambda_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}

# Resource-based policy 
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ohd_api.execution_arn}/*/*/*"
}

output "invoke_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}


# Gunjan Mukherjee


