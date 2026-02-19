---
description: Conventions for CQRS command files in NestJS hexagonal modules
globs:
  - "**/*.command.ts"
---

# Rules — CQRS Commands

Applies to every `*.command.ts` file. Shared CQRS invariants (props naming, correlationId, super(), execute destructuring, handler colocation, no buses, no try-catch, logger pattern) are in `api-cqrs-shared`.

## Command-specific rules

- **`extends TypedCommand<void>`** — commands never return data
- **Inject via `@Inject(TOKEN)`** — always use domain interfaces, never concrete implementations

## Prohibited

- **No data returned** — if the caller needs data, create a separate query
- **No presentation logic** (DTO transformation, HTTP status codes) in the handler

## File structure

```ts
export type XxxCommandProps = {
  // business fields...
  correlationId: string;
};

export class XxxCommand extends TypedCommand<void> {
  constructor(public readonly props: XxxCommandProps) {
    super();
  }
}

@CommandHandler(XxxCommand)
export class XxxCommandHandler implements ICommandHandler<XxxCommand, void> {
  async execute({ props }: XxxCommand): Promise<void> {
    // business logic...
  }
}
```

## Registration

```ts
export const commandHandlers = [XxxCommandHandler];
```
