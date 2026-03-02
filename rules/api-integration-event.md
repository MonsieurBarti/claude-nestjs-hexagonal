---
description: Conventions for integration events — out-of-process cross-service communication
globs:
  - "**/*.integration-event.ts"
---

# Rules — Integration Events

Applies to integration event files (`*.integration-event.ts`).

## Domain events vs integration events

| Aspect | Domain event | Integration event |
|--------|-------------|-------------------|
| Scope | In-process, same transaction | Out-of-process, cross-service |
| Published by | Repository after DB write | Domain event handler after processing |
| Consumers | Same application handlers | External services, message brokers |
| Consistency | Transactional | Eventual |
| Payload | Can include domain details | Minimal IDs and essential data only |

## Publishing flow

```
Entity.apply(DomainEvent)
  → Repository.save() publishes domain event
    → DomainEventHandler reacts
      → Publishes IntegrationEvent via IMessageBus
```

```ts
// Domain event handler publishes integration event:
@EventsHandler(OrderCreatedEvent)
export class PublishOrderCreatedIntegrationHandler
  implements IEventHandler<OrderCreatedEvent>
{
  constructor(
    @Inject(TOKENS.MESSAGE_BUS)
    private readonly messageBus: IMessageBus,
  ) {}

  async handle(event: OrderCreatedEvent): Promise<void> {
    await this.messageBus.publish(
      new OrderCreatedIntegrationEvent({
        orderId: event.aggregateId,
        occurredAt: event.occurredAt,
      }),
    );
  }
}
```

## Integration event structure

```ts
export class OrderCreatedIntegrationEvent {
  constructor(
    public readonly orderId: string,
    public readonly customerId: string,
    public readonly occurredAt: Date,
  ) {}
}
```

## Rules

- **Publish only after DB commit** — never before persistence is confirmed
- **Publish from domain event handlers** — never from command handlers or entities directly
- **Minimal payloads** — include only IDs and essential data, never full domain entities
- **Transactional Outbox** — use when reliable delivery is required (store event in same DB transaction, publish asynchronously)

## File naming and location

- File: `{entity}-{action}.integration-event.ts` (kebab-case)
- Handler: `publish-{event-name}-integration.event-handler.ts`
- Location: integration events in `infrastructure/events/`, handlers in `application/event-handlers/`

## Prohibited

- No publishing from command handlers or entities
- No full domain entity in payload — expose only IDs and essential fields
- No synchronous external calls blocking the write path
