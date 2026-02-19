---
name: api-setup-shared
description: Creates all shared infrastructure required for hexagonal NestJS modules —
  TypedCommand, TypedQuery, BaseDomainError, BaseFeatureExceptionFilter, the BaseLogger
  pattern (wrapping nestjs-pino), ZodValidationPipe with @ZodSchema decorator, and
  the validateEnv helper. Run once per project before using other api-* skills.
---

# api-setup-shared

Creates everything in `{SHARED_ROOT}/` required by the other `api-*` skills.
Run once — after `/api-init-project` and before `/api-add-module`.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for the `{SHARED_ROOT}` value (default: `src/shared`).

## Steps

1. **TypedCommand** — `{SHARED_ROOT}/cqrs/typed-command.ts`
   Load [references/typed-command.md](references/typed-command.md).

2. **TypedQuery** — `{SHARED_ROOT}/cqrs/typed-query.ts`
   Load [references/typed-query.md](references/typed-query.md).

3. **BaseDomainError** — `{SHARED_ROOT}/errors/base-domain.error.ts`
   Load [references/base-domain-error.md](references/base-domain-error.md).

4. **BaseFeatureExceptionFilter** — `{SHARED_ROOT}/errors/base-feature-exception.filter.ts`
   Load [references/base-feature-exception-filter.md](references/base-feature-exception-filter.md).

5. **Logger stack** (5 files + module) — `{SHARED_ROOT}/logger/`
   Load [references/logger.md](references/logger.md) for all logger files.

6. **Zod validation** (pipe + exception + decorator) — `{SHARED_ROOT}/pipes/` and `{SHARED_ROOT}/decorators/`
   Load [references/zod-validation-pipe.md](references/zod-validation-pipe.md).
   Creates 5 files with barrel exports.

7. **Env validation helper** — `{SHARED_ROOT}/config/validate-env.ts`
   Load [references/validate-env.md](references/validate-env.md).

8. **Barrel exports** — `{SHARED_ROOT}/cqrs/index.ts`, `errors/index.ts`, `logger/index.ts`
   Included in the respective reference files (steps 1–5).
   Steps 6 and 7 include their own barrel exports.

9. **Update `src/app.module.ts`**
   Add `AppLoggerModule` to the `imports` array:
   ```ts
   import { AppLoggerModule } from "./shared/logger/app-logger.module";

   @Module({
     imports: [
       LoggerModule.forRoot({ ... }),
       AppLoggerModule,
     ],
   })
   export class AppModule {}
   ```

10. **Update `src/main.ts`**
    Add the ZodValidationPipe and env validation imports — the project will now compile:
    ```ts
    import { ZodValidationPipe } from "./shared/pipes/zod-validation.pipe";
    import "./config/env"; // add this line near the top

    // inside bootstrap():
    app.useGlobalPipes(new ZodValidationPipe());
    ```

## Limitations

- `AppLoggerModule` requires `nestjs-pino` and `pino-http` — installed by `/api-init-project`.
- For non-pino loggers, replace `AppLogger` with a custom `BaseLogger` implementation.
- `BaseFeatureExceptionFilter` uses Fastify types (`FastifyRequest`, `FastifyReply`) — requires `@nestjs/platform-fastify`.
- `validateEnv` is a helper only — the project-specific env schema lives in `src/config/env.ts`, created by `/api-init-project`.
