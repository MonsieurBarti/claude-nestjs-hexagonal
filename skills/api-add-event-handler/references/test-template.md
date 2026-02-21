# Event handler test template

File: `application/event-handlers/{action}-when-{event}.event-handler.spec.ts`

```ts
import { describe, it, expect, beforeEach } from "vitest";
import { DoSomethingWhenXxxCreatedHandler } from "./{action}-when-{event}.event-handler";
import { XxxCreatedEvent } from "../../domain/events/xxx-created.event";
import { InMemoryYyyRepository } from "../../infrastructure/{entity-name}/in-memory-{entity-name}.repository";
import { randomUUID } from "node:crypto";

describe("DoSomethingWhenXxxCreatedHandler", () => {
  let handler: DoSomethingWhenXxxCreatedHandler;
  let yyyRepository: InMemoryYyyRepository;

  beforeEach(() => {
    yyyRepository = new InMemoryYyyRepository();
    handler = new DoSomethingWhenXxxCreatedHandler(yyyRepository);
  });

  it("should do something when xxx is created", async () => {
    const event = new XxxCreatedEvent({
      aggregateId: randomUUID(),
      someField: "value",
      metadata: { correlationId: randomUUID() },
    });

    await handler.handle(event);

    // Assert on side effects
    expect(yyyRepository.count()).toBe(1);
  });
});
```

## Notes

- Construct the event directly — no need for the entity or repository that originally published it
- Pass `metadata.correlationId` to propagate tracing across event handlers
- Use in-memory repositories for all dependencies
- Test the handler in isolation — no NestJS module needed
