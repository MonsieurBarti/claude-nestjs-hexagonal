---
description: Conventions for NestJS module composition and wiring
globs:
  - "**/*.module.ts"
---

# Rules — Module Wiring

Applies to every `*.module.ts` file.

## Application module (`application/{module}.module.ts`)

The internal module that registers CQRS handlers and infrastructure providers.

- **`CqrsModule` import** — required for command, query, and event handler dispatch
- **`PrismaModule` import** — required when the module has query handlers (they inject `PrismaService` directly)
- **Handlers listed explicitly** — no barrel files, no wildcard imports; each handler class by name
- **Repository bindings** — `{ provide: TOKEN, useClass: SqlXxxRepository }` using `Symbol()` tokens from `{module}.tokens.ts`

```ts
@Module({
  imports: [CqrsModule, PrismaModule],
  providers: [
    // Repository bindings
    { provide: MODULE_TOKENS.XXX_REPOSITORY, useClass: SqlXxxRepository },
    // Command handlers
    XxxCommandHandler,
    // Query handlers
    YyyQueryHandler,
    // Event handlers
    ZzzWhenXxxCreatedHandler,
  ],
  exports: [MODULE_TOKENS.XXX_REPOSITORY],
})
export class XxxApplicationModule {}
```

## Root module (`{module}.module.ts`)

The public-facing module imported by `AppModule`.

- **Imports application module** — `XxxApplicationModule`
- **Registers controller** — in `controllers` array
- **Registers exception filter** — via `APP_FILTER` provider

```ts
@Module({
  imports: [XxxApplicationModule],
  controllers: [XxxController],
  providers: [
    { provide: APP_FILTER, useClass: XxxExceptionFilter },
  ],
})
export class XxxModule {}
```

## DI tokens (`{module}.tokens.ts`)

- **`Symbol()` only** — never string literals for injection tokens
- **Grouped by concern** — repositories, readers, services
- **Descriptive symbol name** — `Symbol("{MODULE_UPPER}_XXX_REPOSITORY")`

```ts
export const MODULE_TOKENS = {
  XXX_REPOSITORY: Symbol("MODULE_XXX_REPOSITORY"),
  YYY_READER: Symbol("MODULE_YYY_READER"),
} as const;
```

## Handler registration

- **Command handlers** — listed in application module `providers`
- **Query handlers** — listed in application module `providers`
- **Event handlers** — listed in application module `providers`
- **All handlers by name** — never `...commandHandlers` spread from barrel

## Prohibited

- **No circular module imports** — if module A needs module B's data, use an in-proc facade
- **No string-based injection tokens** — always `Symbol()`
- **No barrel file re-exports for handlers** — list each handler explicitly in providers
- **No `APP_FILTER` in application module** — exception filters belong in the root module
- **No direct handler imports across modules** — use `TypedCommandBus`/`TypedQueryBus` or in-proc facades
