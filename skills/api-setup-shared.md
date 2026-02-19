---
name: api-setup-shared
description: Creates the shared base infrastructure required for hexagonal NestJS modules.
  Scaffolds TypedCommand, TypedQuery, BaseDomainError, BaseFeatureExceptionFilter,
  and the BaseLogger pattern (wrapping nestjs-pino). Run this first when setting up
  a new project or when these classes do not yet exist in {SHARED_ROOT}/.
---

# Skill: api-setup-shared

Creates all shared base classes required by the other `api-*` skills.
Run once per project before using `/api-add-module`, `/api-add-command`, `/api-add-query`, or `/api-add-domain-entity`.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for the `{SHARED_ROOT}` value.
Default: `src/shared`.

---

## Steps

### 1. CQRS base — `{SHARED_ROOT}/cqrs/typed-command.ts`

Phantom-type wrapper that makes `TypedCommand<TResult>` type-safe at the bus level:

```ts
import { ICommand } from "@nestjs/cqrs";

export abstract class TypedCommand<TResult> implements ICommand {
  // Phantom type — carries TResult at compile time, unused at runtime
  readonly _resultType?: TResult;
}
```

### 2. CQRS base — `{SHARED_ROOT}/cqrs/typed-query.ts`

```ts
import { IQuery } from "@nestjs/cqrs";

export abstract class TypedQuery<TResult> implements IQuery<TResult> {
  readonly _resultType?: TResult;
}
```

### 3. Domain error base — `{SHARED_ROOT}/errors/base-domain.error.ts`

```ts
export abstract class BaseDomainError extends Error {
  abstract readonly errorCode: string;
  readonly reportToMonitoring: boolean;
  readonly correlationId?: string;
  readonly metadata?: Record<string, unknown>;
  readonly timestamp = new Date();

  constructor(
    message: string,
    options?: {
      reportToMonitoring?: boolean;
      correlationId?: string;
      metadata?: Record<string, unknown>;
    },
  ) {
    super(message);
    this.name = this.constructor.name;
    this.reportToMonitoring = options?.reportToMonitoring ?? false;
    this.correlationId = options?.correlationId;
    this.metadata = options?.metadata;
  }
}
```

### 4. Exception filter base — `{SHARED_ROOT}/errors/base-feature-exception.filter.ts`

RFC 9457 (Problem Details) response shape:

```ts
import {
  ArgumentsHost,
  ExceptionFilter,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import { HttpAdapterHost } from "@nestjs/core";
import { BaseDomainError } from "./base-domain.error";

export abstract class BaseFeatureExceptionFilter<TError extends BaseDomainError>
  implements ExceptionFilter
{
  private readonly logger = new Logger(BaseFeatureExceptionFilter.name);

  constructor(private readonly httpAdapterHost: HttpAdapterHost) {}

  catch(exception: TError, host: ArgumentsHost): void {
    const { httpAdapter } = this.httpAdapterHost;
    const ctx = host.switchToHttp();

    const status = this.mapErrorToStatus(exception);

    if (exception.reportToMonitoring) {
      this.logger.error(exception.message, exception.stack, {
        errorCode: exception.errorCode,
        correlationId: exception.correlationId,
        metadata: exception.metadata,
      });
    }

    httpAdapter.reply(ctx.getResponse(), {
      type: exception.errorCode,
      title: exception.message,
      status,
      correlationId: exception.correlationId,
      timestamp: exception.timestamp.toISOString(),
    }, status);
  }

  protected abstract mapErrorToStatus(error: TError): number;
}
```

> **Note**: The `HttpAdapterHost` must be injected. Register via `APP_FILTER` in the NestJS module:
> ```ts
> { provide: APP_FILTER, useClass: YourExceptionFilter }
> ```
> NestJS injects `HttpAdapterHost` automatically when using `APP_FILTER`.

### 5. Logger interface — `{SHARED_ROOT}/logger/logger.ts`

```ts
export interface LogParams {
  data?: Record<string, unknown>;
  correlationId?: string;
  functionName?: string;
  entityId?: string;
}

export interface ChildLoggerContext {
  moduleName?: string;
  className?: string;
}

export abstract class BaseLogger {
  abstract log(message: string, params?: LogParams): void;
  abstract warn(message: string, params?: LogParams): void;
  abstract debug(message: string, params?: LogParams): void;
  abstract error(message: string, error: unknown, params?: LogParams): void;
  abstract createChild(context: ChildLoggerContext): BaseLogger;
}
```

### 6. Logger implementation — `{SHARED_ROOT}/logger/pino-logger.ts`

Concrete implementation wrapping `nestjs-pino`:

```ts
import { Injectable } from "@nestjs/common";
import { PinoLogger } from "nestjs-pino";
import { BaseLogger, ChildLoggerContext, LogParams } from "./logger";

@Injectable()
export class AppLogger extends BaseLogger {
  private readonly context: ChildLoggerContext;

  constructor(
    private readonly pinoLogger: PinoLogger,
    context: ChildLoggerContext = {},
  ) {
    super();
    this.context = context;
  }

  log(message: string, params?: LogParams): void {
    this.pinoLogger.info({ ...this.context, ...params }, message);
  }

  warn(message: string, params?: LogParams): void {
    this.pinoLogger.warn({ ...this.context, ...params }, message);
  }

  debug(message: string, params?: LogParams): void {
    this.pinoLogger.debug({ ...this.context, ...params }, message);
  }

  error(message: string, error: unknown, params?: LogParams): void {
    this.pinoLogger.error({ ...this.context, ...params, err: error }, message);
  }

  createChild(context: ChildLoggerContext): BaseLogger {
    return new AppLogger(this.pinoLogger, { ...this.context, ...context });
  }
}
```

### 7. Logger decorator — `{SHARED_ROOT}/logger/inject-logger.decorator.ts`

```ts
import { Inject } from "@nestjs/common";

export const LOGGER_TOKEN = Symbol("LOGGER_TOKEN");

export const InjectLogger = (): ParameterDecorator => Inject(LOGGER_TOKEN);
```

### 8. In-memory logger (tests) — `{SHARED_ROOT}/logger/in-memory-logger.ts`

```ts
import { BaseLogger, ChildLoggerContext, LogParams } from "./logger";

export interface CapturedLog {
  level: "log" | "warn" | "debug" | "error";
  message: string;
  params?: LogParams;
  error?: unknown;
}

export class InMemoryLogger extends BaseLogger {
  private readonly logs: CapturedLog[] = [];

  log(message: string, params?: LogParams): void {
    this.logs.push({ level: "log", message, params });
  }

  warn(message: string, params?: LogParams): void {
    this.logs.push({ level: "warn", message, params });
  }

  debug(message: string, params?: LogParams): void {
    this.logs.push({ level: "debug", message, params });
  }

  error(message: string, error: unknown, params?: LogParams): void {
    this.logs.push({ level: "error", message, error, params });
  }

  createChild(_context: ChildLoggerContext): BaseLogger {
    return this; // same instance — all logs captured in one place
  }

  getLogMessages(): string[] {
    return this.logs.map((l) => l.message);
  }

  hasLoggedMessage(message: string): boolean {
    return this.logs.some((l) => l.message.includes(message));
  }

  clear(): void {
    this.logs.length = 0;
  }
}
```

### 9. Logger module — `{SHARED_ROOT}/logger/app-logger.module.ts`

```ts
import { Global, Module } from "@nestjs/common";
import { LoggerModule } from "nestjs-pino";
import { AppLogger } from "./pino-logger";
import { LOGGER_TOKEN } from "./inject-logger.decorator";

@Global()
@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.LOG_LEVEL ?? "info",
        transport:
          process.env.NODE_ENV !== "production"
            ? { target: "pino-pretty" }
            : undefined,
      },
    }),
  ],
  providers: [
    AppLogger,
    {
      provide: LOGGER_TOKEN,
      useClass: AppLogger,
    },
  ],
  exports: [LOGGER_TOKEN],
})
export class AppLoggerModule {}
```

Import `AppLoggerModule` in the application root module.

### 10. Barrel exports — `{SHARED_ROOT}/cqrs/index.ts`, `{SHARED_ROOT}/errors/index.ts`, `{SHARED_ROOT}/logger/index.ts`

```ts
// cqrs/index.ts
export * from "./typed-command";
export * from "./typed-query";

// errors/index.ts
export * from "./base-domain.error";
export * from "./base-feature-exception.filter";

// logger/index.ts
export * from "./logger";
export * from "./inject-logger.decorator";
export * from "./in-memory-logger";
```

---

## Limitations

- `AppLoggerModule` uses `nestjs-pino` — install `nestjs-pino` and `pino-http` if not already present.
- For non-pino loggers, replace `AppLogger` with your own `BaseLogger` implementation; the interface contract remains the same.
- `BaseFeatureExceptionFilter` uses `HttpAdapterHost` — ensure it is available in the NestJS DI context (it is by default when registered via `APP_FILTER`).
