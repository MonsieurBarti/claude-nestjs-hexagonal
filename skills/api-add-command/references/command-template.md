# Command + Handler template

File: `application/commands/{command-name}/{command-name}.command.ts`

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

## Optional: logger injection

If `BaseLogger` is available (see `/api-setup-shared`), add to imports and constructor:

```ts
import { InjectLogger } from "{SHARED_ROOT}/logger/inject-logger.decorator";
import type { BaseLogger } from "{SHARED_ROOT}/logger/logger";

// In constructor (after other params):
@InjectLogger() logger: BaseLogger,
// In constructor body:
this.logger = logger.createChild({ moduleName: "module-name", className: XxxCommandHandler.name });
```
