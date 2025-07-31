resource "aws_api_gateway_rest_api" "dynamo_db_operations" {
  name = "DynamoDBOperations"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.tags
}

resource "aws_api_gateway_resource" "todos" {
  parent_id   = aws_api_gateway_rest_api.dynamo_db_operations.root_resource_id
  path_part   = "todos"
  rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id
}

resource "aws_api_gateway_resource" "todo_item" {
  parent_id   = aws_api_gateway_resource.todos.id
  path_part   = "{id}"
  rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id
}

# GET /todos
resource "aws_api_gateway_method" "get_todos" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.todos.id
  rest_api_id   = aws_api_gateway_rest_api.dynamo_db_operations.id
}

resource "aws_api_gateway_integration" "get_todos" {
  http_method             = aws_api_gateway_method.get_todos.http_method
  resource_id             = aws_api_gateway_resource.todos.id
  rest_api_id             = aws_api_gateway_rest_api.dynamo_db_operations.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function_over_https.invoke_arn
}

# POST /todos
resource "aws_api_gateway_method" "post_todos" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.todos.id
  rest_api_id   = aws_api_gateway_rest_api.dynamo_db_operations.id
}

resource "aws_api_gateway_integration" "post_todos" {
  http_method             = aws_api_gateway_method.post_todos.http_method
  resource_id             = aws_api_gateway_resource.todos.id
  rest_api_id             = aws_api_gateway_rest_api.dynamo_db_operations.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function_over_https.invoke_arn
}

# PUT /todos/{id}
resource "aws_api_gateway_method" "put_todo" {
  authorization = "NONE"
  http_method   = "PUT"
  resource_id   = aws_api_gateway_resource.todo_item.id
  rest_api_id   = aws_api_gateway_rest_api.dynamo_db_operations.id
}

resource "aws_api_gateway_integration" "put_todo" {
  http_method             = aws_api_gateway_method.put_todo.http_method
  resource_id             = aws_api_gateway_resource.todo_item.id
  rest_api_id             = aws_api_gateway_rest_api.dynamo_db_operations.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function_over_https.invoke_arn
}

# DELETE /todos/{id}
resource "aws_api_gateway_method" "delete_todo" {
  authorization = "NONE"
  http_method   = "DELETE"
  resource_id   = aws_api_gateway_resource.todo_item.id
  rest_api_id   = aws_api_gateway_rest_api.dynamo_db_operations.id
}

resource "aws_api_gateway_integration" "delete_todo" {
  http_method             = aws_api_gateway_method.delete_todo.http_method
  resource_id             = aws_api_gateway_resource.todo_item.id
  rest_api_id             = aws_api_gateway_rest_api.dynamo_db_operations.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function_over_https.invoke_arn
}

# Permissions pour Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_over_https.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.dynamo_db_operations.execution_arn}/*/*"
}

# Déploiement
resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.todos.id,
      aws_api_gateway_resource.todo_item.id,
      aws_api_gateway_method.get_todos.id,
      aws_api_gateway_method.post_todos.id,
      aws_api_gateway_method.put_todo.id,
      aws_api_gateway_method.delete_todo.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.get_todos,
    aws_api_gateway_integration.post_todos,
    aws_api_gateway_integration.put_todo,
    aws_api_gateway_integration.delete_todo,
  ]
}

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.dynamo_db_operations.id
  stage_name    = "prod"
}
