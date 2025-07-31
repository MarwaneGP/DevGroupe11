# Backend Infrastructure Outputs
output "api_gateway_url" {
  description = "API Gateway URL for the backend Lambda function"
  value       = "https://${aws_api_gateway_rest_api.dynamo_db_operations.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.api.stage_name}"
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.lambda_function_over_https.function_name
}

# Frontend Infrastructure Outputs
output "cloudfront_url" {
  description = "CloudFront distribution URL for the frontend"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.cdn.id
}

output "s3_bucket_name" {
  description = "S3 bucket name for static website hosting"
  value       = aws_s3_bucket.main.id
}

output "s3_website_endpoint" {
  description = "S3 website endpoint"
  value       = aws_s3_bucket.main.website_endpoint
}

# Database Outputs
output "dynamodb_table_name" {
  description = "DynamoDB table name for todos"
  value       = aws_dynamodb_table.todos_table.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.todos_table.arn
}

# Container Infrastructure Outputs
output "ecr_client_repository_url" {
  description = "ECR repository URL for client images"
  value       = aws_ecr_repository.client.repository_url
}

output "ecr_client_repository_name" {
  description = "ECR repository name for client"
  value       = aws_ecr_repository.client.name
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

# IAM Outputs
output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_apigateway_role.arn
}

# General Infrastructure Outputs
output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "project_name" {
  description = "Project name used for resource naming"
  value       = var.project_name
}

# Deployment Summary for CI/CD
output "deployment_summary" {
  description = "Summary of all deployed resources"
  value = {
    frontend = {
      cloudfront_url = "https://${aws_cloudfront_distribution.cdn.domain_name}"
      s3_bucket     = aws_s3_bucket.main.id
    }
    backend = {
      api_url          = "https://${aws_api_gateway_rest_api.dynamo_db_operations.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.api.stage_name}"
      lambda_function  = aws_lambda_function.lambda_function_over_https.function_name
      dynamodb_table   = aws_dynamodb_table.todos_table.name
    }
    containers = {
      ecr_repository = aws_ecr_repository.client.repository_url
    }
    project = {
      name   = var.project_name
      region = var.aws_region
    }
  }
}