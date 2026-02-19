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

- Static class with `toDomain(raw: PrismaXxx): Xxx` and `toPersistence(entity: Xxx): PrismaXxx`
- No business logic in mappers — structural conversion only
- Handle `snake_case` (Prisma) → `camelCase` (domain) in `toDomain`

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

## Prohibited

- **No business logic** in repositories or mappers
- **No Prisma models exposed** outside the infrastructure layer
- **No extra methods** on SQL implementations — stay faithful to the domain interface
