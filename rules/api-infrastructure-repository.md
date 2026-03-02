---
description: Conventions for infrastructure layer files in NestJS hexagonal modules
globs:
  - "**/infrastructure/**/*.ts"
---

# Rules — Infrastructure Layer

Applies to every file under `**/infrastructure/`.

## SQL implementations (Prisma)

- **Implement the domain interface** — `implements IXxxRepository` or `implements IXxxReader`
- **Return domain entities** — never raw Prisma models
- **Use a mapper** — `SqlXxxMapper.toDomain(raw)` and `SqlXxxMapper.toPersistence(entity)`
```ts
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

## Mappers

Two variants — choose based on entity type:

### Static mapper (standard entities)

Use when the repository is a standalone class (not extending `SqlRepositoryBase`):

```ts
export class SqlXxxMapper {
  public static toDomain(raw: PrismaXxx): Xxx {
    return Xxx.create({ id: raw.id, name: raw.name });
  }

  public static toPersistence(entity: Xxx): PrismaXxx {
    const props = entity.toJSON();
    return { id: props.id, name: props.name };
  }
}
```

Called as: `SqlXxxMapper.toDomain(raw)` / `SqlXxxMapper.toPersistence(entity)`

### Instance mapper (AggregateRoot entities)

Use when the repository extends `SqlRepositoryBase<E, R>` — the base class requires a `mapper` property implementing `EntityMapper<E, R>`:

```ts
export class SqlXxxMapper implements EntityMapper<Xxx, PrismaXxxRecord> {
  public toDomain(raw: PrismaXxxRecord): Xxx {
    return Xxx.create({ id: raw.id, name: raw.name });
  }

  public toPersistence(entity: Xxx): PrismaXxxRecord {
    const props = entity.toJSON();
    return { id: props.id, name: props.name };
  }
}
```

Assigned as: `protected readonly mapper = new SqlXxxMapper();` in the repository class.

### Shared rules

- No business logic in mappers — structural conversion only
- Handle `snake_case` (Prisma) → `camelCase` (domain) in `toDomain`
- Use generated Prisma types: `import type { Xxx as PrismaXxxRecord } from "@prisma/client"`

## In-memory implementations (tests)

- Implement the same domain interface as the SQL implementation
- Store in `Map<string, Entity>`
- `async` methods — same signatures as the SQL implementation
- Expose test helpers: `clear()`, `getAll()`, `count()`

```ts
@Injectable()
export class InMemoryXxxRepository implements IXxxRepository {
  private readonly store = new Map<string, Xxx>();

  async save(entity: Xxx): Promise<void> {
    this.store.set(entity.id, entity);
  }

  async findById(id: string): Promise<Xxx | null> {
    return this.store.get(id) ?? null;
  }

  public clear(): void { this.store.clear(); }
  public getAll(): Xxx[] { return Array.from(this.store.values()); }
  public count(): number { return this.store.size; }
}
```

## Event publishers in-memory

Same pattern: implement the publisher interface, capture published events, expose:
- `getPublishedEvents(): readonly XxxEvent[]`
- `getLastPublishedEvent(): XxxEvent | undefined`
- `hasPublishedEvent(predicate): boolean`
- `clear(): void`

## SqlRepositoryBase (entities with domain events)

- Extend `SqlRepositoryBase<Entity, DbRecord>` from `{SHARED_ROOT}/db/sql-repository.base`
- Inject `PrismaService` + `EventBus` in constructor, pass to `super()`
- Override `getDelegate()` to return the Prisma delegate (e.g., `this.prisma.user`)
- Override `mapper` with an instance implementing `EntityMapper<E, R>`
- Inherit: `save()`, `findById()`, `delete()` — add only custom queries
- Events auto-publish after successful writes — do NOT call `commit()` in handlers

## In-memory repos for AggregateRoot entities

- Call `entity.uncommit()` after save to clear collected events (mirrors real repo)

## Prohibited

- **No business logic** in repositories or mappers
- **No Prisma models exposed** outside the infrastructure layer
- **No extra methods** on SQL implementations — stay faithful to the domain interface
