# TypedCommandBus

File: `{SHARED_ROOT}/cqrs/typed-command-bus.ts`

Thin wrapper over the NestJS `CommandBus` that preserves the return type inferred from
`TypedCommand<TResult>`. Inject this instead of the native `CommandBus` in controllers
and in-proc facades.

```ts
import { Injectable } from "@nestjs/common";
import { CommandBus } from "@nestjs/cqrs";
import { TypedCommand } from "./typed-command";

@Injectable()
export class TypedCommandBus {
  constructor(private readonly commandBus: CommandBus) {}

  execute<TResult>(command: TypedCommand<TResult>): Promise<TResult> {
    return this.commandBus.execute(command);
  }
}
```

> Export from `{SHARED_ROOT}/cqrs/index.ts`:
> ```ts
> export * from "./typed-command-bus";
> ```
