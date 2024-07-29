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
  http_method   = "POST"   # ANY
  authorization = "CUSTOM" # NONE
  authorizer_id = aws_api_gateway_authorizer.auth_lambda.id
}

resource "aws_api_gateway_authorizer" "auth_lambda" {
  name                   = "lambda-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.ohd_api.id
  authorizer_uri         = aws_lambda_function.auth_lambda.invoke_arn
  authorizer_credentials = aws_iam_role.lambda_exec.arn
  type                   = "TOKEN"
}


# Integration type
/*
AWS and AWS_PROXY are two types of integration in API Gateway.

AWS_PROXY- For HTTP proxy integration, API Gateway passes the entire request and response between the frontend 
and an HTTP backend.

AWS- For Lambda proxy integration, API Gateway sends the entire request as input to a backend Lambda function. 
API Gateway then transforms the Lambda function output to a frontend HTTP response
*/
# Comment this block for custom response

/*
resource "aws_api_gateway_integration" "lambda_integration" {
  http_method             = aws_api_gateway_method.ohd_method.http_method # POST
  resource_id             = aws_api_gateway_resource.ohd_api_resource.id
  rest_api_id             = aws_api_gateway_rest_api.ohd_api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"                                    # AWS_PROXY or AWS (Custom response)
  uri                     = aws_lambda_function.lambda_function.invoke_arn #Lambda Function
}
*/

# Integration type - Custom response
resource "aws_api_gateway_method_response" "ohd_method_response" {
  rest_api_id = aws_api_gateway_rest_api.ohd_api.id
  resource_id = aws_api_gateway_resource.ohd_api_resource.id
  http_method = aws_api_gateway_method.ohd_method.http_method
  status_code = "200"

  //optional for cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "lambda_integration" {
  http_method             = aws_api_gateway_method.ohd_method.http_method
  resource_id             = aws_api_gateway_resource.ohd_api_resource.id
  rest_api_id             = aws_api_gateway_rest_api.ohd_api.id
  integration_http_method = "POST"
  type                    = "AWS" # AWS_PROXY or AWS (Custom response)
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_api_gateway_integration_response" "lambda_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.ohd_api.id
  resource_id = aws_api_gateway_resource.ohd_api_resource.id
  http_method = aws_api_gateway_method.ohd_method.http_method
  status_code = aws_api_gateway_method_response.ohd_method_response.status_code

  //optional for cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  response_templates = {
    "application/json" = jsonencode({ "LambdaValue" = "$input.path('$').body", "data" = "Custom Value" })
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}
## Custom response end

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.ohd_api.id
  stage_name  = "dev"

  #redeploy the REST API
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.ohd_api_resource.id,
      aws_api_gateway_method.ohd_method.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ohd_api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "apigw_lambda_auth_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ohd_api.execution_arn}/*/*/*"
}


output "invoke_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}


# Gunjan Mukherjee


