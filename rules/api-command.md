---
description: Conventions for CQRS command files in NestJS hexagonal modules
globs:
  - "**/*.command.ts"
---

# Rules — CQRS Commands

Applies to every `*.command.ts` file in a NestJS hexagonal module.

## File structure (command + handler in the SAME file)

```ts
// Props type
export type XxxCommandProps = {
  // business fields...
  correlationId: string; // REQUIRED
};

// Command class
export class XxxCommand extends TypedCommand<void> {
  constructor(public readonly props: XxxCommandProps) {
    super(); // REQUIRED
  }
}

// Handler in the same file
@CommandHandler(XxxCommand)
export class XxxCommandHandler implements ICommandHandler<XxxCommand, void> {
  private readonly logger: BaseLogger;

  constructor(
    @Inject(MODULE_TOKENS.SOME_REPOSITORY)
    private readonly someRepository: ISomeRepository,
    // Logger injection — see note below
    @InjectLogger() logger: BaseLogger,
  ) {
    this.logger = logger.createChild({
      moduleName: "module-name",
      className: XxxCommandHandler.name,
    });
  }

  async execute({ props }: XxxCommand): Promise<void> {
    const { correlationId } = props;
    // business logic...
  }
}
```

> **Logger note**: `@InjectLogger()` is a custom decorator wrapping `Inject(LOGGER_TOKEN)`.
> Replace with `new Logger(XxxCommandHandler.name)` (NestJS native) or your own injection pattern if not using the custom logger.

## Mandatory rules

- **`extends TypedCommand<void>`** — commands never return data
- **`props` required** — never `payload`, `data`, or any other name
- **`correlationId: string`** — required field in `XxxCommandProps`
- **`super()`** — required in the constructor
- **Handler in the same file** — no separate `*.command.handler.ts` file
- **Inject via `@Inject(TOKEN)`** — always use domain interfaces, never concrete implementations
- **Logger child** — create in constructor with context (`moduleName`, `className`)
- **`execute({ props }: XxxCommand)`** — destructure props in the signature

## Prohibited

- **No `CommandBus` or `QueryBus` injected in a handler** — handlers do not chain buses
- **No `try-catch` just for logging** — the framework logs uncaught errors automatically
- **No data returned** — if the caller needs data, create a separate query
- **No presentation logic** (DTO transformation, HTTP status codes) in the handler

## Registration

Export the handler in the `commandHandlers` array in `application/{module}.module.ts`:
```ts
export const commandHandlers = [
  XxxCommandHandler,
];
```
