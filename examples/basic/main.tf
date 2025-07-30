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

module "serverless_app" {
  source = "../../"

  # Lambda Configuration
  lambda_function_name = "basic-serverless-function"
  lambda_handler       = "index.handler"
  lambda_runtime       = "nodejs18.x"
  lambda_timeout       = 30
  lambda_memory_size   = 128
  lambda_source_dir    = "./lambda"

  # DynamoDB Configuration
  dynamodb_table_name = "basic-serverless-table"
  dynamodb_hash_key   = "id"
  dynamodb_attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  # API Gateway Configuration
  api_gateway_name       = "basic-serverless-api"
  api_gateway_stage_name = "prod"

  tags = {
    Environment = "development"
    Project     = "basic-serverless"
    Owner       = "devops"
  }
}

# Output the API endpoint
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