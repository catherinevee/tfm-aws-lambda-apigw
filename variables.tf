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

# ==============================================================================
# Enhanced API Gateway Configuration Variables
# ==============================================================================

variable "api_gateways" {
  description = "Map of API Gateways to create"
  type = map(object({
    name = string
    description = optional(string, null)
    endpoint_configuration = optional(object({
      types = list(string)
      vpc_endpoint_ids = optional(list(string), [])
    }), {})
    api_key_source = optional(string, "HEADER")
    binary_media_types = optional(list(string), [])
    body = optional(string, null)
    disable_execute_api_endpoint = optional(bool, false)
    fail_on_warnings = optional(bool, false)
    minimum_compression_size = optional(number, null)
    parameters = optional(map(string), {})
    policy = optional(string, null)
    put_rest_api_mode = optional(string, null)
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "api_gateway_rest_api_policies" {
  description = "Map of API Gateway REST API policies to create"
  type = map(object({
    rest_api_id = string
    policy = string
  }))
  default = {}
}

variable "api_gateway_deployments" {
  description = "Map of API Gateway deployments to create"
  type = map(object({
    rest_api_id = string
    stage_name = optional(string, null)
    description = optional(string, null)
    stage_description = optional(string, null)
    variables = optional(map(string), {})
    triggers = optional(map(string), {})
    lifecycle = optional(object({
      create_before_destroy = optional(bool, false)
    }), {})
  }))
  default = {}
}

variable "api_gateway_stages" {
  description = "Map of API Gateway stages to create"
  type = map(object({
    deployment_id = string
    rest_api_id = string
    stage_name = string
    cache_cluster_enabled = optional(bool, false)
    cache_cluster_size = optional(string, null)
    client_certificate_id = optional(string, null)
    description = optional(string, null)
    documentation_version = optional(string, null)
    variables = optional(map(string), {})
    xray_tracing_enabled = optional(bool, false)
    access_log_settings = optional(object({
      destination_arn = string
      format = string
    }), {})
    canary_settings = optional(object({
      percent_traffic = optional(number, null)
      stage_variable_overrides = optional(map(string), {})
      use_stage_cache = optional(bool, null)
    }), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "api_gateway_resources" {
  description = "Map of API Gateway resources to create"
  type = map(object({
    rest_api_id = string
    parent_id = string
    path_part = string
  }))
  default = {}
}

variable "api_gateway_methods" {
  description = "Map of API Gateway methods to create"
  type = map(object({
    rest_api_id = string
    resource_id = string
    http_method = string
    authorization = optional(string, "NONE")
    authorizer_id = optional(string, null)
    authorization_scopes = optional(list(string), [])
    api_key_required = optional(bool, null)
    operation_name = optional(string, null)
    request_models = optional(map(string), {})
    request_parameters = optional(map(bool), {})
    request_validator_id = optional(string, null)
  }))
  default = {}
}

variable "api_gateway_method_settings" {
  description = "Map of API Gateway method settings to create"
  type = map(object({
    rest_api_id = string
    stage_name = string
    method_path = string
    settings = object({
      metrics_enabled = optional(bool, null)
      logging_level = optional(string, null)
      data_trace_enabled = optional(bool, null)
      throttling_burst_limit = optional(number, null)
      throttling_rate_limit = optional(number, null)
      caching_enabled = optional(bool, null)
      cache_ttl_in_seconds = optional(number, null)
      cache_data_encrypted = optional(bool, null)
      require_authorization_for_cache_control = optional(bool, null)
      unauthorized_cache_control_header_strategy = optional(string, null)
    })
  }))
  default = {}
}

variable "api_gateway_integrations" {
  description = "Map of API Gateway integrations to create"
  type = map(object({
    rest_api_id = string
    resource_id = string
    http_method = string
    type = string
    integration_http_method = optional(string, null)
    uri = optional(string, null)
    connection_type = optional(string, "INTERNET")
    connection_id = optional(string, null)
    credentials = optional(string, null)
    request_parameters = optional(map(string), {})
    request_templates = optional(map(string), {})
    passthrough_behavior = optional(string, "WHEN_NO_MATCH")
    content_handling = optional(string, null)
    timeout_milliseconds = optional(number, null)
    cache_key_parameters = optional(list(string), [])
    cache_namespace = optional(string, null)
  }))
  default = {}
}

variable "api_gateway_integration_responses" {
  description = "Map of API Gateway integration responses to create"
  type = map(object({
    rest_api_id = string
    resource_id = string
    http_method = string
    status_code = string
    selection_pattern = optional(string, null)
    response_parameters = optional(map(string), {})
    response_templates = optional(map(string), {})
    content_handling = optional(string, null)
  }))
  default = {}
}

variable "api_gateway_method_responses" {
  description = "Map of API Gateway method responses to create"
  type = map(object({
    rest_api_id = string
    resource_id = string
    http_method = string
    status_code = string
    response_models = optional(map(string), {})
    response_parameters = optional(map(bool), {})
  }))
  default = {}
}

variable "api_gateway_authorizers" {
  description = "Map of API Gateway authorizers to create"
  type = map(object({
    name = string
    rest_api_id = string
    type = string
    authorizer_uri = optional(string, null)
    authorizer_credentials = optional(string, null)
    authorizer_result_ttl_in_seconds = optional(number, null)
    identity_source = optional(string, "method.request.header.Authorization")
    identity_validation_expression = optional(string, null)
    provider_arns = optional(list(string), [])
  }))
  default = {}
}

variable "api_gateway_models" {
  description = "Map of API Gateway models to create"
  type = map(object({
    name = string
    rest_api_id = string
    description = optional(string, null)
    content_type = string
    schema = string
  }))
  default = {}
}

variable "api_gateway_request_validators" {
  description = "Map of API Gateway request validators to create"
  type = map(object({
    name = string
    rest_api_id = string
    validate_request_body = optional(bool, false)
    validate_request_parameters = optional(bool, false)
  }))
  default = {}
}

variable "api_gateway_gateway_responses" {
  description = "Map of API Gateway gateway responses to create"
  type = map(object({
    rest_api_id = string
    response_type = string
    status_code = optional(string, null)
    response_parameters = optional(map(string), {})
    response_templates = optional(map(string), {})
  }))
  default = {}
}

variable "api_gateway_documentation_parts" {
  description = "Map of API Gateway documentation parts to create"
  type = map(object({
    rest_api_id = string
    location = object({
      type = string
      path = optional(string, null)
      method = optional(string, null)
      status_code = optional(string, null)
      name = optional(string, null)
    })
    properties = string
  }))
  default = {}
}

variable "api_gateway_documentation_versions" {
  description = "Map of API Gateway documentation versions to create"
  type = map(object({
    rest_api_id = string
    version = string
    description = optional(string, null)
  }))
  default = {}
}

variable "api_gateway_base_path_mappings" {
  description = "Map of API Gateway base path mappings to create"
  type = map(object({
    api_id = string
    stage_name = string
    domain_name = string
    base_path = optional(string, null)
  }))
  default = {}
}

variable "api_gateway_client_certificates" {
  description = "Map of API Gateway client certificates to create"
  type = map(object({
    description = optional(string, null)
  }))
  default = {}
}

variable "api_gateway_usage_plans" {
  description = "Map of API Gateway usage plans to create"
  type = map(object({
    name = string
    description = optional(string, null)
    api_stages = optional(list(object({
      api_id = string
      stage = string
    })), [])
    quota_settings = optional(object({
      limit = number
      offset = optional(number, 0)
      period = string
    }), {})
    throttle_settings = optional(object({
      burst_limit = optional(number, null)
      rate_limit = optional(number, null)
    }), {})
    product_code = optional(string, null)
  }))
  default = {}
}

variable "api_gateway_usage_plan_keys" {
  description = "Map of API Gateway usage plan keys to create"
  type = map(object({
    key_id = string
    key_type = string
    usage_plan_id = string
  }))
  default = {}
}

variable "api_gateway_api_keys" {
  description = "Map of API Gateway API keys to create"
  type = map(object({
    name = string
    description = optional(string, null)
    enabled = optional(bool, true)
    value = optional(string, null)
  }))
  default = {}
}

variable "api_gateway_vpc_links" {
  description = "Map of API Gateway VPC links to create"
  type = map(object({
    name = string
    target_arns = list(string)
    description = optional(string, null)
  }))
  default = {}
}

# ==============================================================================
# Enhanced DynamoDB Configuration Variables
# ==============================================================================

variable "dynamodb_tables" {
  description = "Map of DynamoDB tables to create"
  type = map(object({
    name = string
    billing_mode = optional(string, "PAY_PER_REQUEST")
    read_capacity = optional(number, null)
    write_capacity = optional(number, null)
    hash_key = string
    range_key = optional(string, null)
    
    # Attributes
    attributes = list(object({
      name = string
      type = string
    }))
    
    # Global Secondary Indexes
    global_secondary_indexes = optional(list(object({
      name = string
      hash_key = string
      range_key = optional(string, null)
      projection_type = string
      non_key_attributes = optional(list(string), [])
      read_capacity = optional(number, null)
      write_capacity = optional(number, null)
      write_provisioned_throughput_exceeded = optional(bool, null)
      read_provisioned_throughput_exceeded = optional(bool, null)
    })), [])
    
    # Local Secondary Indexes
    local_secondary_indexes = optional(list(object({
      name = string
      range_key = string
      projection_type = string
      non_key_attributes = optional(list(string), [])
    })), [])
    
    # Point-in-time recovery
    point_in_time_recovery = optional(object({
      enabled = optional(bool, true)
    }), {})
    
    # Server-side encryption
    server_side_encryption = optional(object({
      enabled = optional(bool, true)
      kms_key_arn = optional(string, null)
    }), {})
    
    # Stream configuration
    stream_enabled = optional(bool, false)
    stream_view_type = optional(string, null)
    
    # TTL
    ttl = optional(object({
      attribute_name = string
      enabled = optional(bool, true)
    }), {})
    
    # Auto scaling
    autoscaling_enabled = optional(bool, false)
    autoscaling_read_target = optional(number, 70)
    autoscaling_write_target = optional(number, 70)
    autoscaling_read_min_capacity = optional(number, 1)
    autoscaling_read_max_capacity = optional(number, 100)
    autoscaling_write_min_capacity = optional(number, 1)
    autoscaling_write_max_capacity = optional(number, 100)
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "dynamodb_global_tables" {
  description = "Map of DynamoDB global tables to create"
  type = map(object({
    name = string
    billing_mode = optional(string, "PAY_PER_REQUEST")
    read_capacity = optional(number, null)
    write_capacity = optional(number, null)
    hash_key = string
    range_key = optional(string, null)
    
    # Attributes
    attributes = list(object({
      name = string
      type = string
    }))
    
    # Global Secondary Indexes
    global_secondary_indexes = optional(list(object({
      name = string
      hash_key = string
      range_key = optional(string, null)
      projection_type = string
      non_key_attributes = optional(list(string), [])
      read_capacity = optional(number, null)
      write_capacity = optional(number, null)
    })), [])
    
    # Replica configuration
    replicas = list(object({
      region_name = string
      kms_key_arn = optional(string, null)
      point_in_time_recovery = optional(object({
        enabled = optional(bool, true)
      }), {})
      read_capacity = optional(number, null)
      write_capacity = optional(number, null)
      global_secondary_indexes = optional(list(object({
        name = string
        read_capacity = optional(number, null)
        write_capacity = optional(number, null)
      })), [])
    }))
    
    # Stream configuration
    stream_enabled = optional(bool, false)
    stream_view_type = optional(string, null)
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "dynamodb_table_items" {
  description = "Map of DynamoDB table items to create"
  type = map(object({
    table_name = string
    hash_key = string
    range_key = optional(string, null)
    item = string
  }))
  default = {}
}

variable "dynamodb_autoscaling" {
  description = "Map of DynamoDB autoscaling configurations to create"
  type = map(object({
    name = string
    resource_id = string
    scalable_dimension = string
    service_namespace = string
    min_capacity = number
    max_capacity = number
    target_tracking_scaling_policy_configuration = object({
      predefined_metric_specification = optional(object({
        predefined_metric_type = string
        resource_label = optional(string, null)
      }), {})
      customized_metric_specification = optional(object({
        metric_name = string
        namespace = string
        statistic = string
        unit = optional(string, null)
        dimensions = optional(list(object({
          name = string
          value = string
        })), [])
      }), {})
      target_value = number
      scale_in_cooldown = optional(number, null)
      scale_out_cooldown = optional(number, null)
      disable_scale_in = optional(bool, null)
    })
  }))
  default = {}
}

variable "dynamodb_backups" {
  description = "Map of DynamoDB backups to create"
  type = map(object({
    table_name = string
    name = string
  }))
  default = {}
}

variable "dynamodb_kinesis_streaming_destinations" {
  description = "Map of DynamoDB Kinesis streaming destinations to create"
  type = map(object({
    table_name = string
    stream_arn = string
  }))
  default = {}
}

variable "dynamodb_table_replica_auto_scaling" {
  description = "Map of DynamoDB table replica auto scaling configurations to create"
  type = map(object({
    table_name = string
    replica_region = string
    global_secondary_indexes = optional(list(object({
      index_name = string
      read_capacity = optional(object({
        min_capacity = number
        max_capacity = number
        target_tracking_scaling_policy_configuration = object({
          predefined_metric_specification = object({
            predefined_metric_type = string
            resource_label = optional(string, null)
          })
          target_value = number
          scale_in_cooldown = optional(number, null)
          scale_out_cooldown = optional(number, null)
          disable_scale_in = optional(bool, null)
        })
      }), {})
      write_capacity = optional(object({
        min_capacity = number
        max_capacity = number
        target_tracking_scaling_policy_configuration = object({
          predefined_metric_specification = object({
            predefined_metric_type = string
            resource_label = optional(string, null)
          })
          target_value = number
          scale_in_cooldown = optional(number, null)
          scale_out_cooldown = optional(number, null)
          disable_scale_in = optional(bool, null)
        })
      }), {})
    })), [])
  }))
  default = {}
}

# ==============================================================================
# Enhanced Lambda Function Configuration Variables
# ==============================================================================

variable "lambda_functions" {
  description = "Map of Lambda functions to create"
  type = map(object({
    name = string
    description = optional(string, null)
    runtime = optional(string, "nodejs18.x")
    handler = optional(string, "index.handler")
    timeout = optional(number, 30)
    memory_size = optional(number, 128)
    
    # Source code configuration
    filename = optional(string, null)
    source_dir = optional(string, null)
    source_code_hash = optional(string, null)
    s3_bucket = optional(string, null)
    s3_key = optional(string, null)
    s3_object_version = optional(string, null)
    image_uri = optional(string, null)
    
    # Image configuration
    image_config = optional(object({
      command = optional(list(string), [])
      entry_point = optional(list(string), [])
      working_directory = optional(string, null)
    }), {})
    
    # VPC configuration
    vpc_config = optional(object({
      subnet_ids = list(string)
      security_group_ids = list(string)
    }), {})
    
    # File system configuration
    file_system_config = optional(object({
      arn = string
      local_mount_path = string
    }), {})
    
    # Dead letter configuration
    dead_letter_config = optional(object({
      target_arn = string
    }), {})
    
    # Tracing configuration
    tracing_config = optional(object({
      mode = optional(string, "PassThrough")
    }), {})
    
    # KMS configuration
    kms_key_arn = optional(string, null)
    
    # Layers
    layers = optional(list(string), [])
    
    # Runtime management
    runtime_management_config = optional(object({
      update_runtime_on = optional(string, "Auto")
      runtime_version_arn = optional(string, null)
    }), {})
    
    # Snap start
    snap_start = optional(object({
      apply_on = string
    }), {})
    
    # Ephemeral storage
    ephemeral_storage = optional(object({
      size = optional(number, 512)
    }), {})
    
    # Function URL
    function_url = optional(object({
      authorization_type = optional(string, "NONE")
      cors = optional(object({
        allow_credentials = optional(bool, null)
        allow_origins = optional(list(string), [])
        allow_methods = optional(list(string), [])
        allow_headers = optional(list(string), [])
        expose_headers = optional(list(string), [])
        max_age = optional(number, null)
      }), {})
    }), {})
    
    # Event source mappings
    event_source_mappings = optional(list(object({
      event_source_arn = string
      function_name = optional(string, null)
      enabled = optional(bool, true)
      batch_size = optional(number, 100)
      maximum_batching_window_in_seconds = optional(number, 0)
      parallelization_factor = optional(number, 1)
      starting_position = optional(string, "LATEST")
      starting_position_timestamp = optional(string, null)
      destination_config = optional(object({
        on_failure = optional(object({
          destination_arn = string
        }), {})
        on_success = optional(object({
          destination_arn = string
        }), {})
      }), {})
      filter_criteria = optional(object({
        filters = optional(list(object({
          pattern = string
        })), [])
      }), {})
      function_response_types = optional(list(string), [])
      maximum_record_age_in_seconds = optional(number, null)
      maximum_retry_attempts = optional(number, null)
      scaling_config = optional(object({
        maximum_concurrency = optional(number, null)
      }), {})
      self_managed_event_source = optional(object({
        endpoints = map(string)
      }), {})
      source_access_configurations = optional(list(object({
        type = string
        uri = string
      })), [])
      tumbling_window_in_seconds = optional(number, null)
    })), [])
    
    # Aliases
    aliases = optional(list(object({
      name = string
      function_version = string
      description = optional(string, null)
      routing_config = optional(object({
        additional_version_weights = optional(map(number), {})
      }), {})
    })), [])
    
    # Provisioned concurrency
    provisioned_concurrency_configs = optional(list(object({
      qualifier = string
      provisioned_concurrent_executions = number
    })), [])
    
    # Code signing
    code_signing_config = optional(object({
      description = optional(string, null)
      allowed_publishers = object({
        signing_profile_version_arns = optional(list(string), [])
      })
      policies = optional(object({
        untrusted_artifact_on_deployment = string
      }), {})
    }), {})
    
    # Reserved concurrency
    reserved_concurrent_executions = optional(number, null)
    
    # Publish
    publish = optional(bool, false)
    
    # Version description
    version_description = optional(string, null)
    
    # Environment variables
    environment_variables = optional(map(string), {})
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced CloudWatch Configuration Variables
# ==============================================================================

variable "cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups to create"
  type = map(object({
    name = string
    retention_in_days = optional(number, 14)
    kms_key_id = optional(string, null)
    skip_destroy = optional(bool, false)
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "cloudwatch_alarms" {
  description = "Map of CloudWatch alarms to create"
  type = map(object({
    name = string
    comparison_operator = string
    evaluation_periods = number
    metric_name = string
    namespace = string
    period = number
    statistic = string
    threshold = number
    description = optional(string, null)
    actions_enabled = optional(bool, true)
    alarm_actions = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    ok_actions = optional(list(string), [])
    dimensions = optional(map(string), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced IAM Configuration Variables
# ==============================================================================

variable "iam_roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    name = string
    assume_role_policy = string
    description = optional(string, null)
    force_detach_policies = optional(bool, false)
    max_session_duration = optional(number, 3600)
    path = optional(string, "/")
    permissions_boundary = optional(string, null)
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "iam_policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    name = string
    description = optional(string, null)
    path = optional(string, "/")
    policy = string
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "iam_role_policy_attachments" {
  description = "Map of IAM role policy attachments to create"
  type = map(object({
    role = string
    policy_arn = string
  }))
  default = {}
}

variable "iam_role_policies" {
  description = "Map of IAM role policies to create"
  type = map(object({
    name = string
    role = string
    policy = string
  }))
  default = {}
} 