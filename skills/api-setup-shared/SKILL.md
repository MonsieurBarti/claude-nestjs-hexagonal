---
name: api-setup-shared
description: Creates all shared infrastructure required for hexagonal NestJS modules —
  TypedCommand, TypedQuery, TypedCommandBus, TypedQueryBus, CorrelationId decorator,
  PaginatedQueryBase, BaseDomainError, BaseFeatureExceptionFilter,
  the BaseLogger pattern (wrapping nestjs-pino), ZodValidationPipe with @ZodSchema decorator,
  PrismaService + PrismaModule (global), validateEnv helper, CqrsInterceptor (bus observer),
  LoggingInterceptor (HTTP request logger), DomainEvent base class, SqlRepositoryBase
  (generic Prisma CRUD + auto event publishing), and IDateProvider + DateProvider + FakeDateProvider
  (date abstraction for deterministic testing). Run once per project before using other api-* skills.
---

# api-setup-shared

Creates everything in `{SHARED_ROOT}/` required by the other `api-*` skills.
Run once — after `/api-init-project` and before `/api-add-module`.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for the `{SHARED_ROOT}` value (default: `src/shared`).

## Steps

1. **TypedCommand** — `{SHARED_ROOT}/cqrs/typed-command.ts`
   Load [references/typed-command.md](references/typed-command.md).

2. **TypedQuery + PaginatedQueryBase** — `{SHARED_ROOT}/cqrs/typed-query.ts` and `{SHARED_ROOT}/cqrs/paginated-query.base.ts`
   Load [references/typed-query.md](references/typed-query.md).
   Creates `TypedQuery`, `PaginatedQueryBase`, `PaginatedParams`, `PaginatedResult`, and updates the barrel (see Step 1).

3. **BaseDomainError** — `{SHARED_ROOT}/errors/base-domain.error.ts`
   Load [references/base-domain-error.md](references/base-domain-error.md).

4. **BaseFeatureExceptionFilter** — `{SHARED_ROOT}/errors/base-feature-exception.filter.ts`
   Load [references/base-feature-exception-filter.md](references/base-feature-exception-filter.md).

5. **Logger stack** (9 files + module + test helper) — `{SHARED_ROOT}/logger/` and `{SHARED_ROOT}/testing/`
   Load [references/logger.md](references/logger.md) for all logger files.
   This includes: `logger.ts`, `pino-logger.ts`, `inject-logger.decorator.ts`, `in-memory-logger.ts`, `logger.config.ts`, `app-logger.module.ts`.
   Also create:
   - `{SHARED_ROOT}/logger/local-logger.config.ts` — per-session module filter config (see logger.md)
   - `{SHARED_ROOT}/logger/local-log-formatter.ts` — ANSI formatting helper for local mode (see logger.md)
   - `{SHARED_ROOT}/logger/request-serializer.ts` — pino request serializer (see logger.md)
   - `{SHARED_ROOT}/testing/test-logger.module.ts` — shared `@Global()` test module (see logger.md)

   Add `src/shared/logger/local-logger.config.ts` to `.gitignore` so personal module filter
   preferences are never accidentally committed.

6. **Zod validation** (pipe + exception + decorator) — `{SHARED_ROOT}/pipes/` and `{SHARED_ROOT}/decorators/`
   Load [references/zod-validation-pipe.md](references/zod-validation-pipe.md).
   Creates 5 files with barrel exports.

7. **Env validation helper** — `{SHARED_ROOT}/config/validate-env.ts`
   Load [references/validate-env.md](references/validate-env.md).

8. **PrismaService + PrismaModule** — `{SHARED_ROOT}/prisma/prisma.service.ts` and `{SHARED_ROOT}/prisma/prisma.module.ts`
   Load [references/prisma.md](references/prisma.md).

8b. **DomainEvent base class** — `{SHARED_ROOT}/ddd/domain-event.base.ts` + `{SHARED_ROOT}/ddd/index.ts`
    Load [references/domain-event.md](references/domain-event.md).
    Creates the abstract `DomainEvent` class implementing `IEvent` from `@nestjs/cqrs`,
    with `DomainEventMetadata` (correlationId, timestamp, userId) and `DomainEventProps<T>` type.

8c. **SqlRepositoryBase** — `{SHARED_ROOT}/db/sql-repository.base.ts`
    Load [references/sql-repository-base.md](references/sql-repository-base.md).
    Abstract Prisma-based repository providing generic `save()`, `findById()`, `delete()`
    with automatic domain event publishing via `EventBus`. Entities must extend `AggregateRoot`.
    Also exports the `EntityMapper<Entity, DbRecord>` interface used by mappers.

8d. **DateProvider** — `{SHARED_ROOT}/date/date-provider.ts`, `{SHARED_ROOT}/date/date-provider.impl.ts`, `{SHARED_ROOT}/testing/fake-date-provider.ts`
    Load [references/date-provider.md](references/date-provider.md).
    Creates `IDateProvider` abstract class (doubles as DI token), `DateProvider` real implementation,
    `FakeDateProvider` test fake, and `{SHARED_ROOT}/date/index.ts` barrel.

9. **TypedCommandBus** — `{SHARED_ROOT}/cqrs/typed-command-bus.ts`
   Load [references/typed-command-bus.md](references/typed-command-bus.md).

10. **TypedQueryBus** — `{SHARED_ROOT}/cqrs/typed-query-bus.ts`
    Load [references/typed-query-bus.md](references/typed-query-bus.md).

11. **CorrelationId decorator** — `{SHARED_ROOT}/decorators/correlation-id.decorator.ts`
    Load [references/correlation-id-decorator.md](references/correlation-id-decorator.md).
    Also add to the decorators barrel (`{SHARED_ROOT}/decorators/index.ts`):
    ```ts
    export * from "./correlation-id.decorator";
    ```

12. **Barrel exports** — `{SHARED_ROOT}/cqrs/index.ts`, `errors/index.ts`, `logger/index.ts`
    Included in the respective reference files (steps 1–5).
    Steps 6 and 7 include their own barrel exports.
    The `cqrs/index.ts` barrel must also export `TypedCommandBus` and `TypedQueryBus` (steps 9–10).

13. **CqrsInterceptor** — `{SHARED_ROOT}/interceptors/cqrs.interceptor.ts`
    Load [references/cqrs-interceptor.md](references/cqrs-interceptor.md).
    Subscribes to `CommandBus`, `QueryBus`, `EventBus` on module init — logs every
    command/query/event with the class name and full payload via `BaseLogger`.

14. **LoggingInterceptor** — `{SHARED_ROOT}/interceptors/logging.interceptor.ts`
    Load [references/logging-interceptor.md](references/logging-interceptor.md).
    Logs incoming HTTP requests (method, URL, body, query, params) when `IS_LOCAL=false`.
    Add both exports to `{SHARED_ROOT}/interceptors/index.ts` (see reference file).

15. **Update `src/app.module.ts`**
    Add `AppLoggerModule`, `PrismaModule` to `imports`, and the interceptors + `DateProvider` to `providers`:
    ```ts
    import { APP_INTERCEPTOR } from "@nestjs/core";
    import { AppLoggerModule } from "./shared/logger/app-logger.module";
    import { PrismaModule } from "./shared/prisma/prisma.module";
    import { CqrsInterceptor } from "./shared/interceptors/cqrs.interceptor";
    import { LoggingInterceptor } from "./shared/interceptors/logging.interceptor";
    import { IDateProvider } from "./shared/date/date-provider";
    import { DateProvider } from "./shared/date/date-provider.impl";

    @Module({
      imports: [
        ConfigModule.forRoot({ isGlobal: true, cache: true, validate: validateEnvironment }),
        AppLoggerModule,
        PrismaModule,
      ],
      providers: [
        CqrsInterceptor,
        { provide: APP_INTERCEPTOR, useClass: LoggingInterceptor },
        { provide: IDateProvider, useClass: DateProvider },
      ],
    })
    export class AppModule {}
    ```
    Note: `CqrsInterceptor` is a plain provider (not `APP_INTERCEPTOR`) — it subscribes to
    CQRS observables, not the HTTP pipeline.

16. **Update `src/main.ts`**
    Add the ZodValidationPipe and env validation imports — the project will now compile:
    ```ts
    import { ZodValidationPipe } from "./shared/pipes/zod-validation.pipe";
    import "./config/env"; // add this line near the top

    // inside bootstrap():
    app.useGlobalPipes(new ZodValidationPipe());
    app.enableShutdownHooks(); // allows Prisma to disconnect cleanly
    ```

## Limitations

- `AppLoggerModule` requires `nestjs-pino`, `pino-http`, and `@nestjs/config` — installed by `/api-init-project`.
- `getLoggerConfig` uses `ConfigService<EnvVars, true>` — requires `ConfigModule.forRoot({ isGlobal: true, cache: true, validate: validateEnvironment })` in `AppModule` (added by step 13).
- `TestLoggerModule` (in `{SHARED_ROOT}/testing/`) bypasses pino entirely — safe for integration tests without ConfigModule.
- For non-pino loggers, replace `AppLogger` with a custom `BaseLogger` implementation.
- `BaseFeatureExceptionFilter` uses Fastify types (`FastifyRequest`, `FastifyReply`) — requires `@nestjs/platform-fastify`.
- `validateEnv` is a helper only — the project-specific env schema lives in `src/config/env.ts`, created by `/api-init-project`.
- `PrismaService` requires `@prisma/client` — installed by `/api-init-project` (or run `npm i @prisma/client` + `npx prisma init`).
- `DateProvider` requires `date-fns` for date manipulation in consuming code — installed by `/api-init-project`.
