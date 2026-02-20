# TypedCommand

File: `{SHARED_ROOT}/cqrs/typed-command.ts`

```ts
import { ICommand } from "@nestjs/cqrs";

export abstract class TypedCommand<TResult> implements ICommand {
  // Phantom type — carries TResult at compile time, unused at runtime
  readonly _resultType?: TResult;
}
```

Barrel: `{SHARED_ROOT}/cqrs/index.ts`

```ts
export * from "./typed-command";
export * from "./typed-query";
export * from "./paginated-query.base";
```
