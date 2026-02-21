# DomainEvent base class

Creates `{SHARED_ROOT}/ddd/domain-event.base.ts` and `{SHARED_ROOT}/ddd/index.ts`.

## domain-event.base.ts

```ts
import type { IEvent } from "@nestjs/cqrs";
import { randomUUID } from "node:crypto";

export type DomainEventMetadata = {
  readonly correlationId: string;
  readonly timestamp: number;
  readonly userId?: string;
};

export type DomainEventProps<T> = Omit<T, "id" | "metadata"> & {
  aggregateId: string;
  metadata?: Partial<DomainEventMetadata>;
};

export abstract class DomainEvent implements IEvent {
  public readonly id: string;
  public readonly aggregateId: string;
  public readonly metadata: DomainEventMetadata;

  constructor(props: DomainEventProps<unknown>) {
    this.id = randomUUID();
    this.aggregateId = props.aggregateId;
    this.metadata = {
      correlationId: props.metadata?.correlationId ?? randomUUID(),
      timestamp: props.metadata?.timestamp ?? Date.now(),
      userId: props.metadata?.userId,
    };
  }
}
```

## index.ts (barrel)

File: `{SHARED_ROOT}/ddd/index.ts`

```ts
export { DomainEvent } from "./domain-event.base";
export type { DomainEventMetadata, DomainEventProps } from "./domain-event.base";
```
