# =============================================================================
# Lambda Outputs
# =============================================================================

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = var.create_lambda ? aws_lambda_function.this[0].arn : null
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = var.create_lambda ? aws_lambda_function.this[0].function_name : null
}

output "lambda_function_invoke_arn" {
  description = "Invocation ARN of the Lambda function"
  value       = var.create_lambda ? aws_lambda_function.this[0].invoke_arn : null
}

output "lambda_function_version" {
  description = "Latest published version of the Lambda function"
  value       = var.create_lambda ? aws_lambda_function.this[0].version : null
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = var.create_lambda ? aws_iam_role.lambda_role[0].arn : null
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = var.create_lambda ? aws_iam_role.lambda_role[0].name : null
}

output "lambda_log_group_name" {
  description = "Name of the CloudWatch log group for Lambda"
  value       = var.create_lambda ? aws_cloudwatch_log_group.lambda_logs[0].name : null
}

# =============================================================================
# DynamoDB Outputs
# =============================================================================

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = var.create_dynamodb ? aws_dynamodb_table.this[0].arn : null
}

output "dynamodb_table_id" {
  description = "ID of the DynamoDB table"
  value       = var.create_dynamodb ? aws_dynamodb_table.this[0].id : null
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = var.create_dynamodb ? aws_dynamodb_table.this[0].name : null
}

output "dynamodb_table_stream_arn" {
  description = "Stream ARN of the DynamoDB table"
  value       = var.create_dynamodb ? aws_dynamodb_table.this[0].stream_arn : null
}

# =============================================================================
# API Gateway Outputs
# =============================================================================

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = var.create_api_gateway ? aws_api_gateway_rest_api.this[0].id : null
}

output "api_gateway_arn" {
  description = "ARN of the API Gateway"
  value       = var.create_api_gateway ? aws_api_gateway_rest_api.this[0].arn : null
}

output "api_gateway_name" {
  description = "Name of the API Gateway"
  value       = var.create_api_gateway ? aws_api_gateway_rest_api.this[0].name : null
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = var.create_api_gateway ? aws_api_gateway_rest_api.this[0].execution_arn : null
}

output "api_gateway_invoke_url" {
  description = "Invoke URL of the API Gateway"
  value       = var.create_api_gateway ? "${aws_api_gateway_deployment.this[0].invoke_url}" : null
}

output "api_gateway_stage_arn" {
  description = "ARN of the API Gateway stage"
  value       = var.create_api_gateway ? "${aws_api_gateway_rest_api.this[0].execution_arn}/*/${var.api_gateway_stage_name}" : null
}

# =============================================================================
# Combined Outputs
# =============================================================================

output "serverless_endpoint" {
  description = "Complete serverless API endpoint URL"
  value       = var.create_api_gateway && var.create_lambda ? "${aws_api_gateway_deployment.this[0].invoke_url}" : null
}

output "all_outputs" {
  description = "All outputs in a single map for easy consumption"
  value = {
    lambda = {
      function_arn     = var.create_lambda ? aws_lambda_function.this[0].arn : null
      function_name    = var.create_lambda ? aws_lambda_function.this[0].function_name : null
      invoke_arn       = var.create_lambda ? aws_lambda_function.this[0].invoke_arn : null
      version          = var.create_lambda ? aws_lambda_function.this[0].version : null
      role_arn         = var.create_lambda ? aws_iam_role.lambda_role[0].arn : null
      role_name        = var.create_lambda ? aws_iam_role.lambda_role[0].name : null
      log_group_name   = var.create_lambda ? aws_cloudwatch_log_group.lambda_logs[0].name : null
    }
    dynamodb = {
      table_arn        = var.create_dynamodb ? aws_dynamodb_table.this[0].arn : null
      table_id         = var.create_dynamodb ? aws_dynamodb_table.this[0].id : null
      table_name       = var.create_dynamodb ? aws_dynamodb_table.this[0].name : null
      stream_arn       = var.create_dynamodb ? aws_dynamodb_table.this[0].stream_arn : null
    }
    api_gateway = {
      id               = var.create_api_gateway ? aws_api_gateway_rest_api.this[0].id : null
      arn              = var.create_api_gateway ? aws_api_gateway_rest_api.this[0].arn : null
      name             = var.create_api_gateway ? aws_api_gateway_rest_api.this[0].name : null
      execution_arn    = var.create_api_gateway ? aws_api_gateway_rest_api.this[0].execution_arn : null
      invoke_url       = var.create_api_gateway ? "${aws_api_gateway_deployment.this[0].invoke_url}" : null
      stage_arn        = var.create_api_gateway ? "${aws_api_gateway_rest_api.this[0].execution_arn}/*/${var.api_gateway_stage_name}" : null
    }
    endpoint = var.create_api_gateway && var.create_lambda ? "${aws_api_gateway_deployment.this[0].invoke_url}" : null
  }
} 