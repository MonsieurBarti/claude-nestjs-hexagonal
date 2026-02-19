# Query test template

File: `application/queries/{query-name}/{query-name}.query.spec.ts`

```ts
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { XxxQuery, XxxQueryHandler } from "./{query-name}.query";
import { InMemorySomeRepository } from "../../../infrastructure/{aggregate}/in-memory-{aggregate}.repository";
import { SomeBuilder } from "../../../domain/{aggregate}/{aggregate}.builder";
import { SomeNotFoundError } from "../../../domain/errors";

describe("XxxQueryHandler", () => {
  let handler: XxxQueryHandler;
  let someRepository: InMemorySomeRepository;

  beforeEach(() => {
    someRepository = new InMemorySomeRepository();
    handler = new XxxQueryHandler(someRepository);
  });

  afterEach(() => {
    someRepository.clear();
  });

  it("should return entity when it exists", async () => {
    const entity = new SomeBuilder().withId("entity-1").build();
    await someRepository.save(entity);

    const query = new XxxQuery({ someId: "entity-1", correlationId: "test-corr" });
    const result = await handler.execute(query);

    expect(result.id).toBe("entity-1");
  });

  it("should throw SomeNotFoundError when entity does not exist", async () => {
    const query = new XxxQuery({ someId: "unknown", correlationId: "test-corr" });
    await expect(handler.execute(query)).rejects.toThrow(SomeNotFoundError);
  });
});
```
