terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Test the module with minimal configuration
module "test_serverless" {
  source = "../"

  # Lambda Configuration
  lambda_function_name = "test-serverless-function"
  lambda_handler       = "index.handler"
  lambda_runtime       = "nodejs18.x"
  lambda_source_dir    = "./lambda"

  # DynamoDB Configuration
  dynamodb_table_name = "test-serverless-table"
  dynamodb_hash_key   = "id"

  # API Gateway Configuration
  api_gateway_name       = "test-serverless-api"
  api_gateway_stage_name = "test"

  tags = {
    Environment = "test"
    Project     = "module-testing"
  }
}

# Test outputs
output "test_api_endpoint" {
  description = "Test API Gateway endpoint URL"
  value       = module.test_serverless.serverless_endpoint
}

output "test_lambda_function_name" {
  description = "Test Lambda function name"
  value       = module.test_serverless.lambda_function_name
}

output "test_dynamodb_table_name" {
  description = "Test DynamoDB table name"
  value       = module.test_serverless.dynamodb_table_name
} 