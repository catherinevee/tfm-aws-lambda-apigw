output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.serverless_app.serverless_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.serverless_app.lambda_function_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.serverless_app.dynamodb_table_name
}

output "all_outputs" {
  description = "All module outputs"
  value       = module.serverless_app.all_outputs
} 