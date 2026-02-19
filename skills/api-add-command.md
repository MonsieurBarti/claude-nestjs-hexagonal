---
name: api-add-command
description: Creates a CQRS command with its handler and in-memory test in a NestJS
  hexagonal module. Use when adding a write operation (state change) to a module.
  Command and handler are defined in the same file. Requires shared base classes
  from /api-setup-shared.
---

# Skill: api-add-command

Creates a CQRS command + handler (in the same file) with its in-memory integration test.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}` values.

---

## Steps

### 1. Create the folder

```
application/commands/{command-name}/
```

Name in kebab-case, imperative verb (`join-campaign`, `create-order`, `cancel-subscription`).

### 2. Command file — `{command-name}.command.ts`

Command and handler in **the same file**:

```ts
import { CommandHandler, ICommandHandler } from "@nestjs/cqrs";
import { TypedCommand } from "{SHARED_ROOT}/cqrs/typed-command";
import { Inject } from "@nestjs/common";
import { MODULE_TOKENS } from "../../{module}.tokens";
import type { ISomeRepository } from "../../domain/{aggregate}/{aggregate}.repository";
import { SomeNotFoundError } from "../../domain/errors";

// 1. Props type
export type XxxCommandProps = {
  someId: string;
  correlationId: string; // REQUIRED
};

// 2. Command class
export class XxxCommand extends TypedCommand<void> {
  constructor(public readonly props: XxxCommandProps) {
    super(); // REQUIRED
  }
}

// 3. Handler in the same file
@CommandHandler(XxxCommand)
export class XxxCommandHandler implements ICommandHandler<XxxCommand, void> {
  constructor(
    @Inject(MODULE_TOKENS.SOME_REPOSITORY)
    private readonly someRepository: ISomeRepository,
  ) {}

  async execute({ props }: XxxCommand): Promise<void> {
    const { someId, correlationId } = props;

    const entity = await this.someRepository.findById(someId);
    if (!entity) {
      throw new SomeNotFoundError({ correlationId, someId });
    }

    // business logic...
    await this.someRepository.save(entity);
  }
}
```

**Optional logger injection** (if `BaseLogger` pattern is available — see `/api-setup-shared`):
```ts
import { InjectLogger } from "{SHARED_ROOT}/logger/inject-logger.decorator";
import type { BaseLogger } from "{SHARED_ROOT}/logger/logger";

// In constructor:
@InjectLogger() logger: BaseLogger,
// Then: this.logger = logger.createChild({ moduleName: "module-name", className: XxxCommandHandler.name });
```

### 3. Test — `{command-name}.command.spec.ts`

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

If using `BaseLogger`, pass `new InMemoryLogger()` from `{SHARED_ROOT}/logger/in-memory-logger` as the second constructor argument.

### 4. Register in `application/{module}.module.ts`

Add `XxxCommandHandler` to the `commandHandlers` array:

```ts
export const commandHandlers = [
  // existing handlers...
  XxxCommandHandler,
];
```

---

## Limitations

- Does not scaffold `InMemorySomeRepository` or `SomeBuilder` — use `/api-add-domain-entity` first.
- Logger injection is shown as optional. If not using `BaseLogger`, use NestJS native `Logger` or omit entirely.
