# Logger stack

All files live in `{SHARED_ROOT}/logger/`.

## logger.ts — abstract interface

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

## pino-logger.ts — concrete implementation

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

## inject-logger.decorator.ts

```ts
import { Inject } from "@nestjs/common";

export const LOGGER_TOKEN = Symbol("LOGGER_TOKEN");

export const InjectLogger = (): ParameterDecorator => Inject(LOGGER_TOKEN);
```

## in-memory-logger.ts — test double

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

## app-logger.module.ts — global NestJS module

```ts
import { Global, Module } from "@nestjs/common";
import { LoggerModule, PinoLogger } from "nestjs-pino";
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
    {
      provide: LOGGER_TOKEN,
      useFactory: (pinoLogger: PinoLogger) => new AppLogger(pinoLogger),
      inject: [PinoLogger],
    },
  ],
  exports: [LOGGER_TOKEN],
})
export class AppLoggerModule {}
```

Import `AppLoggerModule` in the application root module.

## Barrel — logger/index.ts

```ts
export * from "./logger";
export * from "./inject-logger.decorator";
export * from "./in-memory-logger";
```
