# BaseFeatureExceptionFilter

File: `{SHARED_ROOT}/errors/base-feature-exception.filter.ts`

RFC 9457 (Problem Details) response shape, Fastify-native, using `BaseLogger`.

```ts
import { ArgumentsHost } from "@nestjs/common";
import { BaseExceptionFilter } from "@nestjs/core";
import { ApiProperty } from "@nestjs/swagger";
import { FastifyReply, FastifyRequest } from "fastify";
import { randomUUID } from "node:crypto";
import { BaseDomainError } from "./base-domain.error";
import { InjectLogger } from "../logger/inject-logger.decorator";
import { BaseLogger } from "../logger/logger";

export class ErrorResponseDto {
  @ApiProperty({ example: "USER_NOT_FOUND", description: "Machine-readable error code (SCREAMING_SNAKE_CASE)" })
  type!: string;

  @ApiProperty({ example: "UserNotFoundError", description: "Error class name" })
  title!: string;

  @ApiProperty({ example: 404 })
  status!: number;

  @ApiProperty({ example: "User with id abc123 was not found" })
  detail!: string;

  @ApiProperty({ example: "/v1/users/abc123", description: "Request URL" })
  instance!: string;

  @ApiProperty({ example: "550e8400-e29b-41d4-a716-446655440000" })
  correlationId!: string;

  @ApiProperty({ example: "2024-01-15T10:30:00.000Z", description: "ISO 8601 timestamp" })
  timestamp!: string;

  @ApiProperty({ required: false, nullable: true, description: "Additional error context" })
  metadata?: Record<string, unknown>;
}

export abstract class BaseFeatureExceptionFilter<
  TError extends BaseDomainError,
> extends BaseExceptionFilter {
  protected readonly logger: BaseLogger;

  constructor(@InjectLogger() logger: BaseLogger) {
    super();
    this.logger = logger.createChild({
      moduleName: "exception-filter",
      className: this.constructor.name,
    });
  }

  override async catch(error: TError, host: ArgumentsHost): Promise<void> {
    const ctx = host.switchToHttp();
    const request = ctx.getRequest<FastifyRequest>();
    const response = ctx.getResponse<FastifyReply>();

    const correlationId = error.correlationId ?? this.extractCorrelationId(request);

    this.logger.error(`${error.errorCode} | ${error.message}`, error, {
      correlationId,
      data: error.metadata,
    });

    const statusCode = this.mapErrorToStatus(error);

    await response
      .status(statusCode)
      .send(this.buildErrorResponse(error, request, statusCode, correlationId));
  }

  /**
   * Maps a domain error to an HTTP status code.
   * Check system errors (5xx) FIRST, then user errors (4xx).
   * Fall through to INTERNAL_SERVER_ERROR as a safety net — it signals a missing mapping.
   *
   * @example
   * protected mapErrorToStatus(error: OrderError): number {
   *   if (error instanceof OrderNotFoundError) return HttpStatus.NOT_FOUND;
   *   if (error instanceof OrderAlreadyCancelledError) return HttpStatus.CONFLICT;
   *   return HttpStatus.INTERNAL_SERVER_ERROR; // missing mapping — fix it
   * }
   */
  protected abstract mapErrorToStatus(error: TError): number;

  private buildErrorResponse(
    error: TError,
    request: FastifyRequest,
    statusCode: number,
    correlationId: string,
  ): ErrorResponseDto {
    return {
      type: error.errorCode,
      title: error.name,
      status: statusCode,
      detail: error.message,
      instance: request.url,
      correlationId,
      timestamp: new Date().toISOString(),
      metadata: error.metadata,
    };
  }

  private extractCorrelationId(request: FastifyRequest): string {
    const raw = request.raw as typeof request.raw & { correlationId?: string };
    return (
      raw.correlationId ??
      (request.headers["correlationid"] as string) ??
      randomUUID()
    );
  }
}
```

> Register via `APP_FILTER` — NestJS injects `BaseLogger` automatically via `AppLoggerModule`:
> ```ts
> { provide: APP_FILTER, useClass: YourModuleExceptionFilter }
> ```
>
> No `HttpAdapterHost` needed — Fastify request/response are accessed directly.
