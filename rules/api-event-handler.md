---
description: Conventions for domain event handler files in NestJS hexagonal modules
globs:
  - "**/event-handlers/*.ts"
  - "**/*.event-handler.ts"
---

# Rules — Domain Event Handlers

Applies to every event handler file (`*.event-handler.ts`).

## Structure

- `@EventsHandler(XxxEvent)` decorator — class-based dispatch
- `implements IEventHandler<XxxEvent>` with `handle(event)` method
- Inject repositories via `@Inject(TOKEN)` — same pattern as command handlers

```ts
import { Inject } from "@nestjs/common";
import { EventsHandler, type IEventHandler } from "@nestjs/cqrs";
import { XxxCreatedEvent } from "../../domain/events/xxx-created.event";

@EventsHandler(XxxCreatedEvent)
export class DoSomethingWhenXxxCreatedHandler
  implements IEventHandler<XxxCreatedEvent>
{
  constructor(
    @Inject(TOKENS.YYY_REPOSITORY)
    private readonly yyyRepository: IYyyRepository,
  ) {}

  async handle(event: XxxCreatedEvent): Promise<void> {
    // React to the event
  }
}
```

## Naming

- Class: `{Action}When{Event}Handler` (e.g., `CreateWalletWhenUserCreatedHandler`)
- File: `{action}-when-{event}.event-handler.ts` (kebab-case)
- Location: `application/event-handlers/` within the module

## Registration

- Register in `application/{module-name}.module.ts` providers — list directly, no barrel file
- `CqrsModule` must be imported in the application module (already standard)

## Cross-module events

- Event handlers from module A can listen to events from module B
- Import the event class directly from the source module's domain layer
- The handler module does NOT need to import the source module

## Prohibited

- No HTTP/presentation logic — event handlers are application layer only
- No manual event publishing — events are published by the repository
- No `EventBus` injection unless publishing follow-up events (rare)
- No try-catch around the entire handler — let errors propagate for monitoring
