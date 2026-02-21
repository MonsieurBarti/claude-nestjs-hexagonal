---
description: Conventions for domain event files in NestJS hexagonal modules
globs:
  - "**/domain/events/*.ts"
  - "**/*.event.ts"
---

# Rules — Domain Events

Applies to every domain event file (`*.event.ts`).

## Structure

- Extend `DomainEvent` from `{SHARED_ROOT}/ddd/domain-event.base`
- Constructor takes `DomainEventProps<ThisClass>` — call `super(props)` first, then assign event-specific fields
- All fields `readonly` — events are immutable

```ts
import { DomainEvent, type DomainEventProps } from "{SHARED_ROOT}/ddd/domain-event.base";

export class XxxCreatedEvent extends DomainEvent {
  readonly someField: string;

  constructor(props: DomainEventProps<XxxCreatedEvent>) {
    super(props);
    this.someField = props.someField;
  }
}
```

## Naming

- Class: `{Entity}{Action}Event` (e.g., `UserCreatedEvent`, `OrderCancelledEvent`)
- File: `{entity}-{action}.event.ts` (kebab-case)
- Location: `domain/events/` within the module

## Content

- `aggregateId` is always required — provided by the `DomainEvent` base class
- `metadata.correlationId` should be passed from command props when available
- Carry only the data needed by consumers, not the entire entity
- Events describe **what happened**, not what should happen next

## Prohibited

- No business logic in events
- No mutable fields
- No imports from `infrastructure/`, `application/`, or `presentation/`
- No NestJS decorators in event classes
