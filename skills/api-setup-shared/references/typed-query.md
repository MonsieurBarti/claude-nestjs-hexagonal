# TypedQuery

File: `{SHARED_ROOT}/cqrs/typed-query.ts`

```ts
import { IQuery } from "@nestjs/cqrs";

export abstract class TypedQuery<TResult> implements IQuery<TResult> {
  readonly _resultType?: TResult;
}
```
