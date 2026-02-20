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
import { buildLocalPayload, shouldLog } from "./local-log-formatter";

@Injectable()
export class AppLogger extends BaseLogger {
  private readonly context: ChildLoggerContext;
  private readonly isLocal: boolean;

  constructor(
    private readonly pinoLogger: PinoLogger,
    isLocal: boolean = false,
    context: ChildLoggerContext = {},
  ) {
    super();
    this.isLocal = isLocal;
    this.context = context;
  }

  log(message: string, params?: LogParams): void {
    if (!shouldLog(this.context, this.isLocal)) return;
    if (this.isLocal) {
      this.pinoLogger.info(buildLocalPayload(message, this.context, params));
    } else {
      this.pinoLogger.info({ ...this.context, ...params }, message);
    }
  }

  warn(message: string, params?: LogParams): void {
    if (!shouldLog(this.context, this.isLocal)) return;
    if (this.isLocal) {
      this.pinoLogger.warn(buildLocalPayload(message, this.context, params));
    } else {
      this.pinoLogger.warn({ ...this.context, ...params }, message);
    }
  }

  debug(message: string, params?: LogParams): void {
    if (!shouldLog(this.context, this.isLocal)) return;
    if (this.isLocal) {
      this.pinoLogger.debug(buildLocalPayload(message, this.context, params));
    } else {
      this.pinoLogger.debug({ ...this.context, ...params }, message);
    }
  }

  error(message: string, error: unknown, params?: LogParams): void {
    if (!shouldLog(this.context, this.isLocal)) return;
    if (this.isLocal) {
      this.pinoLogger.error(buildLocalPayload(message, this.context, params, error));
    } else {
      this.pinoLogger.error({ ...this.context, ...params, err: error }, message);
    }
  }

  createChild(context: ChildLoggerContext): BaseLogger {
    return new AppLogger(this.pinoLogger, this.isLocal, {
      ...this.context,
      ...context,
    });
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

## local-logger.config.ts — local dev filter (gitignored)

**Important**: add `src/shared/logger/local-logger.config.ts` to `.gitignore` — this file is edited
per session and must never be committed.

```ts
/**
 * Local development only — has NO effect in production.
 * This file is .gitignore'd: edit freely without fear of committing personal settings.
 */
export const LocalLoggerConfig = {
  /**
   * Allowlist: only log these moduleName values. Empty = log all.
   * Takes precedence over disabledModules.
   * Example: ["catalog", "auth"]
   */
  enabledModules: [] as string[],

  /**
   * Blocklist: skip these moduleName values. Ignored if enabledModules is non-empty.
   * Example: ["cqrs", "prisma"]
   */
  disabledModules: [] as string[],

  /**
   * ANSI color name per moduleName for visual scanning.
   * Available: red, green, yellow, blue, magenta, cyan, white, gray
   * Example: { catalog: "cyan", auth: "magenta" }
   */
  moduleColors: {} as Record<string, string>,

  /** true → log full request (headers, body, query) | false → only "METHOD /url" */
  showFullRequest: false,

  /** Include the `data` field from LogParams in local log output. */
  showDataField: true,

  /** Include error object details in error-level log output. */
  showErrors: true,
};
```

## local-log-formatter.ts — ANSI formatting helper

Keeps local-mode ANSI logic out of `AppLogger`. No external dependencies — uses Node built-in escape codes.

```ts
import type { ChildLoggerContext, LogParams } from "./logger";
import { LocalLoggerConfig } from "./local-logger.config";

const ANSI: Record<string, string> = {
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
  white: "\x1b[37m",
  gray: "\x1b[90m",
  reset: "\x1b[0m",
};

function colorize(text: string, color: string): string {
  return `${ANSI[color] ?? ANSI["white"]}${text}${ANSI["reset"]}`;
}

export function shouldLog(context: ChildLoggerContext, isLocal: boolean): boolean {
  if (!isLocal) return true;
  const mod = context.moduleName;
  if (!mod) return true;
  if (LocalLoggerConfig.enabledModules.length > 0) {
    return LocalLoggerConfig.enabledModules.includes(mod);
  }
  if (LocalLoggerConfig.disabledModules.length > 0) {
    return !LocalLoggerConfig.disabledModules.includes(mod);
  }
  return true;
}

export function buildLocalPayload(
  message: string,
  context: ChildLoggerContext,
  params?: LogParams,
  error?: unknown,
): Record<string, unknown> {
  const parts: string[] = [];

  if (context.moduleName) {
    const color = LocalLoggerConfig.moduleColors[context.moduleName] ?? "white";
    parts.push(colorize(`[${context.moduleName}]`, color));
  }
  if (context.className) {
    parts.push(colorize(context.className, "gray"));
  }

  const prefix = parts.length > 0 ? `${parts.join(" ")} | ` : "";
  const payload: Record<string, unknown> = { msg: `${prefix}${message}` };

  if (LocalLoggerConfig.showDataField && params?.data) {
    payload["data"] = params.data;
  }
  if (LocalLoggerConfig.showErrors && error != null) {
    payload["error"] = error;
  }

  return payload;
}
```

## request-serializer.ts — pino request serializer

Replaces pino's default `req` serializer. Condenses output when `IS_LOCAL=true`.
Note: body is logged as-is — add field redaction in the app layer if needed.

```ts
import { LocalLoggerConfig } from "./local-logger.config";

interface SerializedRequest {
  method: string;
  url: string;
  headers?: Record<string, unknown>;
  body?: unknown;
  query?: Record<string, unknown>;
  params?: Record<string, unknown>;
  remoteAddress?: string;
  userAgent?: string;
}

export const requestSerializer = (req: Record<string, unknown>): SerializedRequest => {
  const isLocal = process.env["IS_LOCAL"] === "true";

  if (isLocal && !LocalLoggerConfig.showFullRequest) {
    return {
      method: req["method"] as string,
      url: req["url"] as string,
    };
  }

  const headers = req["headers"] as Record<string, unknown> | undefined;

  return {
    method: req["method"] as string,
    url: req["url"] as string,
    headers,
    body: req["body"],
    query: req["query"] as Record<string, unknown> | undefined,
    params: req["params"] as Record<string, unknown> | undefined,
    remoteAddress: (req["ip"] ?? req["remoteAddress"]) as string | undefined,
    userAgent: headers?.["user-agent"] as string | undefined,
  };
};
```

## logger.config.ts — pino config factory

```ts
import pino from "pino";
import type { Params } from "nestjs-pino";
import type { ConfigService } from "@nestjs/config";
import type { EnvVars } from "../../config/env";
import { requestSerializer } from "./request-serializer";

const responseSerializer = pino.stdSerializers.res;

export const getLoggerConfig = (configService: ConfigService<EnvVars, true>): Params => {
  const isLocal = configService.get("IS_LOCAL", { infer: true });

  return {
    pinoHttp: {
      serializers: {
        err: pino.stdSerializers.err,
        req: requestSerializer,   // ← replaces pino.stdSerializers.req
        res: responseSerializer,
      },
      autoLogging: false,
      wrapSerializers: true,
      level: isLocal ? "debug" : "info",
      transport: isLocal
        ? {
            target: "pino-pretty",
            options: {
              colorize: true,
              colorizeObjects: false,
              singleLine: true,
              translateTime: "SYS:HH:MM:ss",
              messageFormat: "{msg}",
            },
          }
        : undefined,
      customLogLevel: (_req, res, err) => {
        if (isLocal) return "silent";
        if (res.statusCode >= 400 && res.statusCode < 500) return "warn";
        else if (res.statusCode >= 500 || err) return "error";
        else if (res.statusCode >= 300 && res.statusCode < 400) return "silent";
        return "info";
      },
      customSuccessMessage: (req, res) => {
        if (res.statusCode === 404) return "resource not found";
        return `${req.method} completed`;
      },
      customReceivedMessage: (_req, _res) => "request received",
      customErrorMessage: (_req, _res, _err) =>
        `request errored with status code: ${_res.statusCode}`,
      customAttributeKeys: {
        req: "request",
        res: "response",
        err: "error",
        responseTime: "timeTaken",
      },
    },
  };
};
```

## app-logger.module.ts — global NestJS module

Uses `LoggerModule.forRootAsync` so pino config can read from `ConfigService` (requires `ConfigModule.forRoot` in `AppModule`).

```ts
import { Global, Module } from "@nestjs/common";
import { LoggerModule, PinoLogger } from "nestjs-pino";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { AppLogger } from "./pino-logger";
import { LOGGER_TOKEN } from "./inject-logger.decorator";
import { getLoggerConfig } from "./logger.config";
import type { EnvVars } from "../../config/env";

@Global()
@Module({
  imports: [
    LoggerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService<EnvVars, true>) =>
        getLoggerConfig(configService),
    }),
  ],
  providers: [
    {
      provide: LOGGER_TOKEN,
      useFactory: (pinoLogger: PinoLogger, configService: ConfigService<EnvVars, true>) =>
        new AppLogger(pinoLogger, configService.get("IS_LOCAL", { infer: true })),
      inject: [PinoLogger, ConfigService],
    },
  ],
  exports: [LOGGER_TOKEN],
})
export class AppLoggerModule {}
```

Import `AppLoggerModule` in the application root module **after** `ConfigModule.forRoot`.

## test-logger.module.ts — shared test helper

File: `{SHARED_ROOT}/testing/test-logger.module.ts`

Provides `LOGGER_TOKEN` globally for integration tests without booting the full `AppLoggerModule` + pino stack.

```ts
import { Global, Module } from "@nestjs/common";
import { LOGGER_TOKEN } from "../logger/inject-logger.decorator";
import { InMemoryLogger } from "../logger/in-memory-logger";

@Global()
@Module({
  providers: [{ provide: LOGGER_TOKEN, useValue: new InMemoryLogger() }],
  exports: [LOGGER_TOKEN],
})
export class TestLoggerModule {}
```

Import it before the feature module in every integration test:
```ts
imports: [TestLoggerModule, XxxModule]
```

## Barrel — logger/index.ts

```ts
export * from "./logger";
export * from "./inject-logger.decorator";
export * from "./in-memory-logger";
export * from "./local-logger.config";
export * from "./local-log-formatter";
export * from "./request-serializer";
```
