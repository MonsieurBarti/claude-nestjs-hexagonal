# LoggingInterceptor

File: `{SHARED_ROOT}/interceptors/logging.interceptor.ts`

Logs every incoming HTTP request (method, URL, body, query, params) when `IS_LOCAL` is `false`.
Uses `BaseLogger` + `@InjectLogger()` — consistent with the project logger pattern.
Register as `APP_INTERCEPTOR` in `AppModule`.

Note: body is logged as-is — add field-level redaction in the app if needed.

```ts
import {
  Injectable,
  type NestInterceptor,
  type ExecutionContext,
  type CallHandler,
} from "@nestjs/common";
import type { Observable } from "rxjs";
import type { FastifyRequest } from "fastify";
import { ConfigService } from "@nestjs/config";
import type { EnvVars } from "../../config/env";
import { BaseLogger } from "../logger/logger";
import { InjectLogger } from "../logger/inject-logger.decorator";

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger: BaseLogger;

  constructor(
    @InjectLogger() logger: BaseLogger,
    private readonly configService: ConfigService<EnvVars, true>,
  ) {
    this.logger = logger.createChild({
      moduleName: "http",
      className: LoggingInterceptor.name,
    });
  }

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<FastifyRequest>();
    const { method, url, body, query, params } = request;
    const userAgent = request.headers["user-agent"] ?? "";
    const isLocal = this.configService.get("IS_LOCAL", { infer: true });

    if (body && !isLocal) {
      this.logger.log(`${method} ${url} received`, {
        data: { body, query, params, userAgent },
      });
    }

    return next.handle();
  }
}
```

Add to barrel `{SHARED_ROOT}/interceptors/index.ts`:

```ts
export * from "./logging.interceptor";
```
