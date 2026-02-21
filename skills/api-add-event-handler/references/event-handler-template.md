# Event handler template

File: `application/event-handlers/{action}-when-{event}.event-handler.ts`

```ts
import { Inject } from "@nestjs/common";
import { EventsHandler, type IEventHandler } from "@nestjs/cqrs";
import { XxxCreatedEvent } from "../../domain/events/xxx-created.event";
import type { IYyyRepository } from "../../domain/{entity-name}/{entity-name}.repository";
import { TOKENS } from "../../{module-name}.tokens";

@EventsHandler(XxxCreatedEvent)
export class DoSomethingWhenXxxCreatedHandler
  implements IEventHandler<XxxCreatedEvent>
{
  constructor(
    @Inject(TOKENS.YYY_REPOSITORY)
    private readonly yyyRepository: IYyyRepository,
  ) {}

  async handle(event: XxxCreatedEvent): Promise<void> {
    // React to the event — create related entity, update state, etc.
    // Access event data: event.aggregateId, event.someField, event.metadata.correlationId
  }
}
```

## Cross-module event handler

When reacting to events from another module, import the event class directly from the source module's domain layer:

```ts
import { XxxCreatedEvent } from "{MODULE_ROOT}/source-module/domain/events/xxx-created.event";
```

## Naming conventions

- Class: `{Action}When{Event}Handler` (e.g., `CreateWalletWhenUserCreatedHandler`)
- File: `{action}-when-{event}.event-handler.ts` (kebab-case)
