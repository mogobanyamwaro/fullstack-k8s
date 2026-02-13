import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { TodoModule } from './todo/todo.module';
import { MetricsModule } from './metrics/metrics.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      // In Kubernetes, DATABASE_* are injected by the deployment — skip .env so they are used. Locally, load .env.
      envFilePath: '.env',
      ignoreEnvFile: !!process.env.DATABASE_HOST,
    }),

    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => {
        const host: string =
          configService.get<string>('DATABASE_HOST') ??
          configService.get<string>('DB_HOST', 'localhost');
        const port = parseInt(
          configService.get<string>('DATABASE_PORT') ??
            configService.get<string>('DB_PORT') ??
            '5432',
          10,
        );
        const username: string =
          configService.get<string>('DATABASE_USER') ??
          configService.get<string>('DB_USERNAME', 'todo_user');
        const password: string =
          configService.get<string>('DATABASE_PASSWORD') ??
          configService.get<string>('DB_PASSWORD', 'todo_password');
        const database: string =
          configService.get<string>('DATABASE_NAME') ??
          configService.get<string>('DB_DATABASE', 'todo_db');

        console.log('[DB config]', {
          host,
          port,
          username,
          database,
          password: password ? '***' : '(empty)',
        });

        return {
          type: 'postgres' as const,
          host,
          port,
          username,
          password,
          database,
          autoLoadEntities: true,
          synchronize: configService.get<string>('NODE_ENV') !== 'production',
        };
      },
      inject: [ConfigService],
    }),
    MetricsModule,
    TodoModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
//
