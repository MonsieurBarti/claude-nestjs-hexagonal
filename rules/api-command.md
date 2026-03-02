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

## Handler as orchestrator

Command handlers **orchestrate only** — they fetch entities, call business methods, and save. All business logic lives in domain entities and domain services:

```ts
// Correct — handler orchestrates, entity decides:
async execute({ props }: CancelOrderCommand): Promise<void> {
  const order = await this.orderRepo.findById(props.orderId);
  if (!order) throw new OrderNotFoundError(props.orderId, props.correlationId);
  order.cancel(props.reason); // domain logic in entity
  await this.orderRepo.save(order);
}

// Wrong — business logic leaked into handler:
async execute({ props }: CancelOrderCommand): Promise<void> {
  const order = await this.orderRepo.findById(props.orderId);
  if (order.status !== 'ACTIVE') throw new OrderNotActiveError(order.id);
  order.props.status = 'CANCELLED'; // handler doing entity's job
  await this.orderRepo.save(order);
}
```

## No command-to-command chains

When a command needs to trigger another command, use **domain events** as the bridge — never chain buses in a handler:

```ts
// Correct — Command → Event → Handler → Command:
// PlaceOrderHandler saves entity (emits OrderPlacedEvent)
// NotifyWarehouseWhenOrderPlacedHandler dispatches ReserveStockCommand

// Wrong — direct chain in handler:
async execute(command: PlaceOrderCommand): Promise<void> {
  await this.orderRepo.save(order);
  await this.commandBus.execute(new ReserveStockCommand({ ... })); // tight coupling
}
```

## Prohibited

- **No data returned** — if the caller needs data, create a separate query
- **No presentation logic** (DTO transformation, HTTP status codes) in the handler
- **No business logic in handler** — delegate to entity methods and domain services
- **No `CommandBus.execute()` calls** inside a command handler — use events for chains

## Domain events in commands

- Do NOT manually publish events — the repository handles this after `save()`
- Do NOT inject `EventBus` or `EventPublisher` in command handlers
- Entity mutations via business methods automatically collect events via `this.apply()`

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
