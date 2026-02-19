---
name: api-add-query
description: Creates a CQRS query with its handler and in-memory test in a NestJS
  hexagonal module. Use when adding a read operation (data retrieval) to a module.
  Query and handler are defined in the same file. Requires shared base classes
  from /api-setup-shared.
---

# Skill: api-add-query

Creates a CQRS query + handler (in the same file) with its in-memory integration test.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}` values.

---

## Steps

### 1. Create the folder

```
application/queries/{query-name}/
```

Name in kebab-case, read verb (`get-campaign-details`, `list-live-campaigns`, `get-user-balances`).

### 2. Query file — `{query-name}.query.ts`

Query and handler in **the same file**:

```ts
import { QueryHandler, IQueryHandler } from "@nestjs/cqrs";
import { TypedQuery } from "{SHARED_ROOT}/cqrs/typed-query";
import { Inject, Injectable } from "@nestjs/common";
import { MODULE_TOKENS } from "../../{module}.tokens";
import type { ISomeRepository } from "../../domain/{aggregate}/{aggregate}.repository";
import { SomeNotFoundError } from "../../domain/errors";
import type { SomeDomainType } from "../../domain/{aggregate}/{aggregate}";

// 1. Props type
export type XxxQueryProps = {
  someId: string;
  correlationId: string; // REQUIRED
};

// 2. Explicit return type
export type XxxQueryResult = SomeDomainType;
// or: SomeDomainType[] | null | { data: SomeDomainType[]; total: number }

// 3. Query class
export class XxxQuery extends TypedQuery<XxxQueryResult> {
  constructor(public readonly props: XxxQueryProps) {
    super(); // REQUIRED
  }
}

// 4. Handler in the same file
@QueryHandler(XxxQuery)
@Injectable() // REQUIRED on query handlers
export class XxxQueryHandler implements IQueryHandler<XxxQuery, XxxQueryResult> {
  constructor(
    @Inject(MODULE_TOKENS.SOME_REPOSITORY)
    private readonly someRepository: ISomeRepository,
  ) {}

  async execute({ props }: XxxQuery): Promise<XxxQueryResult> {
    const { someId, correlationId } = props;

    const entity = await this.someRepository.findById(someId);
    if (!entity) {
      throw new SomeNotFoundError({ correlationId, someId });
    }

    return entity; // Return domain entity — controller transforms to DTO
  }
}
```

### 3. Test — `{query-name}.query.spec.ts`

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

### 4. Register in `application/{module}.module.ts`

Add `XxxQueryHandler` to the `queryHandlers` array:

```ts
export const queryHandlers = [
  // existing handlers...
  XxxQueryHandler,
];
```

---

## Limitations

- Does not scaffold `InMemorySomeRepository` or `SomeBuilder` — use `/api-add-domain-entity` first.
- Handlers do not include logger injection by default. Add `@InjectLogger()` if `BaseLogger` is available (see `/api-setup-shared`).
