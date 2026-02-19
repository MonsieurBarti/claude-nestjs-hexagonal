---
name: api-add-domain-entity
description: Creates a complete domain entity in an existing NestJS hexagonal module,
  including repository/reader interface, test builder, unit tests, and infrastructure
  implementations (SQL Prisma + in-memory). Use when adding a new aggregate or value
  object to a module's domain layer.
---

# Skill: api-add-domain-entity

Creates a complete domain entity with all its supporting files: interface, builder, unit tests, SQL repository, in-memory repository, and mapper.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}` values.

---

## Steps

### 1. Domain entity — `domain/{entity-name}/{entity-name}.ts`

```ts
import { z, ZodError } from "zod";
import { randomUUID } from "node:crypto";

// Zod schema for validation
export const XxxPropsSchema = z.object({
  id: z.string().uuid(),
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
  public toJSON(): XxxProps { /* ... */ }
}
```

### 2. Repository/reader interface — `domain/{entity-name}/{entity-name}.repository.ts`

```ts
export interface IXxxRepository {
  save(entity: Xxx): Promise<void>;
  findById(id: string): Promise<Xxx | null>;
  // other necessary methods...
}
```

For a read-only reader: `{entity-name}.reader.ts` with `IXxxReader`.

### 3. Test builder — `domain/{entity-name}/{entity-name}.builder.ts`

```ts
import { faker } from "@faker-js/faker";
import { Xxx, XxxProps } from "./{entity-name}";

export class XxxBuilder {
  private id: string = faker.string.uuid();
  // ... other fields with default values

  public withId(id: string): XxxBuilder { this.id = id; return this; }
  // ... other with*() methods

  // Semantic preset methods when relevant
  public asActiveXxx(): XxxBuilder { /* ... */ return this; }

  public build(): Xxx {
    return Xxx.create({ id: this.id, /* ... */ });
  }

  public buildProps(): XxxProps {
    return { id: this.id, /* ... */ };
  }
}
```

### 4. Unit tests — `domain/{entity-name}/{entity-name}.spec.ts`

Test business methods of the entity with Vitest. Use the builder to create test instances.

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

### 5. SQL implementation — `infrastructure/{entity-name}/sql-{entity-name}.repository.ts`

```ts
import { Injectable } from "@nestjs/common";
import { PrismaService } from "{SHARED_ROOT}/prisma/prisma.service";
import { SqlXxxMapper } from "./sql-{entity-name}.mapper";

@Injectable()
export class SqlXxxRepository implements IXxxRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(entity: Xxx): Promise<void> {
    const data = SqlXxxMapper.toPersistence(entity);
    await this.prisma.xxx.upsert({ where: { id: data.id }, create: data, update: data });
  }

  async findById(id: string): Promise<Xxx | null> {
    const raw = await this.prisma.xxx.findUnique({ where: { id } });
    return raw ? SqlXxxMapper.toDomain(raw) : null;
  }
}
```

### 6. In-memory implementation — `infrastructure/{entity-name}/in-memory-{entity-name}.repository.ts`

```ts
import { Injectable } from "@nestjs/common";

@Injectable()
export class InMemoryXxxRepository implements IXxxRepository {
  private readonly store = new Map<string, Xxx>();

  async save(entity: Xxx): Promise<void> { this.store.set(entity.id, entity); }
  async findById(id: string): Promise<Xxx | null> { return this.store.get(id) ?? null; }

  // Test helpers
  public clear(): void { this.store.clear(); }
  public getAll(): Xxx[] { return Array.from(this.store.values()); }
  public count(): number { return this.store.size; }
}
```

### 7. Mapper — `infrastructure/{entity-name}/sql-{entity-name}.mapper.ts`

```ts
export class SqlXxxMapper {
  public static toDomain(raw: PrismaXxx): Xxx {
    return Xxx.create({ id: raw.id, /* snake_case → camelCase */ });
  }

  public static toPersistence(entity: Xxx): PrismaXxx {
    return { id: entity.id, /* camelCase → snake_case */ };
  }
}
```

### 8. DI token — `{module}.tokens.ts`

Add the token:
```ts
export const MODULE_TOKENS = {
  // ...
  XXX_REPOSITORY: Symbol("MODULE_XXX_REPOSITORY"),
} as const;
```

### 9. Register in `application/{module}.module.ts`

```ts
providers: [
  // ...
  {
    provide: MODULE_TOKENS.XXX_REPOSITORY,
    useClass: SqlXxxRepository,
  },
],
```

---

## Limitations

- Does not create Prisma schema migrations — add the model to `schema.prisma` and run `prisma migrate dev` separately.
- Does not create domain events — add an `events/` folder and publisher interface manually.
- Does not scaffold `IDateProvider` — inject it as needed for `createNew()` factories.
