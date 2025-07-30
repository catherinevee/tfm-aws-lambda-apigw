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
    
    if (httpMethod === 'GET' && path === '/health') {
      response.body = JSON.stringify({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'test-serverless-api'
      });
    } else if (httpMethod === 'GET' && path === '/test') {
      // Test DynamoDB connectivity
      const params = {
        TableName: process.env.TABLE_NAME || 'test-serverless-table'
      };
      
      try {
        await dynamodb.describeTable({ TableName: params.TableName }).promise();
        response.body = JSON.stringify({
          message: 'DynamoDB connection successful',
          tableName: params.TableName
        });
      } catch (error) {
        response.statusCode = 500;
        response.body = JSON.stringify({
          error: 'DynamoDB connection failed',
          message: error.message
        });
      }
    } else {
      response.statusCode = 404;
      response.body = JSON.stringify({ error: 'Endpoint not found' });
    }
  } catch (error) {
    response.statusCode = 500;
    response.body = JSON.stringify({ error: error.message });
  }

  return response;
}; 