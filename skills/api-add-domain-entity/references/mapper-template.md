# Mapper template

File: `infrastructure/{entity-name}/sql-{entity-name}.mapper.ts`

## Standard variant (static methods)

Use when the entity does NOT extend `AggregateRoot` and the SQL repository is standalone.

```ts
import type { Xxx as PrismaXxxRecord } from "@prisma/client";
import { Xxx, type XxxProps } from "../../domain/{entity-name}/{entity-name}";

export type { PrismaXxxRecord };

export class SqlXxxMapper {
  public static toDomain(raw: PrismaXxxRecord): Xxx {
    return Xxx.create({
      id: raw.id,
      // Prisma model fields use camelCase (matching the schema model, not the DB column)
      createdAt: raw.createdAt,
    });
  }

  public static toPersistence(entity: Xxx): PrismaXxxRecord {
    const props = entity.toJSON();
    return {
      id: props.id,
      createdAt: props.createdAt,
    };
  }
}
```

## EntityMapper variant (instance methods)

Use when the entity extends `AggregateRoot` and the SQL repository extends `SqlRepositoryBase`. Required by the `EntityMapper<E, R>` interface.

```ts
import type { Xxx as PrismaXxxRecord } from "@prisma/client";
import type { EntityMapper } from "{SHARED_ROOT}/db/sql-repository.base";
import { Xxx, type XxxProps } from "../../domain/{entity-name}/{entity-name}";

export type { PrismaXxxRecord };

export class SqlXxxMapper implements EntityMapper<Xxx, PrismaXxxRecord> {
  toDomain(raw: PrismaXxxRecord): Xxx {
    return Xxx.create({
      id: raw.id,
      // Prisma model fields use camelCase (matching the schema model, not the DB column)
      createdAt: raw.createdAt,
    });
  }

  toPersistence(entity: Xxx): PrismaXxxRecord {
    const props = entity.toJSON();
    return {
      id: props.id,
      createdAt: props.createdAt,
    };
  }
}
```

## Notes

- **Use generated Prisma types** — `import type { Xxx as PrismaXxxRecord } from "@prisma/client"`. This keeps the mapper in sync with the Prisma schema automatically. Never define `PrismaXxxRecord` as a manual type alias.
- Re-export the type alias with `export type { PrismaXxxRecord }` so `SqlRepositoryBase` generics can reference it.
- Prisma model field names are **camelCase** (matching the `model` definition in `schema.prisma`), even if the DB columns use snake_case via `@map()`. The mapper maps between domain props and Prisma model fields — no snake_case conversion needed.
- No business logic in mappers — structural conversion only.
