# CorrelationId decorator

File: `{SHARED_ROOT}/decorators/correlation-id.decorator.ts`

Fastify-native `@Param`-style decorator. Reads the correlation ID from (in priority order):
1. `request.raw.correlationId` — set by middleware
2. `x-correlation-id` request header
3. A freshly generated `randomUUID()` as fallback

```ts
import { createParamDecorator, ExecutionContext } from "@nestjs/common";
import { FastifyRequest } from "fastify";
import { randomUUID } from "node:crypto";

export const CorrelationId = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): string => {
    const request = ctx.switchToHttp().getRequest<FastifyRequest>();
    const raw = request.raw as typeof request.raw & { correlationId?: string };
    return (
      raw.correlationId ??
      (request.headers["x-correlation-id"] as string) ??
      randomUUID()
    );
  },
);
```

> Export from `{SHARED_ROOT}/decorators/index.ts`:
> ```ts
> export * from "./correlation-id.decorator";
> ```

> Use in controllers:
> ```ts
> async create(
>   @Body() body: CreateXxxBodyDto,
>   @CorrelationId() correlationId: string,
> ): Promise<void> { ... }
> ```
