# TypedQueryBus

File: `{SHARED_ROOT}/cqrs/typed-query-bus.ts`

Thin wrapper over the NestJS `QueryBus` that preserves the return type inferred from
`TypedQuery<TResult>`. Inject this instead of the native `QueryBus` in controllers
and in-proc facades.

```ts
import { Injectable } from "@nestjs/common";
import { QueryBus } from "@nestjs/cqrs";
import { TypedQuery } from "./typed-query";

@Injectable()
export class TypedQueryBus {
  constructor(private readonly queryBus: QueryBus) {}

  execute<TResult>(query: TypedQuery<TResult>): Promise<TResult> {
    return this.queryBus.execute(query);
  }
}
```

> Export from `{SHARED_ROOT}/cqrs/index.ts`:
> ```ts
> export * from "./typed-query-bus";
> ```
