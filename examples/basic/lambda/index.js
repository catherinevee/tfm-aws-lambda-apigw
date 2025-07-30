const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  const response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
    }
  };

  try {
    const httpMethod = event.httpMethod;
    const path = event.path;
    
    // Handle preflight requests
    if (httpMethod === 'OPTIONS') {
      return response;
    }
    
    switch (httpMethod) {
      case 'GET':
        if (path === '/items') {
          // Get all items
          const params = {
            TableName: process.env.TABLE_NAME || 'basic-serverless-table'
          };
          const result = await dynamodb.scan(params).promise();
          response.body = JSON.stringify({
            items: result.Items,
            count: result.Count
          });
        } else if (path.startsWith('/items/')) {
          // Get specific item
          const id = path.split('/')[2];
          const params = {
            TableName: process.env.TABLE_NAME || 'basic-serverless-table',
            Key: { id }
          };
          const result = await dynamodb.get(params).promise();
          if (result.Item) {
            response.body = JSON.stringify(result.Item);
          } else {
            response.statusCode = 404;
            response.body = JSON.stringify({ error: 'Item not found' });
          }
        } else if (path === '/health') {
          // Health check endpoint
          response.body = JSON.stringify({ 
            status: 'healthy',
            timestamp: new Date().toISOString(),
            service: 'basic-serverless-api'
          });
        } else {
          response.statusCode = 404;
          response.body = JSON.stringify({ error: 'Endpoint not found' });
        }
        break;
        
      case 'POST':
        if (path === '/items') {
          // Create new item
          const item = JSON.parse(event.body);
          if (!item.id) {
            item.id = Date.now().toString();
          }
          item.created_at = new Date().toISOString();
          
          const params = {
            TableName: process.env.TABLE_NAME || 'basic-serverless-table',
            Item: item
          };
          await dynamodb.put(params).promise();
          response.statusCode = 201;
          response.body = JSON.stringify({ 
            message: 'Item created successfully',
            item: item
          });
        } else {
          response.statusCode = 404;
          response.body = JSON.stringify({ error: 'Endpoint not found' });
        }
        break;
        
      case 'PUT':
        if (path.startsWith('/items/')) {
          // Update item
          const id = path.split('/')[2];
          const updates = JSON.parse(event.body);
          updates.updated_at = new Date().toISOString();
          
          const updateExpression = 'SET ' + Object.keys(updates).map(key => `#${key} = :${key}`).join(', ');
          const expressionAttributeNames = {};
          const expressionAttributeValues = {};
          
          Object.keys(updates).forEach(key => {
            expressionAttributeNames[`#${key}`] = key;
            expressionAttributeValues[`:${key}`] = updates[key];
          });
          
          const params = {
            TableName: process.env.TABLE_NAME || 'basic-serverless-table',
            Key: { id },
            UpdateExpression: updateExpression,
            ExpressionAttributeNames: expressionAttributeNames,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW'
          };
          
          const result = await dynamodb.update(params).promise();
          response.body = JSON.stringify({ 
            message: 'Item updated successfully',
            item: result.Attributes
          });
        } else {
          response.statusCode = 404;
          response.body = JSON.stringify({ error: 'Endpoint not found' });
        }
        break;
        
      case 'DELETE':
        if (path.startsWith('/items/')) {
          // Delete item
          const id = path.split('/')[2];
          const params = {
            TableName: process.env.TABLE_NAME || 'basic-serverless-table',
            Key: { id }
          };
          await dynamodb.delete(params).promise();
          response.body = JSON.stringify({ message: 'Item deleted successfully' });
        } else {
          response.statusCode = 404;
          response.body = JSON.stringify({ error: 'Endpoint not found' });
        }
        break;
        
      default:
        response.statusCode = 405;
        response.body = JSON.stringify({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('Error:', error);
    response.statusCode = 500;
    response.body = JSON.stringify({ 
      error: 'Internal server error',
      message: error.message
    });
  }

  return response;
}; 