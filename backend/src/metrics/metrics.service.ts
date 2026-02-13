import { Injectable, OnModuleInit } from '@nestjs/common';
import {
  Registry,
  collectDefaultMetrics,
  Counter,
  Histogram,
  Gauge,
  Summary,
} from 'prom-client';

@Injectable()
export class MetricsService implements OnModuleInit {
  private readonly registry: Registry;

  // HTTP Metrics
  public readonly httpRequestsTotal: Counter<string>;
  public readonly httpRequestDuration: Histogram<string>;
  public readonly httpRequestSize: Summary<string>;
  public readonly httpResponseSize: Summary<string>;
  public readonly httpActiveRequests: Gauge<string>;

  // Application Metrics
  public readonly todosTotal: Gauge<string>;
  public readonly todosCreated: Counter<string>;
  public readonly todosCompleted: Counter<string>;
  public readonly todosDeleted: Counter<string>;

  // Database Metrics
  public readonly dbQueryDuration: Histogram<string>;
  public readonly dbConnectionsActive: Gauge<string>;
  public readonly dbErrors: Counter<string>;

  // Error Metrics
  public readonly errorsTotal: Counter<string>;
  public readonly unhandledExceptions: Counter<string>;

  // Business Metrics
  public readonly apiLatencyPerEndpoint: Summary<string>;

  constructor() {
    this.registry = new Registry();

    // HTTP Request Counter
    this.httpRequestsTotal = new Counter({
      name: 'http_requests_total',
      help: 'Total number of HTTP requests',
      labelNames: ['method', 'route', 'status_code'],
      registers: [this.registry],
    });

    // HTTP Request Duration Histogram
    this.httpRequestDuration = new Histogram({
      name: 'http_request_duration_seconds',
      help: 'Duration of HTTP requests in seconds',
      labelNames: ['method', 'route', 'status_code'],
      buckets: [0.001, 0.005, 0.015, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 1, 2, 5],
      registers: [this.registry],
    });

    // HTTP Request Size Summary
    this.httpRequestSize = new Summary({
      name: 'http_request_size_bytes',
      help: 'Size of HTTP requests in bytes',
      labelNames: ['method', 'route'],
      percentiles: [0.5, 0.9, 0.95, 0.99],
      registers: [this.registry],
    });

    // HTTP Response Size Summary
    this.httpResponseSize = new Summary({
      name: 'http_response_size_bytes',
      help: 'Size of HTTP responses in bytes',
      labelNames: ['method', 'route'],
      percentiles: [0.5, 0.9, 0.95, 0.99],
      registers: [this.registry],
    });

    // Active HTTP Requests Gauge
    this.httpActiveRequests = new Gauge({
      name: 'http_active_requests',
      help: 'Number of active HTTP requests',
      labelNames: ['method'],
      registers: [this.registry],
    });

    // Todos Total Gauge
    this.todosTotal = new Gauge({
      name: 'todos_total',
      help: 'Total number of todos in the system',
      labelNames: ['status'],
      registers: [this.registry],
    });

    // Todos Created Counter
    this.todosCreated = new Counter({
      name: 'todos_created_total',
      help: 'Total number of todos created',
      registers: [this.registry],
    });

    // Todos Completed Counter
    this.todosCompleted = new Counter({
      name: 'todos_completed_total',
      help: 'Total number of todos marked as completed',
      registers: [this.registry],
    });

    // Todos Deleted Counter
    this.todosDeleted = new Counter({
      name: 'todos_deleted_total',
      help: 'Total number of todos deleted',
      registers: [this.registry],
    });

    // Database Query Duration Histogram
    this.dbQueryDuration = new Histogram({
      name: 'db_query_duration_seconds',
      help: 'Duration of database queries in seconds',
      labelNames: ['operation', 'table'],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1],
      registers: [this.registry],
    });

    // Database Active Connections Gauge
    this.dbConnectionsActive = new Gauge({
      name: 'db_connections_active',
      help: 'Number of active database connections',
      registers: [this.registry],
    });

    // Database Errors Counter
    this.dbErrors = new Counter({
      name: 'db_errors_total',
      help: 'Total number of database errors',
      labelNames: ['operation', 'error_type'],
      registers: [this.registry],
    });

    // Errors Total Counter
    this.errorsTotal = new Counter({
      name: 'errors_total',
      help: 'Total number of errors',
      labelNames: ['type', 'route'],
      registers: [this.registry],
    });

    // Unhandled Exceptions Counter
    this.unhandledExceptions = new Counter({
      name: 'unhandled_exceptions_total',
      help: 'Total number of unhandled exceptions',
      labelNames: ['exception_type'],
      registers: [this.registry],
    });

    // API Latency Per Endpoint Summary
    this.apiLatencyPerEndpoint = new Summary({
      name: 'api_latency_seconds',
      help: 'API latency per endpoint in seconds',
      labelNames: ['method', 'route'],
      percentiles: [0.5, 0.9, 0.95, 0.99],
      maxAgeSeconds: 600,
      ageBuckets: 5,
      registers: [this.registry],
    });
  }

  onModuleInit() {
    // Collect default Node.js metrics (CPU, memory, event loop, etc.)
    collectDefaultMetrics({
      register: this.registry,
      prefix: 'nodejs_',
      gcDurationBuckets: [0.001, 0.01, 0.1, 1, 2, 5],
    });
  }

  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }

  getContentType(): string {
    return this.registry.contentType;
  }

  // Helper method to record HTTP request metrics
  recordHttpRequest(
    method: string,
    route: string,
    statusCode: number,
    duration: number,
    requestSize?: number,
    responseSize?: number,
  ) {
    const labels = { method, route, status_code: statusCode.toString() };

    this.httpRequestsTotal.inc(labels);
    this.httpRequestDuration.observe(labels, duration);

    if (requestSize !== undefined) {
      this.httpRequestSize.observe({ method, route }, requestSize);
    }
    if (responseSize !== undefined) {
      this.httpResponseSize.observe({ method, route }, responseSize);
    }

    this.apiLatencyPerEndpoint.observe({ method, route }, duration);
  }

  // Helper method to record database query metrics
  recordDbQuery(operation: string, table: string, duration: number) {
    this.dbQueryDuration.observe({ operation, table }, duration);
  }

  // Helper method to record database errors
  recordDbError(operation: string, errorType: string) {
    this.dbErrors.inc({ operation, error_type: errorType });
  }

  // Helper method to update todo counts
  updateTodoCounts(active: number, completed: number) {
    this.todosTotal.set({ status: 'active' }, active);
    this.todosTotal.set({ status: 'completed' }, completed);
  }

  // Sync counters with existing database state at startup
  syncCounters(totalCreated: number, totalCompleted: number) {
    // Reset and set counters to match database state
    this.todosCreated.reset();
    this.todosCompleted.reset();
    this.todosCreated.inc(totalCreated);
    this.todosCompleted.inc(totalCompleted);
  }
}
