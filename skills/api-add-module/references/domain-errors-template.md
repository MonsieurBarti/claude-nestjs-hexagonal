# Domain errors templates

## Base error — `domain/errors/{module-name}-base.error.ts`

```ts
import { BaseDomainError } from "{SHARED_ROOT}/errors/base-domain.error";

export abstract class {ModuleName}Error extends BaseDomainError {
  abstract override readonly errorCode: string;
}
```

## First specific error — `domain/errors/{module-name}.errors.ts`

```ts
import { {ModuleName}Error } from "./{module-name}-base.error";

export class SomeNotFoundError extends {ModuleName}Error {
  readonly errorCode = "{MODULE_UPPER}_SOME_NOT_FOUND";
  constructor(options: { correlationId?: string; someId: string }) {
    super(`Some entity ${options.someId} not found`, {
      reportToMonitoring: false,
      correlationId: options.correlationId,
      metadata: { someId: options.someId },
    });
  }
}
```

## Barrel export — `domain/errors/index.ts`

```ts
export * from "./{module-name}-base.error";
export * from "./{module-name}.errors";
```
