# Command test template

File: `application/commands/{command-name}/{command-name}.command.spec.ts`

```ts
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { XxxCommand, XxxCommandHandler } from "./{command-name}.command";
import { InMemorySomeRepository } from "../../../infrastructure/{aggregate}/in-memory-{aggregate}.repository";
import { SomeBuilder } from "../../../domain/{aggregate}/{aggregate}.builder";
import { SomeNotFoundError } from "../../../domain/errors";

describe("XxxCommandHandler", () => {
  let handler: XxxCommandHandler;
  let someRepository: InMemorySomeRepository;

  beforeEach(() => {
    someRepository = new InMemorySomeRepository();
    handler = new XxxCommandHandler(someRepository);
  });

  afterEach(() => {
    someRepository.clear();
  });

  it("should execute successfully when entity exists", async () => {
    const entity = new SomeBuilder().withId("entity-1").build();
    await someRepository.save(entity);

    const command = new XxxCommand({ someId: "entity-1", correlationId: "test-corr" });
    await expect(handler.execute(command)).resolves.not.toThrow();
  });

  it("should throw SomeNotFoundError when entity does not exist", async () => {
    const command = new XxxCommand({ someId: "unknown", correlationId: "test-corr" });
    await expect(handler.execute(command)).rejects.toThrow(SomeNotFoundError);
  });
});
```

## With BaseLogger

Pass `new InMemoryLogger()` from `{SHARED_ROOT}/logger/in-memory-logger` as the second constructor argument:

```ts
import { InMemoryLogger } from "{SHARED_ROOT}/logger/in-memory-logger";

handler = new XxxCommandHandler(someRepository, new InMemoryLogger());
```
