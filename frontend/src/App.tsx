import { useEffect, useState } from "react";
import type { Todo } from "./types/todo";
import { todoApi } from "./api/todoApi";
import { TodoForm } from "./components/TodoForm";
import { TodoItem } from "./components/TodoItem";

function App() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<"all" | "active" | "completed">("all");
  console.log("API URL:", import.meta.env.VITE_API_URL);

  const fetchTodos = async () => {
    try {
      setError(null);
      const data = await todoApi.getAll();
      setTodos(data);
    } catch (err) {
      setError("Failed to load todos. Make sure the backend is running.");
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchTodos();
  }, []);

  const filteredTodos = todos.filter((todo) => {
    if (filter === "active") return !todo.completed;
    if (filter === "completed") return todo.completed;
    return true;
  });

  const activeTodosCount = todos.filter((t) => !t.completed).length;
  const completedTodosCount = todos.filter((t) => t.completed).length;

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-8 px-4">
      <div className="max-w-2xl mx-auto">
        <header className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-800 mb-2">Todo App</h1>
          <p className="text-gray-600">Stay organized and productive</p>
        </header>

        <TodoForm onCreated={fetchTodos} />

        {error && (
          <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
            {error}
          </div>
        )}

        <div className="mt-6 flex items-center justify-between">
          <div className="flex gap-2">
            <button
              onClick={() => setFilter("all")}
              className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                filter === "all"
                  ? "bg-blue-500 text-white"
                  : "bg-white text-gray-700 hover:bg-gray-100"
              }`}
            >
              All ({todos.length})
            </button>
            <button
              onClick={() => setFilter("active")}
              className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                filter === "active"
                  ? "bg-blue-500 text-white"
                  : "bg-white text-gray-700 hover:bg-gray-100"
              }`}
            >
              Active ({activeTodosCount})
            </button>
            <button
              onClick={() => setFilter("completed")}
              className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                filter === "completed"
                  ? "bg-blue-500 text-white"
                  : "bg-white text-gray-700 hover:bg-gray-100"
              }`}
            >
              Completed ({completedTodosCount})
            </button>
          </div>
        </div>

        <div className="mt-4 space-y-3">
          {isLoading ? (
            <div className="text-center py-8">
              <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-blue-500 border-r-transparent"></div>
              <p className="mt-2 text-gray-600">Loading todos...</p>
            </div>
          ) : filteredTodos.length === 0 ? (
            <div className="text-center py-8 bg-white rounded-lg shadow-md">
              <p className="text-gray-500">
                {filter === "all"
                  ? "No todos yet. Add one above!"
                  : filter === "active"
                    ? "No active todos"
                    : "No completed todos"}
              </p>
            </div>
          ) : (
            filteredTodos.map((todo) => (
              <TodoItem key={todo.id} todo={todo} onUpdate={fetchTodos} />
            ))
          )}
        </div>

        {todos.length > 0 && (
          <footer className="mt-6 text-center text-sm text-gray-500">
            {activeTodosCount} item{activeTodosCount !== 1 ? "s" : ""} left
          </footer>
        )}
      </div>
    </div>
  );
}

export default App;
