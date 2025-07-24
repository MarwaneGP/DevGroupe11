import AWS from 'aws-sdk'

const dynamodb = new AWS.DynamoDB.DocumentClient()
const TABLE_NAME = process.env.TABLE_NAME || 'todos'

export const handler = async (event) => {
  const method = event.httpMethod
  const path = event.path
  const body = event.body ? JSON.parse(event.body) : {}

  try {
    if (method === 'GET' && path === '/todos') {
      return await getTodos()
    }

    if (method === 'POST' && path === '/todos') {
      return await createTodo(body)
    }

    if (method === 'PUT' && path.startsWith('/todos/')) {
      const id = path.split('/').pop()
      return await updateTodo(id, body)
    }

    if (method === 'DELETE' && path.startsWith('/todos/')) {
      const id = path.split('/').pop()
      return await deleteTodo(id)
    }

    return response(404, { message: 'Not Found' })
  } catch (err) {
    console.error(err)
    return response(500, { message: 'Server Error' })
  }
}

// === Handlers ===

const getTodos = async () => {
  const result = await dynamodb.scan({ TableName: TABLE_NAME }).promise()
  return response(200, result.Items)
}

const createTodo = async (todo) => {
  if (!todo.id || !todo.title) {
    return response(400, { message: 'Missing id or title' })
  }

  await dynamodb.put({
    TableName: TABLE_NAME,
    Item: todo
  }).promise()

  return response(201, todo)
}

const updateTodo = async (id, data) => {
  await dynamodb.update({
    TableName: TABLE_NAME,
    Key: { id },
    UpdateExpression: 'SET title = :t, completed = :c',
    ExpressionAttributeValues: {
      ':t': data.title || '',
      ':c': data.completed ?? false
    }
  }).promise()

  return response(200, { message: 'Updated' })
}

const deleteTodo = async (id) => {
  await dynamodb.delete({
    TableName: TABLE_NAME,
    Key: { id }
  }).promise()

  return response(200, { message: 'Deleted' })
}

// === Response helper ===

const response = (statusCode, body) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*'
  },
  body: JSON.stringify(body)
})
