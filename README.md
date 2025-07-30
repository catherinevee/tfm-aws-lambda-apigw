# AWS Lambda + API Gateway + DynamoDB Terraform Module

A comprehensive Terraform module for creating serverless applications with AWS Lambda, API Gateway, and DynamoDB. This module provides a complete serverless stack with proper IAM roles, CloudWatch logging, and security configurations.

## Features

- **Lambda Function**: Serverless compute with configurable runtime, memory, and timeout
- **API Gateway**: RESTful API with proxy integration to Lambda
- **DynamoDB**: NoSQL database with configurable indexes and encryption
- **IAM Roles**: Proper permissions and least-privilege access
- **CloudWatch Logging**: Centralized logging with configurable retention
- **Security**: Server-side encryption, VPC support, and proper access controls
- **Flexibility**: Conditional resource creation and extensive customization options

## Usage

### Basic Usage

```hcl
module "serverless_app" {
  source = "./tfm-aws-lambda-apigw"

  lambda_function_name = "my-serverless-function"
  lambda_handler       = "index.handler"
  lambda_runtime       = "nodejs18.x"
  lambda_source_dir    = "./src"

  dynamodb_table_name = "my-app-table"
  dynamodb_hash_key   = "id"

  api_gateway_name = "my-api"
  api_gateway_stage_name = "prod"

  tags = {
    Environment = "production"
    Project     = "serverless-app"
  }
}
```

### Advanced Usage

```hcl
module "serverless_app" {
  source = "./tfm-aws-lambda-apigw"

  # Lambda Configuration
  lambda_function_name = "advanced-function"
  lambda_handler       = "index.handler"
  lambda_runtime       = "nodejs18.x"
  lambda_timeout       = 60
  lambda_memory_size   = 512
  lambda_source_dir    = "./src"
  
  lambda_environment_variables = {
    TABLE_NAME = "my-dynamodb-table"
    LOG_LEVEL  = "INFO"
  }

  lambda_vpc_config = {
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
    security_group_ids = ["sg-12345678"]
  }

  # DynamoDB Configuration
  dynamodb_table_name = "advanced-table"
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
    }
  ]

  dynamodb_global_secondary_indexes = [
    {
      name            = "gsi1"
      hash_key        = "gsi1pk"
      range_key       = "gsi1sk"
      projection_type = "ALL"
    }
  ]

  # API Gateway Configuration
  api_gateway_name        = "advanced-api"
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
            "s3:PutObject"
          ]
          Resource = "arn:aws:s3:::my-bucket/*"
        }
      ]
    })
  }

  tags = {
    Environment = "production"
    Project     = "advanced-serverless"
    Owner       = "devops-team"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| archive | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| archive | >= 2.0 |

## Inputs

### Common Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| tags | A map of tags to assign to all resources | `map(string)` | `{}` | no |

### Lambda Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_lambda | Whether to create Lambda function | `bool` | `true` | no |
| lambda_function_name | Name of the Lambda function | `string` | `"serverless-function"` | no |
| lambda_handler | Lambda function entry point in your code | `string` | `"index.handler"` | no |
| lambda_runtime | Lambda function runtime | `string` | `"nodejs18.x"` | no |
| lambda_timeout | Lambda function timeout in seconds | `number` | `30` | no |
| lambda_memory_size | Lambda function memory size in MB | `number` | `128` | no |
| lambda_description | Description of the Lambda function | `string` | `"Serverless function created by Terraform"` | no |
| lambda_publish | Whether to publish creation/change as new Lambda function version | `bool` | `false` | no |
| lambda_filename | Path to the function's deployment package within the local filesystem | `string` | `null` | no |
| lambda_source_dir | Path to the source directory for creating ZIP file | `string` | `null` | no |
| lambda_environment_variables | Environment variables for Lambda function | `map(string)` | `null` | no |
| lambda_vpc_config | VPC configuration for Lambda function | `object` | `null` | no |
| lambda_log_retention_days | CloudWatch log group retention in days | `number` | `14` | no |
| lambda_custom_policies | Map of custom IAM policies to attach to Lambda role | `map(string)` | `{}` | no |

### DynamoDB Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_dynamodb | Whether to create DynamoDB table | `bool` | `true` | no |
| dynamodb_table_name | Name of the DynamoDB table | `string` | `"serverless-table"` | no |
| dynamodb_billing_mode | DynamoDB billing mode | `string` | `"PAY_PER_REQUEST"` | no |
| dynamodb_hash_key | DynamoDB table hash key | `string` | `"id"` | no |
| dynamodb_range_key | DynamoDB table range key | `string` | `null` | no |
| dynamodb_attributes | List of DynamoDB table attributes | `list(object)` | `[{"name": "id", "type": "S"}]` | no |
| dynamodb_global_secondary_indexes | List of DynamoDB global secondary indexes | `list(object)` | `[]` | no |
| dynamodb_local_secondary_indexes | List of DynamoDB local secondary indexes | `list(object)` | `[]` | no |
| dynamodb_point_in_time_recovery | Enable point-in-time recovery for DynamoDB table | `bool` | `true` | no |
| dynamodb_server_side_encryption | Enable server-side encryption for DynamoDB table | `bool` | `true` | no |
| dynamodb_kms_key_arn | KMS key ARN for DynamoDB encryption | `string` | `null` | no |

### API Gateway Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_api_gateway | Whether to create API Gateway | `bool` | `true` | no |
| api_gateway_name | Name of the API Gateway | `string` | `"serverless-api"` | no |
| api_gateway_description | Description of the API Gateway | `string` | `"Serverless API Gateway created by Terraform"` | no |
| api_gateway_endpoint_types | List of endpoint types for API Gateway | `list(string)` | `["REGIONAL"]` | no |
| api_gateway_stage_name | Name of the API Gateway stage | `string` | `"prod"` | no |
| api_gateway_authorization | Authorization type for API Gateway methods | `string` | `"NONE"` | no |
| api_gateway_authorizer_id | ID of the API Gateway authorizer | `string` | `null` | no |

## Outputs

### Lambda Outputs

| Name | Description |
|------|-------------|
| lambda_function_arn | ARN of the Lambda function |
| lambda_function_name | Name of the Lambda function |
| lambda_function_invoke_arn | Invocation ARN of the Lambda function |
| lambda_function_version | Latest published version of the Lambda function |
| lambda_role_arn | ARN of the Lambda execution role |
| lambda_role_name | Name of the Lambda execution role |
| lambda_log_group_name | Name of the CloudWatch log group for Lambda |

### DynamoDB Outputs

| Name | Description |
|------|-------------|
| dynamodb_table_arn | ARN of the DynamoDB table |
| dynamodb_table_id | ID of the DynamoDB table |
| dynamodb_table_name | Name of the DynamoDB table |
| dynamodb_table_stream_arn | Stream ARN of the DynamoDB table |

### API Gateway Outputs

| Name | Description |
|------|-------------|
| api_gateway_id | ID of the API Gateway |
| api_gateway_arn | ARN of the API Gateway |
| api_gateway_name | Name of the API Gateway |
| api_gateway_execution_arn | Execution ARN of the API Gateway |
| api_gateway_invoke_url | Invoke URL of the API Gateway |
| api_gateway_stage_arn | ARN of the API Gateway stage |

### Combined Outputs

| Name | Description |
|------|-------------|
| serverless_endpoint | Complete serverless API endpoint URL |
| all_outputs | All outputs in a single map for easy consumption |

## Examples

### Basic Serverless API

```hcl
module "basic_serverless" {
  source = "./tfm-aws-lambda-apigw"

  lambda_function_name = "basic-api"
  lambda_source_dir    = "./lambda"
  
  dynamodb_table_name = "basic-table"
  
  api_gateway_name = "basic-api-gateway"
}
```

### Serverless with Custom Domain

```hcl
# Create custom domain certificate
resource "aws_acm_certificate" "api" {
  domain_name       = "api.example.com"
  validation_method = "DNS"
}

# Create custom domain
resource "aws_api_gateway_domain_name" "api" {
  domain_name     = "api.example.com"
  certificate_arn = aws_acm_certificate.api.arn
}

# Create base path mapping
resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = module.serverless_app.api_gateway_id
  stage_name  = module.serverless_app.api_gateway_stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}

module "serverless_app" {
  source = "./tfm-aws-lambda-apigw"

  lambda_function_name = "custom-domain-api"
  lambda_source_dir    = "./lambda"
  
  dynamodb_table_name = "custom-domain-table"
  
  api_gateway_name = "custom-domain-api"
}
```

### Serverless with Cognito Authorization

```hcl
# Create Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "serverless-user-pool"
}

# Create Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "serverless-client"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Create Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = module.serverless_app.api_gateway_id
  provider_arns = [aws_cognito_user_pool.main.arn]
}

module "serverless_app" {
  source = "./tfm-aws-lambda-apigw"

  lambda_function_name = "auth-api"
  lambda_source_dir    = "./lambda"
  
  dynamodb_table_name = "auth-table"
  
  api_gateway_name        = "auth-api"
  api_gateway_authorization = "COGNITO_USER_POOLS"
  api_gateway_authorizer_id = aws_api_gateway_authorizer.cognito.id
}
```

## Lambda Function Examples

### Node.js Lambda Function

```javascript
// index.js
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  const response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  };

  try {
    const httpMethod = event.httpMethod;
    const path = event.path;
    
    switch (httpMethod) {
      case 'GET':
        if (path === '/items') {
          const params = {
            TableName: process.env.TABLE_NAME
          };
          const result = await dynamodb.scan(params).promise();
          response.body = JSON.stringify(result.Items);
        } else if (path.startsWith('/items/')) {
          const id = path.split('/')[2];
          const params = {
            TableName: process.env.TABLE_NAME,
            Key: { id }
          };
          const result = await dynamodb.get(params).promise();
          response.body = JSON.stringify(result.Item);
        }
        break;
        
      case 'POST':
        if (path === '/items') {
          const item = JSON.parse(event.body);
          const params = {
            TableName: process.env.TABLE_NAME,
            Item: item
          };
          await dynamodb.put(params).promise();
          response.body = JSON.stringify({ message: 'Item created successfully' });
        }
        break;
        
      default:
        response.statusCode = 405;
        response.body = JSON.stringify({ error: 'Method not allowed' });
    }
  } catch (error) {
    response.statusCode = 500;
    response.body = JSON.stringify({ error: error.message });
  }

  return response;
};
```

### Python Lambda Function

```python
# index.py
import json
import boto3
import os
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    response = {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        }
    }
    
    try:
        http_method = event['httpMethod']
        path = event['path']
        
        if http_method == 'GET':
            if path == '/items':
                result = table.scan()
                response['body'] = json.dumps(result['Items'])
            elif path.startswith('/items/'):
                item_id = path.split('/')[2]
                result = table.get_item(Key={'id': item_id})
                response['body'] = json.dumps(result.get('Item'))
                
        elif http_method == 'POST':
            if path == '/items':
                item = json.loads(event['body'])
                table.put_item(Item=item)
                response['body'] = json.dumps({'message': 'Item created successfully'})
                
        else:
            response['statusCode'] = 405
            response['body'] = json.dumps({'error': 'Method not allowed'})
            
    except Exception as e:
        response['statusCode'] = 500
        response['body'] = json.dumps({'error': str(e)})
    
    return response
```

## Best Practices

### Security
- Always use least-privilege IAM policies
- Enable server-side encryption for DynamoDB
- Use VPC for Lambda when accessing private resources
- Implement proper authorization for API Gateway
- Use environment variables for sensitive configuration

### Performance
- Choose appropriate Lambda memory size (affects CPU allocation)
- Use DynamoDB on-demand billing for unpredictable workloads
- Implement proper error handling and retries
- Use CloudWatch metrics for monitoring

### Cost Optimization
- Use DynamoDB on-demand billing for development
- Set appropriate CloudWatch log retention periods
- Monitor Lambda execution times and memory usage
- Use API Gateway caching when appropriate

### Monitoring
- Set up CloudWatch alarms for Lambda errors
- Monitor DynamoDB consumed capacity
- Track API Gateway 4xx and 5xx errors
- Use AWS X-Ray for distributed tracing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Support

For issues and questions, please open an issue in the GitHub repository.