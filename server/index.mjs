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
  const method = event.httpMethod;
  const path = event.path;
  const body = event.body ? JSON.parse(event.body) : {};

  // 👉 Gestion des requêtes CORS preflight
  if (method === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      },
      body: '',
    };
  }

  try {
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

    return response(404, { message: 'Not Found' });
  } catch (err) {
    console.error(err);
    return response(500, { message: 'Server Error' });
  }
};

// === Handlers ===

const getTodos = async () => {
  const command = new ScanCommand({ TableName: TABLE_NAME });
  const result = await dynamodb.send(command);
  return response(200, result.Items || []);
};

const createTodo = async (todo) => {
  if (!todo.id || !todo.title) {
    return response(400, { message: 'Missing id or title' });
  }

  const command = new PutCommand({
    TableName: TABLE_NAME,
    Item: todo,
  });

  await dynamodb.send(command);
  return response(201, todo);
};

const updateTodo = async (id, data) => {
  const command = new UpdateCommand({
    TableName: TABLE_NAME,
    Key: { id },
    UpdateExpression: 'SET title = :t, completed = :c',
    ExpressionAttributeValues: {
      ':t': data.title || '',
      ':c': data.completed ?? false,
    },
  });

  await dynamodb.send(command);
  return response(200, { message: 'Updated' });
};

const deleteTodo = async (id) => {
  const command = new DeleteCommand({
    TableName: TABLE_NAME,
    Key: { id },
  });

  await dynamodb.send(command);
  return response(200, { message: 'Deleted' });
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
