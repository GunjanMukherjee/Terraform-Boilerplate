#Zip 
data "archive_file" "lambda_auth_zip_file" {
  type        = "zip"
  source_file = "lambda/lambda-authorizer.js"
  output_path = "lambda/lambda-authorizer.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda
resource "aws_lambda_function" "auth_lambda" {
  filename         = "lambda/lambda-authorizer.zip"
  function_name    = "auth_lambda"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.lambda_auth_zip_file.output_base64sha256

  environment {
    variables = {
      OKTA_DOMAIN = "https://{yourOktaDomain}"
    }
  }
}
