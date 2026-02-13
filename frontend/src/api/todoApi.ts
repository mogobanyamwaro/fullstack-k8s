import axios from "axios";
import type { Todo, CreateTodoDto, UpdateTodoDto } from "../types/todo";
//
// Set at build time (e.g. .env) or in Kubernetes via deployment env (ConfigMap key VITE_API_URL).
const API_URL =
  import.meta.env.VITE_API_URL ?? "http://backend.fullstack-app.local:30814";

const api = axios.create({
  baseURL: API_URL,
  headers: { "Content-Type": "application/json" },
});

export const todoApi = {
  async getAll(): Promise<Todo[]> {
    try {
      const { data } = await api.get<Todo[]>("/todos");
      return data;
    } catch (err) {
      console.error("todoApi.getAll failed:", err);
      throw err;
    }
  },

  async getOne(id: number): Promise<Todo> {
    try {
      const { data } = await api.get<Todo>(`/todos/${id}`);
      return data;
    } catch (err) {
      console.error("todoApi.getOne failed:", err);
      throw err;
    }
  },

  async create(createDto: CreateTodoDto): Promise<Todo> {
    try {
      const { data } = await api.post<Todo>("/todos", createDto);
      return data;
    } catch (err) {
      console.error("todoApi.create failed:", err);
      throw err;
    }
  },

  async update(id: number, updateDto: UpdateTodoDto): Promise<Todo> {
    try {
      const { data } = await api.patch<Todo>(`/todos/${id}`, updateDto);
      return data;
    } catch (err) {
      console.error("todoApi.update failed:", err);
      throw err;
    }
  },

  async toggle(id: number): Promise<Todo> {
    try {
      const { data } = await api.patch<Todo>(`/todos/${id}/toggle`);
      return data;
    } catch (err) {
      console.error("todoApi.toggle failed:", err);
      throw err;
    }
  },

  async delete(id: number): Promise<void> {
    try {
      await api.delete(`/todos/${id}`);
    } catch (err) {
      console.error("todoApi.delete failed:", err);
      throw err;
    }
  },
};
