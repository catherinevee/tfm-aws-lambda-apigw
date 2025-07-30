# Examples

This directory contains example configurations for the AWS Lambda + API Gateway + DynamoDB Terraform module.

## Available Examples

### Basic Example (`basic/`)

A simple serverless application with:
- Lambda function with basic DynamoDB operations
- DynamoDB table with single hash key
- API Gateway with proxy integration
- Basic IAM roles and permissions

**Usage:**
```bash
cd examples/basic
terraform init
terraform plan
terraform apply
```

### Advanced Example (`advanced/`)

A production-ready serverless application with:
- Lambda function with VPC configuration
- DynamoDB table with composite keys and GSIs
- API Gateway with IAM authorization
- KMS encryption for DynamoDB
- CloudWatch alarms for monitoring
- Custom IAM policies for S3 and Secrets Manager access
- Comprehensive error handling and logging

**Usage:**
```bash
cd examples/advanced
terraform init
terraform plan
terraform apply
```

## Testing the Examples

After deploying either example, you can test the API endpoints:

### Basic Example Testing

```bash
# Get the API endpoint
API_ENDPOINT=$(terraform output -raw api_endpoint)

# Test health endpoint
curl $API_ENDPOINT/health

# Create an item
curl -X POST $API_ENDPOINT/items \
  -H "Content-Type: application/json" \
  -d '{"id": "test123", "name": "Test Item", "description": "A test item"}'

# Get all items
curl $API_ENDPOINT/items

# Get specific item
curl $API_ENDPOINT/items/test123
```

### Advanced Example Testing

```bash
# Get the API endpoint
API_ENDPOINT=$(terraform output -raw api_endpoint)

# Test health endpoint
curl $API_ENDPOINT/health

# Create an item (requires AWS credentials)
aws sigv4-sign-request --region us-west-2 \
  --service execute-api \
  --method POST \
  --path /items \
  --body '{"pk": "user123", "sk": "profile", "name": "John Doe", "email": "john@example.com"}' \
  $API_ENDPOINT/items
```

## Cleanup

To destroy the resources created by the examples:

```bash
terraform destroy
```

## Customization

Each example can be customized by modifying the variables in the `main.tf` file. Common customizations include:

- Changing the AWS region
- Modifying Lambda function configuration
- Adding more DynamoDB indexes
- Configuring custom domain names
- Adding additional IAM policies
- Setting up monitoring and alerting

## Notes

- The examples use the `us-west-2` region by default
- Make sure you have appropriate AWS credentials configured
- The advanced example creates additional resources (VPC, KMS key, etc.) that may incur costs
- Always review the Terraform plan before applying changes 