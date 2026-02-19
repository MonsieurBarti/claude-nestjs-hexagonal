# BaseDomainError

File: `{SHARED_ROOT}/errors/base-domain.error.ts`

```ts
export abstract class BaseDomainError extends Error {
  abstract readonly errorCode: string;
  readonly reportToMonitoring: boolean;
  readonly correlationId?: string;
  readonly metadata?: Record<string, unknown>;
  readonly timestamp = new Date();

  constructor(
    message: string,
    options?: {
      reportToMonitoring?: boolean;
      correlationId?: string;
      metadata?: Record<string, unknown>;
    },
  ) {
    super(message);
    this.name = this.constructor.name;
    this.reportToMonitoring = options?.reportToMonitoring ?? false;
    this.correlationId = options?.correlationId;
    this.metadata = options?.metadata;
  }
}
```

Barrel: `{SHARED_ROOT}/errors/index.ts`

```ts
export * from "./base-domain.error";
export * from "./base-feature-exception.filter";
```
