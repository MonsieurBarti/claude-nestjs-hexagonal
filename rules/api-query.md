---
description: Conventions for CQRS query files in NestJS hexagonal modules
globs:
  - "**/*.query.ts"
---

# Rules — CQRS Queries

Applies to every `*.query.ts` file. Shared CQRS invariants (props naming, correlationId, super(), execute destructuring, handler colocation, no buses, no try-catch, logger pattern) are in `api-cqrs-shared`.

## Query-specific rules

- **`extends TypedQuery<TResult>`** — the return type must be explicit and precise
- **`@Injectable()`** — required decorator on the query handler
- **No side effects** — queries read only, they never mutate state
- **Bypass domain and repository layers** — handlers inject `PrismaService` directly and query the database without going through the domain or any repository abstraction
- **Return read models** — plain typed objects (`XxxReadModel`), not domain entities and not DTO class instances. The read model type is defined in the same query file.

## Two variants

### Standard — single item or flat list

Handler injects `PrismaService`, queries directly, returns `XxxReadModel | null` or `XxxReadModel[]`.

```ts
export type XxxReadModel = { id: string; /* projected fields only */ };
export type XxxQueryResult = XxxReadModel | null;

@QueryHandler(XxxQuery)
@Injectable()
export class XxxQueryHandler implements IQueryHandler<XxxQuery, XxxQueryResult> {
  constructor(private readonly prisma: PrismaService) {}

  async execute({ props }: XxxQuery): Promise<XxxQueryResult> {
    return this.prisma.xxx.findUnique({
      where: { id: props.someId },
      select: { id: true, /* projected fields */ },
    });
  }
}
```

### Paginated — list with pagination

Query class extends `TypedQuery<PaginatedResult<XxxReadModel>>` and replicates the `PaginatedQueryBase` constructor logic inline (TypeScript only allows one `extends` — `TypedQuery<TResult>` takes priority). Import `PaginatedParams`, `PaginatedQueryParams`, and `PaginatedResult` from `{SHARED_ROOT}/cqrs/paginated-query.base`.

Handler uses `execute(query: ListXxxQuery)` (not destructured) and accesses `query.limit`, `query.offset`, `query.orderBy` alongside `query.props`.

```ts
export type ListXxxQueryResult = PaginatedResult<XxxReadModel>;

export class ListXxxQuery extends TypedQuery<ListXxxQueryResult> {
  readonly limit: number;
  readonly offset: number;
  readonly page: number;
  readonly orderBy: { field: string; direction: "asc" | "desc" };

  constructor(public readonly props: ListXxxQueryProps) {
    super();
    this.limit = props.limit ?? 20;
    this.page = props.page ?? 1;
    this.offset = this.page > 0 ? (this.page - 1) * this.limit : 0;
    this.orderBy = props.orderBy ?? { field: "createdAt", direction: "desc" };
  }
}

@QueryHandler(ListXxxQuery)
@Injectable()
export class ListXxxQueryHandler
  implements IQueryHandler<ListXxxQuery, ListXxxQueryResult>
{
  constructor(private readonly prisma: PrismaService) {}

  async execute(query: ListXxxQuery): Promise<ListXxxQueryResult> {
    const where = { /* filter from query.props */ };
    const [rows, total] = await this.prisma.$transaction([
      this.prisma.xxx.findMany({
        where,
        take: query.limit,
        skip: query.offset,
        orderBy: { [query.orderBy.field]: query.orderBy.direction },
      }),
      this.prisma.xxx.count({ where }),
    ]);
    return { data: rows, total, page: query.page, limit: query.limit };
  }
}
```

## Testing

Query handler tests are **HTTP integration tests** (Supertest + Testcontainers):
- One `PostgreSqlContainer` per test file, started in `beforeAll`, stopped in `afterAll`
- Prisma migrations run against the container before the app boots
- `TestingModule` imports only the **feature module** (`XxxModule`) — not `AppModule`; the feature module must explicitly import `PrismaModule` in its own `imports` array
- Seed data via `PrismaService`; tables truncated in `beforeEach` for isolation
- Tests cover Prisma query correctness and response shape — **not** input validation (400 cases belong in controller tests)
- Pagination math (`offset` derivation) tested as pure unit assertions in the same file

## File structure (standard variant)

```ts
export type XxxReadModel = { id: string; /* projected fields */ };

export type XxxQueryProps = {
  someId: string;
  correlationId: string;
};

export type XxxQueryResult = XxxReadModel | null;

export class XxxQuery extends TypedQuery<XxxQueryResult> {
  constructor(public readonly props: XxxQueryProps) {
    super();
  }
}

@QueryHandler(XxxQuery)
@Injectable()
export class XxxQueryHandler implements IQueryHandler<XxxQuery, XxxQueryResult> {
  async execute({ props }: XxxQuery): Promise<XxxQueryResult> {
    return result;
  }
}
```

## Registration

```ts
export const queryHandlers = [XxxQueryHandler];
```

## Prohibited

- **No writes** to the database or state mutations in a query handler
- **No repository injection** — queries bypass repositories entirely
- **No domain entities returned** — return read models (plain typed objects)
- **No DTO class instances returned** — read models are plain types, not class instances
- **No `vi.fn()` mocks of PrismaService** — use integration tests against a real database
