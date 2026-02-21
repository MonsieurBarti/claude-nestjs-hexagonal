# Domain entity template

File: `domain/{entity-name}/{entity-name}.ts`

## Standard entity (no domain events)

```ts
import { z, ZodError } from "zod";
import { randomUUID } from "node:crypto";
import type { IDateProvider } from "{SHARED_ROOT}/date/date-provider";

// Zod schema for validation
export const XxxPropsSchema = z.object({
  id: z.uuid(),
  // ... other fields
  createdAt: z.coerce.date(),
});

export type XxxProps = z.infer<typeof XxxPropsSchema>;

export class Xxx {
  private readonly _id: string;
  // ... other private readonly fields (or private for mutable state)

  private constructor(props: XxxProps) {
    this._id = props.id;
    // ...
  }

  // Factory for reconstitution (from DB)
  public static create(props: XxxProps): Xxx {
    try {
      const validated = XxxPropsSchema.parse(props);
      return new Xxx(validated);
    } catch (error) {
      if (error instanceof ZodError) throw error;
      throw error;
    }
  }

  // Factory for creation (new entity)
  public static createNew(/* params */, dateProvider: IDateProvider): Xxx {
    return Xxx.create({
      id: randomUUID(),
      // ...
      createdAt: dateProvider.now(),
    });
  }

  // Public getters
  public get id(): string { return this._id; }
  // ...

  // Business methods (dependencies as parameters)
  public someBusinessMethod(dependency: IDependency): boolean { /* ... */ }

  // Serialization
  public toJSON(): XxxProps {
    return { id: this._id, /* ... */ };
  }
}
```

## Entity with domain events (extends AggregateRoot)

Use this variant when the entity publishes domain events. The entity extends `AggregateRoot` from `@nestjs/cqrs` and uses `this.apply()` to collect events.

```ts
import { AggregateRoot } from "@nestjs/cqrs";
import { z, ZodError } from "zod";
import { randomUUID } from "node:crypto";
import type { IDateProvider } from "{SHARED_ROOT}/date/date-provider";
import { XxxCreatedEvent } from "../events/xxx-created.event";

export const XxxPropsSchema = z.object({
  id: z.uuid(),
  // ... other fields
  createdAt: z.coerce.date(),
});

export type XxxProps = z.infer<typeof XxxPropsSchema>;

export class Xxx extends AggregateRoot {
  private readonly _id: string;
  // ... other private fields

  private constructor(props: XxxProps) {
    super();
    this._id = props.id;
    // ...
  }

  // Reconstitution from DB — no events emitted
  public static create(props: XxxProps): Xxx {
    try {
      const validated = XxxPropsSchema.parse(props);
      return new Xxx(validated);
    } catch (error) {
      if (error instanceof ZodError) throw error;
      throw error;
    }
  }

  // Creation of new entity — emits domain event
  public static createNew(/* params */, dateProvider: IDateProvider): Xxx {
    const entity = Xxx.create({
      id: randomUUID(),
      // ...
      createdAt: dateProvider.now(),
    });
    entity.apply(
      new XxxCreatedEvent({
        aggregateId: entity.id,
        metadata: { /* correlationId if available */ },
        // ... event-specific fields
      }),
    );
    return entity;
  }

  // Business method that emits event
  public doSomething(): void {
    // ... state change ...
    this.apply(new XxxSomethingDoneEvent({
      aggregateId: this.id,
      // ...
    }));
  }

  // Public getters
  public get id(): string { return this._id; }
  // ...

  // Serialization
  public toJSON(): XxxProps {
    return { id: this._id, /* ... */ };
  }
}
```

### Key differences from standard entity

- `extends AggregateRoot` + `super()` in constructor
- `this.apply(new XxxEvent(...))` in creation + business methods
- `create()` (reconstitution) does NOT emit events
- `createNew()` (new entity) DOES emit events
- Events are collected internally, published by the repository after DB write

## Unit test pattern

File: `domain/{entity-name}/{entity-name}.spec.ts`

```ts
import { describe, it, expect } from "vitest";
import { XxxBuilder } from "./{entity-name}.builder";

describe("Xxx", () => {
  describe("someBusinessMethod", () => {
    it("should return true when ...", () => {
      const entity = new XxxBuilder().build();
      expect(entity.someBusinessMethod(fakeDependency)).toBe(true);
    });
  });
});
```

### Testing domain events (AggregateRoot variant)

```ts
import { describe, it, expect } from "vitest";
import { XxxBuilder } from "./{entity-name}.builder";
import { XxxCreatedEvent } from "../events/xxx-created.event";

describe("Xxx", () => {
  describe("createNew", () => {
    it("should emit XxxCreatedEvent", () => {
      const entity = Xxx.createNew(/* params */, fakeDateProvider);
      const events = entity.getUncommittedEvents();
      expect(events).toHaveLength(1);
      expect(events[0]).toBeInstanceOf(XxxCreatedEvent);
    });
  });
});
```
