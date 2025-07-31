import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  ScanCommand,
  PutCommand,
  UpdateCommand,
  DeleteCommand,
} from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const dynamodb = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME || 'todos';

export const handler = async (event) => {
  console.log('Lambda event:', JSON.stringify(event, null, 2));
  const method = event.httpMethod;
  const path = event.path;
  let body = {};
  try {
    body = event.body ? JSON.parse(event.body) : {};
  } catch (parseErr) {
    console.error('Error parsing body:', parseErr, 'Raw body:', event.body);
    return response(400, { message: 'Invalid JSON body' });
  }

  try {
    console.log(`Received ${method} request on ${path} with body:`, body);

    if (method === 'GET' && path === '/todos') {
      return await getTodos();
    }

    if (method === 'POST' && path === '/todos') {
      return await createTodo(body);
    }

    if (method === 'PUT' && path.startsWith('/todos/')) {
      const id = path.split('/').pop();
      return await updateTodo(id, body);
    }

    if (method === 'DELETE' && path.startsWith('/todos/')) {
      const id = path.split('/').pop();
      return await deleteTodo(id);
    }

    console.warn('Route not found:', method, path);
    return response(404, { message: 'Not Found' });
  } catch (err) {
    console.error('Handler error:', err);
    return response(500, { message: 'Server Error', error: err.message });
  }
};

// === Handlers ===

const getTodos = async () => {
  console.log('getTodos called');
  try {
    const command = new ScanCommand({ TableName: TABLE_NAME });
    const result = await dynamodb.send(command);
    console.log('getTodos result:', result.Items);
    return response(200, result.Items || []);
  } catch (err) {
    console.error('getTodos error:', err);
    return response(500, {
      message: 'Error fetching todos',
      error: err.message,
    });
  }
};

const createTodo = async (todo) => {
  console.log('createTodo called with:', todo);
  if (!todo.id || !todo.title) {
    console.warn('Missing id or title in todo:', todo);
    return response(400, { message: 'Missing id or title' });
  }

  try {
    const command = new PutCommand({
      TableName: TABLE_NAME,
      Item: todo,
    });

    const result = await dynamodb.send(command);
    console.log('createTodo result:', result);
    return response(201, todo);
  } catch (err) {
    console.error('createTodo error:', err);
    return response(500, {
      message: 'Error creating todo',
      error: err.message,
    });
  }
};

const updateTodo = async (id, data) => {
  console.log('updateTodo called with id:', id, 'data:', data);
  try {
    const command = new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { id },
      UpdateExpression: 'SET title = :t, completed = :c',
      ExpressionAttributeValues: {
        ':t': data.title || '',
        ':c': data.completed ?? false,
      },
    });

    const result = await dynamodb.send(command);
    console.log('updateTodo result:', result);
    return response(200, { message: 'Updated' });
  } catch (err) {
    console.error('updateTodo error:', err);
    return response(500, {
      message: 'Error updating todo',
      error: err.message,
    });
  }
};

const deleteTodo = async (id) => {
  console.log('deleteTodo called with id:', id);
  try {
    const command = new DeleteCommand({
      TableName: TABLE_NAME,
      Key: { id },
    });

    const result = await dynamodb.send(command);
    console.log('deleteTodo result:', result);
    return response(200, { message: 'Deleted' });
  } catch (err) {
    console.error('deleteTodo error:', err);
    return response(500, {
      message: 'Error deleting todo',
      error: err.message,
    });
  }
};

// === Response helper ===

const response = (statusCode, body) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
  },
  body: JSON.stringify(body),
});
