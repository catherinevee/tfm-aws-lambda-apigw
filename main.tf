# =============================================================================
# Lambda Function
# =============================================================================

resource "aws_lambda_function" "this" {
  count = var.create_lambda ? 1 : 0

  filename         = var.lambda_filename != null ? var.lambda_filename : data.archive_file.lambda_zip[0].output_path
  function_name    = var.lambda_function_name
  role            = aws_iam_role.lambda_role[0].arn
  handler         = var.lambda_handler
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  description     = var.lambda_description
  publish         = var.lambda_publish

  dynamic "environment" {
    for_each = var.lambda_environment_variables != null ? [var.lambda_environment_variables] : []
    content {
      variables = environment.value
    }
  }

  dynamic "vpc_config" {
    for_each = var.lambda_vpc_config != null ? [var.lambda_vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  tags = merge(var.tags, {
    Name = var.lambda_function_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# Create ZIP file for Lambda function
data "archive_file" "lambda_zip" {
  count = var.create_lambda && var.lambda_filename == null ? 1 : 0

  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/lambda_function.zip"
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  count = var.create_lambda ? 1 : 0

  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.lambda_log_retention_days

  tags = var.tags
}

# =============================================================================
# DynamoDB Table
# =============================================================================

resource "aws_dynamodb_table" "this" {
  count = var.create_dynamodb ? 1 : 0

  name           = var.dynamodb_table_name
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = var.dynamodb_hash_key
  range_key      = var.dynamodb_range_key

  dynamic "attribute" {
    for_each = var.dynamodb_attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.dynamodb_global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.dynamodb_local_secondary_indexes
    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = lookup(local_secondary_index.value, "non_key_attributes", null)
    }
  }

  point_in_time_recovery {
    enabled = var.dynamodb_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = var.dynamodb_server_side_encryption
    kms_key_arn = var.dynamodb_kms_key_arn
  }

  tags = merge(var.tags, {
    Name = var.dynamodb_table_name
  })
}

# =============================================================================
# API Gateway
# =============================================================================

resource "aws_api_gateway_rest_api" "this" {
  count = var.create_api_gateway ? 1 : 0

  name        = var.api_gateway_name
  description = var.api_gateway_description

  endpoint_configuration {
    types = var.api_gateway_endpoint_types
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "proxy" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.this[0].id
  parent_id   = aws_api_gateway_rest_api.this[0].root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  resource_id   = aws_api_gateway_resource.proxy[0].id
  http_method   = "ANY"
  authorization = var.api_gateway_authorization
  authorizer_id = var.api_gateway_authorizer_id

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "lambda" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.this[0].id
  resource_id = aws_api_gateway_resource.proxy[0].id
  http_method = aws_api_gateway_method.proxy[0].http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.this[0].invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  resource_id   = aws_api_gateway_rest_api.this[0].root_resource_id
  http_method   = "ANY"
  authorization = var.api_gateway_authorization
  authorizer_id = var.api_gateway_authorizer_id
}

resource "aws_api_gateway_integration" "lambda_root" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.this[0].id
  resource_id = aws_api_gateway_rest_api.this[0].root_resource_id
  http_method = aws_api_gateway_method.proxy_root[0].http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.this[0].invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  count = var.create_api_gateway ? 1 : 0

  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.this[0].id
  stage_name  = var.api_gateway_stage_name

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# Lambda Permission for API Gateway
# =============================================================================

resource "aws_lambda_permission" "apigw" {
  count = var.create_lambda && var.create_api_gateway ? 1 : 0

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[0].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this[0].execution_arn}/*/*"
}

# =============================================================================
# IAM Roles and Policies
# =============================================================================

resource "aws_iam_role" "lambda_role" {
  count = var.create_lambda ? 1 : 0

  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = var.create_lambda ? 1 : 0

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.create_lambda && var.lambda_vpc_config != null ? 1 : 0

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# DynamoDB access policy for Lambda
resource "aws_iam_role_policy" "lambda_dynamodb" {
  count = var.create_lambda && var.create_dynamodb ? 1 : 0

  name = "${var.lambda_function_name}-dynamodb-policy"
  role = aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:BatchGetItem"
        ]
        Resource = [
          aws_dynamodb_table.this[0].arn,
          "${aws_dynamodb_table.this[0].arn}/index/*"
        ]
      }
    ]
  })
}

# Custom IAM policies
resource "aws_iam_role_policy" "lambda_custom" {
  for_each = var.create_lambda ? var.lambda_custom_policies : {}

  name = "${var.lambda_function_name}-${each.key}-policy"
  role = aws_iam_role.lambda_role[0].id

  policy = each.value
} 