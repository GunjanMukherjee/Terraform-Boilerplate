#1 Create Amazon Lambda Function

#Zip 
data "archive_file" "lambda_zip_file" {
  type        = "zip"
  source_file = "lambda/index.js"
  output_path = "lambda/index.zip"
}

# Lambda Role
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = file("lambda-policy.json")
}

# IAM policy 
resource "aws_iam_role_policy_attachment" "lambda_exec_role_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#Lambda Function
resource "aws_lambda_function" "lambda_function" {
  filename         = "lambda/index.zip"
  function_name    = "RgaLambdaFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 30
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME = "Operational Health Dashboard"
      CLIENT_NAME  = "Reinsurance Group of America"
    }
  }
}

# Gunjan Mukherjee

