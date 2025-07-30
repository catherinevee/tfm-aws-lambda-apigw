# =============================================================================
# Common Variables
# =============================================================================

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Lambda Variables
# =============================================================================

variable "create_lambda" {
  description = "Whether to create Lambda function"
  type        = bool
  default     = true
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "serverless-function"
}

variable "lambda_handler" {
  description = "Lambda function entry point in your code"
  type        = string
  default     = "index.handler"
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "lambda_description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Serverless function created by Terraform"
}

variable "lambda_publish" {
  description = "Whether to publish creation/change as new Lambda function version"
  type        = bool
  default     = false
}

variable "lambda_filename" {
  description = "Path to the function's deployment package within the local filesystem"
  type        = string
  default     = null
}

variable "lambda_source_dir" {
  description = "Path to the source directory for creating ZIP file"
  type        = string
  default     = null
}

variable "lambda_environment_variables" {
  description = "Environment variables for Lambda function"
  type        = map(string)
  default     = null
}

variable "lambda_vpc_config" {
  description = "VPC configuration for Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "lambda_log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14
}

variable "lambda_custom_policies" {
  description = "Map of custom IAM policies to attach to Lambda role"
  type        = map(string)
  default     = {}
}

# =============================================================================
# DynamoDB Variables
# =============================================================================

variable "create_dynamodb" {
  description = "Whether to create DynamoDB table"
  type        = bool
  default     = true
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "serverless-table"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.dynamodb_billing_mode)
    error_message = "Billing mode must be either 'PROVISIONED' or 'PAY_PER_REQUEST'."
  }
}

variable "dynamodb_hash_key" {
  description = "DynamoDB table hash key"
  type        = string
  default     = "id"
}

variable "dynamodb_range_key" {
  description = "DynamoDB table range key"
  type        = string
  default     = null
}

variable "dynamodb_attributes" {
  description = "List of DynamoDB table attributes"
  type = list(object({
    name = string
    type = string
  }))
  default = [
    {
      name = "id"
      type = "S"
    }
  ]
}

variable "dynamodb_global_secondary_indexes" {
  description = "List of DynamoDB global secondary indexes"
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = string
    non_key_attributes = optional(list(string))
  }))
  default = []
}

variable "dynamodb_local_secondary_indexes" {
  description = "List of DynamoDB local secondary indexes"
  type = list(object({
    name               = string
    range_key          = string
    projection_type    = string
    non_key_attributes = optional(list(string))
  }))
  default = []
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB table"
  type        = bool
  default     = true
}

variable "dynamodb_server_side_encryption" {
  description = "Enable server-side encryption for DynamoDB table"
  type        = bool
  default     = true
}

variable "dynamodb_kms_key_arn" {
  description = "KMS key ARN for DynamoDB encryption"
  type        = string
  default     = null
}

# =============================================================================
# API Gateway Variables
# =============================================================================

variable "create_api_gateway" {
  description = "Whether to create API Gateway"
  type        = bool
  default     = true
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "serverless-api"
}

variable "api_gateway_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "Serverless API Gateway created by Terraform"
}

variable "api_gateway_endpoint_types" {
  description = "List of endpoint types for API Gateway"
  type        = list(string)
  default     = ["REGIONAL"]
  validation {
    condition = alltrue([
      for endpoint_type in var.api_gateway_endpoint_types : 
      contains(["EDGE", "REGIONAL", "PRIVATE"], endpoint_type)
    ])
    error_message = "Endpoint types must be one of: EDGE, REGIONAL, PRIVATE."
  }
}

variable "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "prod"
}

variable "api_gateway_authorization" {
  description = "Authorization type for API Gateway methods"
  type        = string
  default     = "NONE"
  validation {
    condition     = contains(["NONE", "AWS_IAM", "CUSTOM", "COGNITO_USER_POOLS"], var.api_gateway_authorization)
    error_message = "Authorization must be one of: NONE, AWS_IAM, CUSTOM, COGNITO_USER_POOLS."
  }
}

variable "api_gateway_authorizer_id" {
  description = "ID of the API Gateway authorizer"
  type        = string
  default     = null
} 