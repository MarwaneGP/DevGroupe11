data "archive_file" "lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/../server/index.mjs"
  output_path = "${path.module}/lambda/lambda_function_payload.zip"
}

# Lambda function
resource "aws_lambda_function" "lambda_function_over_https" {
  filename         = data.archive_file.lambda_archive.output_path
  function_name    = "TodosLambdaFunction"
  role             = aws_iam_role.lambda_apigateway_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_archive.output_base64sha256
  runtime          = "nodejs20.x"
  
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.todos_table.name
    }
  }
  
  tags = var.tags
}