# Lambda execution policy avec permissions spécifiques
resource "aws_iam_policy" "lambda_apigateway_policy" {
  name        = "${var.project_name}-lambda-execution-policy"
  description = "IAM policy for Lambda function execution with DynamoDB and CloudWatch access"
  policy      = data.aws_iam_policy_document.lambda_execution_policy_document.json
}

# Policy document avec permissions granulaires
data "aws_iam_policy_document" "lambda_execution_policy_document" {
  # DynamoDB permissions spécifiques à la table todos
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem"
    ]
    resources = [
      aws_dynamodb_table.todos_table.arn,
      "${aws_dynamodb_table.todos_table.arn}/index/*"
    ]
  }

  # CloudWatch Logs permissions
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-*:*"
    ]
  }

  # X-Ray tracing (optionnel pour debugging)
  statement {
    sid    = "XRayAccess"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }
}

# Lambda assume role policy
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    sid     = "AllowLambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# IAM role pour Lambda
resource "aws_iam_role" "lambda_apigateway_role" {
  name               = "${var.project_name}-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  
  tags = var.tags
}

# Attacher la policy custom à la role
resource "aws_iam_role_policy_attachment" "lambda_apigateway_attachment" {
  role       = aws_iam_role.lambda_apigateway_role.name
  policy_arn = aws_iam_policy.lambda_apigateway_policy.arn
}

# Attacher la policy AWS managée pour VPC (si besoin futur)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_apigateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}