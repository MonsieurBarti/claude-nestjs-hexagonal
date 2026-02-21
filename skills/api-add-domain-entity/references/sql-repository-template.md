# SQL repository template

File: `infrastructure/{entity-name}/sql-{entity-name}.repository.ts`

## Standard variant (no domain events)

```ts
import { Injectable } from "@nestjs/common";
import { PrismaService } from "{SHARED_ROOT}/prisma/prisma.service";
import { IXxxRepository } from "../../domain/{entity-name}/{entity-name}.repository";
import { Xxx } from "../../domain/{entity-name}/{entity-name}";
import { SqlXxxMapper } from "./sql-{entity-name}.mapper";

@Injectable()
export class SqlXxxRepository implements IXxxRepository {
  private readonly mapper = new SqlXxxMapper();

  constructor(private readonly prisma: PrismaService) {}

  async save(entity: Xxx): Promise<void> {
    const data = this.mapper.toPersistence(entity);
    await this.prisma.xxx.upsert({ where: { id: data.id }, create: data, update: data });
  }

  async findById(id: string): Promise<Xxx | null> {
    const raw = await this.prisma.xxx.findUnique({ where: { id } });
    return raw ? this.mapper.toDomain(raw) : null;
  }
}
```

## SqlRepositoryBase variant (entities with domain events)

Use this when the entity extends `AggregateRoot`. Inherits `save()`, `findById()`, `delete()` with automatic event publishing.

```ts
import { Injectable } from "@nestjs/common";
import { SqlRepositoryBase } from "{SHARED_ROOT}/db/sql-repository.base";
import { IXxxRepository } from "../../domain/{entity-name}/{entity-name}.repository";
import { Xxx } from "../../domain/{entity-name}/{entity-name}";
import { SqlXxxMapper, type PrismaXxxRecord } from "./sql-{entity-name}.mapper";

@Injectable()
export class SqlXxxRepository
  extends SqlRepositoryBase<Xxx, PrismaXxxRecord>
  implements IXxxRepository
{
  protected readonly mapper = new SqlXxxMapper();

  protected getDelegate() {
    return this.prisma.xxx;
  }

  // Custom queries only — save(), findById(), delete() are inherited
  // async findByEmail(email: string): Promise<Xxx | null> { ... }
}
```

## Notes

- **SqlRepositoryBase variant**: no explicit constructor needed — NestJS resolves `PrismaService` and `EventBus` from the parent class constructor automatically. Biome flags a `super(prisma, eventBus)` passthrough constructor as `noUselessConstructor`.
- `getDelegate()` returns `this.prisma.xxx` directly — the Prisma delegate satisfies the `PrismaDelegate<DbRecord>` interface structurally. No casting needed when using generated Prisma types in the mapper.
- `PrismaXxxRecord` is a re-export of the generated Prisma type from the mapper file.
