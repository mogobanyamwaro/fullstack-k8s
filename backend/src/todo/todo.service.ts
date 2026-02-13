import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Todo } from './entities/todo.entity';
import { CreateTodoDto } from './dto/create-todo.dto';
import { UpdateTodoDto } from './dto/update-todo.dto';
import { MetricsService } from '../metrics/metrics.service';

@Injectable()
export class TodoService implements OnModuleInit {
  constructor(
    @InjectRepository(Todo)
    private readonly todoRepository: Repository<Todo>,
    private readonly metricsService: MetricsService,
  ) {}

  async onModuleInit() {
    await this.syncMetricsWithDatabase();
  }

  private async syncMetricsWithDatabase() {
    const [active, completed, total] = await Promise.all([
      this.todoRepository.count({ where: { completed: false } }),
      this.todoRepository.count({ where: { completed: true } }),
      this.todoRepository.count(),
    ]);
    this.metricsService.updateTodoCounts(active, completed);
    // Sync counters with existing data
    this.metricsService.syncCounters(total, completed);
  }

  private async updateTodoMetrics() {
    const [active, completed] = await Promise.all([
      this.todoRepository.count({ where: { completed: false } }),
      this.todoRepository.count({ where: { completed: true } }),
    ]);
    this.metricsService.updateTodoCounts(active, completed);
  }

  async create(createTodoDto: CreateTodoDto): Promise<Todo> {
    const startTime = process.hrtime.bigint();
    try {
      const todo = this.todoRepository.create(createTodoDto);
      const result = await this.todoRepository.save(todo);

      // Record metrics
      const duration = Number(process.hrtime.bigint() - startTime) / 1e9;
      this.metricsService.recordDbQuery('insert', 'todos', duration);
      this.metricsService.todosCreated.inc();
      await this.updateTodoMetrics();

      return result;
    } catch (error) {
      this.metricsService.recordDbError('insert', this.getErrorName(error));
      throw error;
    }
  }

  async findAll(): Promise<Todo[]> {
    const startTime = process.hrtime.bigint();
    try {
      const result = await this.todoRepository.find({
        order: { createdAt: 'DESC' },
      });

      const duration = Number(process.hrtime.bigint() - startTime) / 1e9;
      this.metricsService.recordDbQuery('select', 'todos', duration);

      return result;
    } catch (error) {
      this.metricsService.recordDbError('select', this.getErrorName(error));
      throw error;
    }
  }

  async findOne(id: number): Promise<Todo> {
    const startTime = process.hrtime.bigint();
    try {
      const todo = await this.todoRepository.findOne({ where: { id } });

      const duration = Number(process.hrtime.bigint() - startTime) / 1e9;
      this.metricsService.recordDbQuery('select', 'todos', duration);

      if (!todo) {
        throw new NotFoundException(`Todo with ID ${id} not found`);
      }
      return todo;
    } catch (error) {
      if (!(error instanceof NotFoundException)) {
        this.metricsService.recordDbError('select', this.getErrorName(error));
      }
      throw error;
    }
  }

  async update(id: number, updateTodoDto: UpdateTodoDto): Promise<Todo> {
    const startTime = process.hrtime.bigint();
    try {
      const todo = await this.findOne(id);
      const wasCompleted = todo.completed;
      Object.assign(todo, updateTodoDto);
      const result = await this.todoRepository.save(todo);

      const duration = Number(process.hrtime.bigint() - startTime) / 1e9;
      this.metricsService.recordDbQuery('update', 'todos', duration);

      // Track completion metrics if status changed
      if (!wasCompleted && result.completed) {
        this.metricsService.todosCompleted.inc();
      }
      await this.updateTodoMetrics();

      return result;
    } catch (error) {
      if (!(error instanceof NotFoundException)) {
        this.metricsService.recordDbError('update', this.getErrorName(error));
      }
      throw error;
    }
  }

  async remove(id: number): Promise<void> {
    const startTime = process.hrtime.bigint();
    try {
      const todo = await this.findOne(id);
      await this.todoRepository.remove(todo);

      const duration = Number(process.hrtime.bigint() - startTime) / 1e9;
      this.metricsService.recordDbQuery('delete', 'todos', duration);
      this.metricsService.todosDeleted.inc();
      await this.updateTodoMetrics();
    } catch (error) {
      if (!(error instanceof NotFoundException)) {
        this.metricsService.recordDbError('delete', this.getErrorName(error));
      }
      throw error;
    }
  }

  async toggleComplete(id: number): Promise<Todo> {
    const startTime = process.hrtime.bigint();
    try {
      const todo = await this.findOne(id);
      const wasCompleted = todo.completed;
      todo.completed = !todo.completed;
      const result = await this.todoRepository.save(todo);

      const duration = Number(process.hrtime.bigint() - startTime) / 1e9;
      this.metricsService.recordDbQuery('update', 'todos', duration);

      // Track completion metrics
      if (!wasCompleted && todo.completed) {
        this.metricsService.todosCompleted.inc();
      }
      await this.updateTodoMetrics();

      return result;
    } catch (error) {
      if (!(error instanceof NotFoundException)) {
        this.metricsService.recordDbError('update', this.getErrorName(error));
      }
      throw error;
    }
  }

  private getErrorName(error: unknown): string {
    if (error instanceof Error) {
      return error.constructor.name;
    }
    return 'UnknownError';
  }
}
