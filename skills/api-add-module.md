---
name: api-add-module
description: Scaffolds a complete NestJS hexagonal module with all 4 layers (domain,
  application, infrastructure, presentation). Use when starting a new bounded context
  or feature module. Requires shared base classes from /api-setup-shared.
---

# Skill: api-add-module

Full scaffold of a new NestJS hexagonal module following the 4-layer architecture.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}` values.

---

## Step 0: Prerequisites

Check that shared base classes exist before starting:
- `{SHARED_ROOT}/cqrs/typed-command.ts`
- `{SHARED_ROOT}/cqrs/typed-query.ts`
- `{SHARED_ROOT}/errors/base-domain.error.ts`
- `{SHARED_ROOT}/errors/base-feature-exception.filter.ts`

If any are missing, run `/api-setup-shared` first.

---

## Steps

### 1. Create folder structure

```
{MODULE_ROOT}/{module-name}/
├── application/
│   ├── commands/
│   └── queries/
├── domain/
│   └── errors/
├── infrastructure/
└── presentation/
    ├── controllers/
    ├── dto/
    └── in-proc/
```

### 2. DI tokens — `{module-name}.tokens.ts`

```ts
export const {MODULE_UPPER}_TOKENS = {
  // Repositories (for aggregates owned by this module)
  SOME_REPOSITORY: Symbol("{MODULE_UPPER}_SOME_REPOSITORY"),
  // Readers (for external or read-only data)
  // SOME_READER: Symbol("{MODULE_UPPER}_SOME_READER"),
  // Event publisher
  // EVENT_PUBLISHER: Symbol("{MODULE_UPPER}_EVENT_PUBLISHER"),
} as const;
```

### 3. Domain layer — `domain/`

3a. Create entities — use `/api-add-domain-entity`

3b. Base error — `domain/errors/{module-name}-base.error.ts`:
```ts
import { BaseDomainError } from "{SHARED_ROOT}/errors/base-domain.error";

export abstract class {ModuleName}Error extends BaseDomainError {
  abstract readonly errorCode: string;
}
```

3c. First specific errors — `domain/errors/{module-name}.errors.ts`:
```ts
import { {ModuleName}Error } from "./{module-name}-base.error";

export class SomeNotFoundError extends {ModuleName}Error {
  readonly errorCode = "{MODULE_UPPER}_SOME_NOT_FOUND";
  constructor(options: { correlationId?: string; someId: string }) {
    super(`Some entity ${options.someId} not found`, {
      reportToMonitoring: false,
      correlationId: options.correlationId,
      metadata: { someId: options.someId },
    });
  }
}
```

3d. Barrel export — `domain/errors/index.ts`:
```ts
export * from "./{module-name}-base.error";
export * from "./{module-name}.errors";
```

### 4. Application module — `application/{module-name}.module.ts`

```ts
import { Module } from "@nestjs/common";
import { CqrsModule } from "@nestjs/cqrs";
import { {MODULE_UPPER}_TOKENS } from "../{module-name}.tokens";
import { SqlSomeRepository } from "../infrastructure/some/sql-some.repository";
import { commandHandlers } from "./commands";
import { queryHandlers } from "./queries";

@Module({
  imports: [CqrsModule],
  providers: [
    {
      provide: {MODULE_UPPER}_TOKENS.SOME_REPOSITORY,
      useClass: SqlSomeRepository,
    },
    ...commandHandlers,
    ...queryHandlers,
  ],
})
export class {ModuleName}ApplicationModule {}
```

Add barrel exports for handlers:
- `application/commands/index.ts` → `export const commandHandlers = [];`
- `application/queries/index.ts` → `export const queryHandlers = [];`

### 5. Infrastructure layer — `infrastructure/`

For each aggregate, create (use `/api-add-domain-entity` steps 5–7):
- `sql-{aggregate}.repository.ts`
- `in-memory-{aggregate}.repository.ts`
- `sql-{aggregate}.mapper.ts`

### 6. Presentation layer — `presentation/`

6a. Exception filter — `presentation/{module-name}-exception.filter.ts`:
```ts
import { Catch, HttpStatus } from "@nestjs/common";
import { BaseFeatureExceptionFilter } from "{SHARED_ROOT}/errors/base-feature-exception.filter";
import { {ModuleName}Error, SomeNotFoundError } from "../domain/errors";

@Catch({ModuleName}Error)
export class {ModuleName}ExceptionFilter extends BaseFeatureExceptionFilter<{ModuleName}Error> {
  protected mapErrorToStatus(error: {ModuleName}Error): number {
    // System errors FIRST (500)
    // if (error instanceof SomeSystemError) return HttpStatus.INTERNAL_SERVER_ERROR;
    // User errors
    if (error instanceof SomeNotFoundError) return HttpStatus.NOT_FOUND;
    return HttpStatus.INTERNAL_SERVER_ERROR;
  }
}
```

6b. Controller — `presentation/controllers/{module-name}.controller.ts`:
See `api-presentation` rule for the exact pattern.

6c. DTOs — `presentation/dto/{module-name}.dto.ts`

6d. In-proc (if consumed by other modules):
- Interface in `{SHARED_ROOT}/in-proc/{module-name}.in-proc.ts`
- Implementation in `presentation/in-proc/{module-name}.in-proc.ts`

### 7. Root NestJS module — `{module-name}.module.ts`

```ts
import { Module } from "@nestjs/common";
import { APP_FILTER } from "@nestjs/core";
import { {ModuleName}ApplicationModule } from "./application/{module-name}.module";
import { {ModuleName}ExceptionFilter } from "./presentation/{module-name}-exception.filter";
import { {ModuleName}Controller } from "./presentation/controllers/{module-name}.controller";

@Module({
  imports: [{ModuleName}ApplicationModule],
  controllers: [{ModuleName}Controller],
  providers: [
    {
      provide: APP_FILTER,
      useClass: {ModuleName}ExceptionFilter,
    },
  ],
})
export class {ModuleName}Module {}
```

### 8. Register in the application root module

In the app root module (e.g. `app.module.ts`), add `{ModuleName}Module` to `imports`.

---

## Limitations

- Does not create Prisma schema or migrations. Add models to `schema.prisma` and run `prisma migrate dev`.
- Does not scaffold domain events or BullMQ processors. Add them manually as needed.
- The in-proc interface location (`{SHARED_ROOT}/in-proc/`) may differ per project — adjust the path.
