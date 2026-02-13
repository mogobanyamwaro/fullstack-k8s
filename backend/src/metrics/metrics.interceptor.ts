import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { Response } from 'express';
import { MetricsService } from './metrics.service';

interface HttpRequest {
  method: string;
  path: string;
  route?: { path?: string };
  headers: Record<string, string | string[] | undefined>;
}

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(private readonly metricsService: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const ctx = context.switchToHttp();
    const request = ctx.getRequest<HttpRequest>();
    const response = ctx.getResponse<Response>();

    const method = request.method;
    const route: string = request.route?.path ?? request.path;

    // Skip metrics endpoint to avoid recursion
    if (route === '/metrics') {
      return next.handle();
    }

    // Increment active requests
    this.metricsService.httpActiveRequests.inc({ method });

    const startTime = process.hrtime.bigint();
    const contentLength = request.headers['content-length'];
    const requestSize = parseInt(
      Array.isArray(contentLength) ? contentLength[0] : (contentLength ?? '0'),
      10,
    );

    return next.handle().pipe(
      tap({
        next: () => {
          this.recordMetrics(
            method,
            route,
            response.statusCode,
            startTime,
            requestSize,
          );
        },
        error: () => {
          this.recordMetrics(
            method,
            route,
            response.statusCode || 500,
            startTime,
            requestSize,
          );
          this.metricsService.errorsTotal.inc({
            type: 'http_error',
            route: route,
          });
        },
        finalize: () => {
          // Decrement active requests
          this.metricsService.httpActiveRequests.dec({ method });
        },
      }),
    );
  }

  private recordMetrics(
    method: string,
    route: string,
    statusCode: number,
    startTime: bigint,
    requestSize: number,
  ) {
    const endTime = process.hrtime.bigint();
    const duration = Number(endTime - startTime) / 1e9; // Convert to seconds

    this.metricsService.recordHttpRequest(
      method,
      route,
      statusCode,
      duration,
      requestSize,
    );
  }
}
