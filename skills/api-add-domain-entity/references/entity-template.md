# Domain entity template

File: `domain/{entity-name}/{entity-name}.ts`

```ts
import { z, ZodError } from "zod";
import { randomUUID } from "node:crypto";

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
