import { useEffect, useState } from 'react';
import { v4 as uuidv4 } from 'uuid';
import './App.css';

const API_URL = `${import.meta.env.VITE_API_URL}/todos`;

function App() {
  const [todos, setTodos] = useState([]);
  const [newTodo, setNewTodo] = useState('');

  useEffect(() => {
    fetch(API_URL)
      .then((res) => res.json())
      .then(setTodos);
  }, []);

  const addTodo = async () => {
    if (!newTodo.trim()) return;

    const myHeaders = new Headers();
    myHeaders.append('Content-Type', 'application/json');

    const raw = JSON.stringify({
      id: uuidv4(),
      title: newTodo,
      completed: false,
    });

    const requestOptions = {
      method: 'POST',
      headers: myHeaders,
      body: raw,
      redirect: 'follow',
    };

    try {
      const response = await fetch(API_URL, requestOptions);
      const result = await response.text();
      console.log(result);

      setTodos([...todos, todo]);
      setNewTodo('');
    } catch (error) {
      console.error(error);
    }
  };

  const toggleComplete = async (todo) => {
    await fetch(`${API_URL}/${todo.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...todo, completed: !todo.completed }),
    });
    setTodos(
      todos.map((t) =>
        t.id === todo.id ? { ...t, completed: !t.completed } : t
      )
    );
  };

  const deleteTodo = async (id) => {
    await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
    setTodos(todos.filter((t) => t.id !== id));
  };

  return (
    <div className="app">
      <h1>📝 Todo List</h1>
      <div className="input-section">
        <input
          placeholder="Ajouter une tâche..."
          value={newTodo}
          onChange={(e) => setNewTodo(e.target.value)}
        />
        <button onClick={addTodo}>Ajouter</button>
      </div>
      <ul className="todo-list">
        {todos.map((todo) => (
          <li key={todo.id}>
            <span
              className={todo.completed ? 'completed' : ''}
              onClick={() => toggleComplete(todo)}
            >
              {todo.title}
            </span>
            <button className="delete" onClick={() => deleteTodo(todo.id)}>
              ✖
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
