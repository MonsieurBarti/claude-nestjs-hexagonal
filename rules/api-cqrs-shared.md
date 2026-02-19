---
description: Shared invariants for all CQRS command and query files
globs:
  - "**/*.command.ts"
  - "**/*.query.ts"
---

# Rules — CQRS Shared Invariants

Applies to every `*.command.ts` and `*.query.ts` file.

## Mandatory invariants

- **`props` required** — the property holding the payload must always be named `props`, never `payload`, `data`, or anything else
- **`correlationId: string`** — required field in every Props type
- **`super()`** — required in the CQRS class constructor
- **`execute({ props }: XxxClass)`** — destructure `props` in the handler signature
- **Handler in the same file** — no separate `*.command.handler.ts` or `*.query.handler.ts`
- **No `CommandBus` or `QueryBus` injected in a handler** — handlers do not chain buses
- **No `try-catch` just for logging** — the framework logs uncaught errors automatically

## Logger pattern

Inject via `@InjectLogger()` and create a child logger in the constructor:

```ts
private readonly logger: BaseLogger;

constructor(
  @Inject(MODULE_TOKENS.SOME_DEPENDENCY)
  private readonly someDependency: ISomeDependency,
  @InjectLogger() logger: BaseLogger,
) {
  this.logger = logger.createChild({
    moduleName: "module-name",
    className: XxxHandlerOrController.name,
  });
}
```

> **Logger note**: `@InjectLogger()` is a custom decorator wrapping `Inject(LOGGER_TOKEN)`.
> Replace with `new Logger(ClassName.name)` (NestJS native) if not using the custom logger.
