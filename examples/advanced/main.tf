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

# Create VPC for Lambda (optional)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "serverless-vpc"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_security_group" "lambda" {
  name_prefix = "lambda-sg-"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-security-group"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create KMS key for DynamoDB encryption
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "dynamodb-encryption-key"
  }
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/dynamodb-encryption"
  target_key_id = aws_kms_key.dynamodb.key_id
}

module "advanced_serverless" {
  source = "../../"

  # Lambda Configuration
  lambda_function_name = "advanced-serverless-function"
  lambda_handler       = "index.handler"
  lambda_runtime       = "nodejs18.x"
  lambda_timeout       = 60
  lambda_memory_size   = 512
  lambda_source_dir    = "./lambda"
  
  lambda_environment_variables = {
    TABLE_NAME = "advanced-serverless-table"
    LOG_LEVEL  = "INFO"
    ENVIRONMENT = "production"
  }

  lambda_vpc_config = {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  lambda_log_retention_days = 30

  # DynamoDB Configuration
  dynamodb_table_name = "advanced-serverless-table"
  dynamodb_hash_key   = "pk"
  dynamodb_range_key  = "sk"
  
  dynamodb_attributes = [
    {
      name = "pk"
      type = "S"
    },
    {
      name = "sk"
      type = "S"
    },
    {
      name = "gsi1pk"
      type = "S"
    },
    {
      name = "gsi1sk"
      type = "S"
    },
    {
      name = "gsi2pk"
      type = "S"
    },
    {
      name = "gsi2sk"
      type = "S"
    }
  ]

  dynamodb_global_secondary_indexes = [
    {
      name            = "gsi1"
      hash_key        = "gsi1pk"
      range_key       = "gsi1sk"
      projection_type = "ALL"
    },
    {
      name            = "gsi2"
      hash_key        = "gsi2pk"
      range_key       = "gsi2sk"
      projection_type = "INCLUDE"
      non_key_attributes = ["data", "created_at"]
    }
  ]

  dynamodb_point_in_time_recovery = true
  dynamodb_server_side_encryption = true
  dynamodb_kms_key_arn            = aws_kms_key.dynamodb.arn

  # API Gateway Configuration
  api_gateway_name        = "advanced-serverless-api"
  api_gateway_stage_name  = "prod"
  api_gateway_authorization = "AWS_IAM"

  # Custom IAM Policies
  lambda_custom_policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ]
          Resource = "arn:aws:s3:::my-advanced-bucket/*"
        }
      ]
    })
    secrets_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Resource = "arn:aws:secretsmanager:us-west-2:*:secret:my-app-secrets-*"
        }
      ]
    })
  }

  tags = {
    Environment = "production"
    Project     = "advanced-serverless"
    Owner       = "devops-team"
    CostCenter  = "engineering"
  }
}

# Create CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-errors-${module.advanced_serverless.lambda_function_name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Lambda function error rate"
  alarm_actions       = []

  dimensions = {
    FunctionName = module.advanced_serverless.lambda_function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "lambda-duration-${module.advanced_serverless.lambda_function_name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"
  alarm_description   = "Lambda function duration"
  alarm_actions       = []

  dimensions = {
    FunctionName = module.advanced_serverless.lambda_function_name
  }
}

# Create DynamoDB CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttled_requests" {
  alarm_name          = "dynamodb-throttled-requests-${module.advanced_serverless.dynamodb_table_name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "DynamoDB throttled requests"
  alarm_actions       = []

  dimensions = {
    TableName = module.advanced_serverless.dynamodb_table_name
  }
}

# Outputs
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.advanced_serverless.serverless_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.advanced_serverless.lambda_function_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.advanced_serverless.dynamodb_table_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "kms_key_arn" {
  description = "KMS key ARN for DynamoDB encryption"
  value       = aws_kms_key.dynamodb.arn
} 