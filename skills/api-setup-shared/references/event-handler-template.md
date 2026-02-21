# Event handler reference template

Reference for how domain event handlers are structured. Used by `/api-add-event-handler` skill.

## Handler

```ts
import { EventsHandler, type IEventHandler } from "@nestjs/cqrs";
import { SomeCreatedEvent } from "../../domain/events/some-created.event";

@EventsHandler(SomeCreatedEvent)
export class DoSomethingWhenSomeCreatedHandler
  implements IEventHandler<SomeCreatedEvent>
{
  constructor(/* inject dependencies via @Inject(TOKEN) */) {}

  async handle(event: SomeCreatedEvent): Promise<void> {
    // React to the event — create related entity, send notification, etc.
  }
}
```

## Naming conventions

- Class: `{Action}When{Event}Handler` (e.g., `CreateWalletWhenUserCreatedHandler`)
- File: `{action}-when-{event}.event-handler.ts` (kebab-case)
- Register in `application/{module-name}.module.ts` providers
