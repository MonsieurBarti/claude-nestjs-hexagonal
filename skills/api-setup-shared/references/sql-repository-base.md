# SqlRepositoryBase

Creates `{SHARED_ROOT}/db/sql-repository.base.ts`.

Abstract Prisma-based repository with generic `save()`, `findById()`, `delete()` and automatic domain event publishing via `EventBus`.

```ts
import { EventBus } from "@nestjs/cqrs";
import type { AggregateRoot } from "@nestjs/cqrs";
import type { PrismaService } from "../prisma/prisma.service";

export interface EntityMapper<Entity, DbRecord> {
  toDomain(record: DbRecord): Entity;
  toPersistence(entity: Entity): DbRecord;
}

/**
 * Minimal shape of a Prisma delegate (e.g. prisma.user, prisma.task).
 * Kept loose intentionally — Prisma's generated delegate types are complex generics
 * that change between versions. Subclasses return `this.prisma.xxx` directly.
 */
interface PrismaDelegate<DbRecord> {
  findUnique(args: { where: { id: string } }): Promise<DbRecord | null>;
  upsert(args: {
    where: { id: string };
    create: DbRecord;
    update: DbRecord;
  }): Promise<DbRecord>;
  delete(args: { where: { id: string } }): Promise<DbRecord>;
}

export abstract class SqlRepositoryBase<
  Entity extends AggregateRoot,
  DbRecord extends { id: string },
> {
  protected abstract readonly mapper: EntityMapper<Entity, DbRecord>;

  constructor(
    protected readonly prisma: PrismaService,
    private readonly eventBus: EventBus,
  ) {}

  protected abstract getDelegate(): PrismaDelegate<DbRecord>;

  async save(entity: Entity): Promise<void> {
    const data = this.mapper.toPersistence(entity);
    await this.getDelegate().upsert({
      where: { id: data.id },
      create: data,
      update: data,
    });
    this.publishEvents(entity);
  }

  async findById(id: string): Promise<Entity | null> {
    const raw = await this.getDelegate().findUnique({ where: { id } });
    return raw ? this.mapper.toDomain(raw) : null;
  }

  async delete(entity: Entity): Promise<void> {
    const data = this.mapper.toPersistence(entity);
    await this.getDelegate().delete({ where: { id: data.id } });
    this.publishEvents(entity);
  }

  protected publishEvents(entity: AggregateRoot): void {
    const events = entity.getUncommittedEvents();
    if (events.length > 0) {
      this.eventBus.publishAll(events);
      entity.uncommit();
    }
  }
}
```

## Design notes

- Uses `EventBus.publishAll()` directly instead of `mergeObjectContext` + `commit()` — simpler, avoids patching each entity instance.
- The repository takes `EventBus` in its constructor (injected by NestJS from `CqrsModule`).
- `delete()` uses `mapper.toPersistence()` to get the ID instead of `(entity as any).id`.
- Subclasses override `getDelegate()` to return the Prisma delegate (e.g., `this.prisma.user`). The `PrismaDelegate<DbRecord>` interface is intentionally minimal — Prisma's actual delegate satisfies it structurally.
- The `DbRecord` type should be the **generated Prisma type** (imported from `@prisma/client`), not a manual type alias. This ensures the mapper and repository stay in sync with the schema.
