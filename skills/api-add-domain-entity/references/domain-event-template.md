# Domain event template

File: `domain/events/{entity}-{action}.event.ts`

```ts
import {
  DomainEvent,
  type DomainEventProps,
} from "{SHARED_ROOT}/ddd/domain-event.base";

export class XxxCreatedEvent extends DomainEvent {
  readonly someField: string;

  constructor(props: DomainEventProps<XxxCreatedEvent>) {
    super(props);
    this.someField = props.someField;
  }
}
```

## Conventions

- Naming: `{Entity}{Action}Event` (e.g., `UserCreatedEvent`, `OrderCancelledEvent`)
- File naming: `{entity}-{action}.event.ts` (kebab-case)
- Extend `DomainEvent` from `{SHARED_ROOT}/ddd/domain-event.base`
- Constructor takes `DomainEventProps<ThisClass>` — `aggregateId` and `metadata` are handled by the base class
- All fields `readonly` — events are immutable
- Carry only the data needed by consumers, not the entire entity
