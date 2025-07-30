const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Configure AWS SDK
AWS.config.update({
  region: process.env.AWS_REGION || 'us-west-2'
});

// Initialize other AWS services
const secretsManager = new AWS.SecretsManager();
const s3 = new AWS.S3();

// Utility functions
const createResponse = (statusCode, body, headers = {}) => {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type,Authorization',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      ...headers
    },
    body: JSON.stringify(body)
  };
};

const logMessage = (level, message, data = {}) => {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    data,
    environment: process.env.ENVIRONMENT || 'development'
  };
  
  if (level === 'ERROR') {
    console.error(JSON.stringify(logEntry));
  } else {
    console.log(JSON.stringify(logEntry));
  }
};

const validateItem = (item) => {
  const errors = [];
  
  if (!item.pk) {
    errors.push('pk is required');
  }
  
  if (!item.sk) {
    errors.push('sk is required');
  }
  
  return errors;
};

const generateCompositeKey = (pk, sk) => {
  return `${pk}#${sk}`;
};

exports.handler = async (event) => {
  const startTime = Date.now();
  
  try {
    logMessage('INFO', 'Lambda function invoked', {
      httpMethod: event.httpMethod,
      path: event.path,
      requestId: event.requestContext?.requestId
    });

    // Handle preflight requests
    if (event.httpMethod === 'OPTIONS') {
      return createResponse(200, { message: 'OK' });
    }

    const httpMethod = event.httpMethod;
    const path = event.path;
    const tableName = process.env.TABLE_NAME;

    if (!tableName) {
      throw new Error('TABLE_NAME environment variable is not set');
    }

    switch (httpMethod) {
      case 'GET':
        return await handleGetRequest(path, tableName);
        
      case 'POST':
        return await handlePostRequest(path, event.body, tableName);
        
      case 'PUT':
        return await handlePutRequest(path, event.body, tableName);
        
      case 'DELETE':
        return await handleDeleteRequest(path, tableName);
        
      default:
        return createResponse(405, { error: 'Method not allowed' });
    }

  } catch (error) {
    logMessage('ERROR', 'Lambda function error', {
      error: error.message,
      stack: error.stack,
      duration: Date.now() - startTime
    });

    return createResponse(500, {
      error: 'Internal server error',
      message: process.env.ENVIRONMENT === 'development' ? error.message : 'An unexpected error occurred'
    });
  }
};

async function handleGetRequest(path, tableName) {
  if (path === '/items') {
    // Get all items with pagination
    const limit = 50;
    const params = {
      TableName: tableName,
      Limit: limit
    };

    if (event.queryStringParameters?.lastKey) {
      params.ExclusiveStartKey = JSON.parse(event.queryStringParameters.lastKey);
    }

    const result = await dynamodb.scan(params).promise();
    
    return createResponse(200, {
      items: result.Items,
      count: result.Count,
      lastEvaluatedKey: result.LastEvaluatedKey,
      scannedCount: result.ScannedCount
    });

  } else if (path.startsWith('/items/')) {
    // Get specific item
    const pathParts = path.split('/');
    const pk = pathParts[2];
    const sk = pathParts[3] || 'default';

    const params = {
      TableName: tableName,
      Key: { pk, sk }
    };

    const result = await dynamodb.get(params).promise();
    
    if (result.Item) {
      return createResponse(200, result.Item);
    } else {
      return createResponse(404, { error: 'Item not found' });
    }

  } else if (path === '/query') {
    // Query items by GSI
    const { gsi, pk, sk, skCondition } = event.queryStringParameters || {};
    
    if (!gsi || !pk) {
      return createResponse(400, { error: 'gsi and pk parameters are required' });
    }

    const params = {
      TableName: tableName,
      IndexName: gsi,
      KeyConditionExpression: '#pk = :pk',
      ExpressionAttributeNames: {
        '#pk': `${gsi}pk`
      },
      ExpressionAttributeValues: {
        ':pk': pk
      }
    };

    if (sk && skCondition) {
      params.KeyConditionExpression += ` AND #sk ${skCondition} :sk`;
      params.ExpressionAttributeNames['#sk'] = `${gsi}sk`;
      params.ExpressionAttributeValues[':sk'] = sk;
    }

    const result = await dynamodb.query(params).promise();
    
    return createResponse(200, {
      items: result.Items,
      count: result.Count,
      lastEvaluatedKey: result.LastEvaluatedKey,
      scannedCount: result.ScannedCount
    });

  } else if (path === '/health') {
    // Health check with additional information
    const healthInfo = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'advanced-serverless-api',
      environment: process.env.ENVIRONMENT || 'development',
      region: process.env.AWS_REGION || 'us-west-2',
      tableName: tableName
    };

    // Test DynamoDB connectivity
    try {
      await dynamodb.describeTable({ TableName: tableName }).promise();
      healthInfo.dynamodb = 'connected';
    } catch (error) {
      healthInfo.dynamodb = 'error';
      healthInfo.dynamodbError = error.message;
    }

    return createResponse(200, healthInfo);

  } else {
    return createResponse(404, { error: 'Endpoint not found' });
  }
}

async function handlePostRequest(path, body, tableName) {
  if (path === '/items') {
    const item = JSON.parse(body);
    
    // Validate item
    const validationErrors = validateItem(item);
    if (validationErrors.length > 0) {
      return createResponse(400, { 
        error: 'Validation failed',
        details: validationErrors
      });
    }

    // Add metadata
    item.created_at = new Date().toISOString();
    item.updated_at = new Date().toISOString();
    item.version = 1;

    const params = {
      TableName: tableName,
      Item: item,
      ConditionExpression: 'attribute_not_exists(pk) AND attribute_not_exists(sk)'
    };

    try {
      await dynamodb.put(params).promise();
      
      logMessage('INFO', 'Item created successfully', { pk: item.pk, sk: item.sk });
      
      return createResponse(201, {
        message: 'Item created successfully',
        item: item
      });
    } catch (error) {
      if (error.code === 'ConditionalCheckFailedException') {
        return createResponse(409, { error: 'Item already exists' });
      }
      throw error;
    }

  } else if (path === '/batch') {
    // Batch write items
    const { items } = JSON.parse(body);
    
    if (!Array.isArray(items) || items.length === 0) {
      return createResponse(400, { error: 'items array is required and must not be empty' });
    }

    // Validate all items
    const validationErrors = [];
    items.forEach((item, index) => {
      const errors = validateItem(item);
      if (errors.length > 0) {
        validationErrors.push({ index, errors });
      }
    });

    if (validationErrors.length > 0) {
      return createResponse(400, {
        error: 'Validation failed',
        details: validationErrors
      });
    }

    // Add metadata to all items
    const timestamp = new Date().toISOString();
    items.forEach(item => {
      item.created_at = timestamp;
      item.updated_at = timestamp;
      item.version = 1;
    });

    // Split items into batches of 25 (DynamoDB limit)
    const batches = [];
    for (let i = 0; i < items.length; i += 25) {
      batches.push(items.slice(i, i + 25));
    }

    const results = [];
    for (const batch of batches) {
      const params = {
        RequestItems: {
          [tableName]: batch.map(item => ({
            PutRequest: { Item: item }
          }))
        }
      };

      const result = await dynamodb.batchWrite(params).promise();
      results.push(result);
    }

    return createResponse(201, {
      message: 'Batch write completed',
      processedItems: items.length,
      results: results
    });

  } else {
    return createResponse(404, { error: 'Endpoint not found' });
  }
}

async function handlePutRequest(path, body, tableName) {
  if (path.startsWith('/items/')) {
    const pathParts = path.split('/');
    const pk = pathParts[2];
    const sk = pathParts[3] || 'default';
    
    const updates = JSON.parse(body);
    updates.updated_at = new Date().toISOString();

    // Build update expression
    const updateExpression = 'SET ' + Object.keys(updates).map(key => `#${key} = :${key}`).join(', ');
    const expressionAttributeNames = {};
    const expressionAttributeValues = {};

    Object.keys(updates).forEach(key => {
      expressionAttributeNames[`#${key}`] = key;
      expressionAttributeValues[`:${key}`] = updates[key];
    });

    // Add version increment
    expressionAttributeNames['#version'] = 'version';
    expressionAttributeValues[':version'] = 1;
    expressionAttributeValues[':currentVersion'] = updates.version || 0;

    const params = {
      TableName: tableName,
      Key: { pk, sk },
      UpdateExpression: updateExpression + ', #version = #version + :version',
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      ConditionExpression: '#version = :currentVersion',
      ReturnValues: 'ALL_NEW'
    };

    try {
      const result = await dynamodb.update(params).promise();
      
      logMessage('INFO', 'Item updated successfully', { pk, sk });
      
      return createResponse(200, {
        message: 'Item updated successfully',
        item: result.Attributes
      });
    } catch (error) {
      if (error.code === 'ConditionalCheckFailedException') {
        return createResponse(409, { error: 'Version conflict - item was modified by another request' });
      }
      throw error;
    }

  } else {
    return createResponse(404, { error: 'Endpoint not found' });
  }
}

async function handleDeleteRequest(path, tableName) {
  if (path.startsWith('/items/')) {
    const pathParts = path.split('/');
    const pk = pathParts[2];
    const sk = pathParts[3] || 'default';

    const params = {
      TableName: tableName,
      Key: { pk, sk },
      ReturnValues: 'ALL_OLD'
    };

    const result = await dynamodb.delete(params).promise();
    
    if (result.Attributes) {
      logMessage('INFO', 'Item deleted successfully', { pk, sk });
      
      return createResponse(200, {
        message: 'Item deleted successfully',
        deletedItem: result.Attributes
      });
    } else {
      return createResponse(404, { error: 'Item not found' });
    }

  } else {
    return createResponse(404, { error: 'Endpoint not found' });
  }
} 