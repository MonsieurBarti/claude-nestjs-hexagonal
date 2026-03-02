---
description: Conventions for test files in NestJS hexagonal modules
globs:
  - "**/*.spec.ts"
  - "**/*.integration.spec.ts"
---

# Rules — Testing Conventions

Applies to every test file (`*.spec.ts` and `*.integration.spec.ts`).

## Two test categories

| Category | Suffix | Target | DB | Runner |
|----------|--------|--------|----|--------|
| Unit | `.spec.ts` | Commands, event handlers, domain entities | In-memory repositories | `vitest` unit project |
| Integration | `.integration.spec.ts` | Queries, controllers, full HTTP flows | Testcontainers (PostgreSQL) | `vitest` integration project |

## Unit tests — commands, event handlers, entities

- **In-memory repositories** — never mock `PrismaService` with `vi.fn()`
- **Builders with faker** — use `XxxBuilder` with `@faker-js/faker` defaults; avoid hardcoded values unless testing a specific value
- **Direct handler instantiation** — construct the handler with in-memory dependencies, no `TestingModule`
- **State reset** — `afterEach(() => { repository.clear(); })` on every in-memory repo
- **Event assertions** (AggregateRoot entities) — use `entity.getUncommittedEvents()` to assert emitted events

```ts
describe("XxxCommandHandler", () => {
  let handler: XxxCommandHandler;
  let repository: InMemoryXxxRepository;

  beforeEach(() => {
    repository = new InMemoryXxxRepository();
    handler = new XxxCommandHandler(repository);
  });

  afterEach(() => {
    repository.clear();
  });

  it("should ...", async () => {
    const entity = new XxxBuilder().build();
    await repository.save(entity);

    const command = new XxxCommand({ someId: entity.id, correlationId: "test-corr" });
    await handler.execute(command);

    expect(repository.count()).toBe(1);
  });
});
```

## Integration tests — queries, HTTP flows

- **Testcontainers** — `PostgreSqlContainer("postgres:16")` in `beforeAll`, `container.stop()` in `afterAll`
- **Feature module only** — `Test.createTestingModule({ imports: [TestLoggerModule, XxxModule] })` — never `AppModule`
- **Schema push** — `pnpm prisma db push --url "..."` before app boots
- **DATABASE_URL timing** — set `process.env.DATABASE_URL` before `Test.createTestingModule()` (Prisma reads at construction)
- **Table truncation** — `beforeEach` truncates relevant tables with `RESTART IDENTITY CASCADE`
- **Real HTTP** — use `supertest` against `app.getHttpServer()` for request/response validation
- **Timeout** — `beforeAll` gets `120_000` ms timeout for container startup

```ts
beforeAll(async () => {
  container = await new PostgreSqlContainer("postgres:16").start();
  const databaseUrl = container.getConnectionUri();
  process.env.DATABASE_URL = databaseUrl;
  // push schema to test database
  // ... boot feature module
}, 120_000);

beforeEach(async () => {
  await prisma.$executeRaw`TRUNCATE TABLE "xxx" RESTART IDENTITY CASCADE`;
});
```

## Deterministic testing

- **`FakeDateProvider`** — inject instead of `IDateProvider` for time-dependent logic
- **`InMemoryLogger`** — inject instead of `BaseLogger` when handler uses `@InjectLogger()`
- **Builder presets** — use semantic methods like `.asActiveEntity()`, `.asExpiredEntity()` for readable tests
- **No `Date.now()`** — always go through `IDateProvider` so tests control time

## File naming and placement

| Test type | Location | Naming |
|-----------|----------|--------|
| Entity unit | `domain/{entity}/{entity}.spec.ts` | Same folder as entity |
| Command unit | `application/commands/{name}/{name}.command.spec.ts` | Same folder as command |
| Event handler unit | `application/event-handlers/{name}.event-handler.spec.ts` | Same folder as handler |
| Query integration | `application/queries/{name}/{name}.query.integration.spec.ts` | Same folder as query |

## Prohibited

- **No `vi.fn()` mocks of PrismaService** — use Testcontainers for real DB tests
- **No SQLite or H2** as test database — PostgreSQL via Testcontainers only
- **No `any` in tests** — same typing rules apply (see `api-typing`)
- **No hardcoded UUIDs as default builder values** — use `faker.string.uuid()`
- **No shared mutable state between test files** — each file manages its own setup/teardown
- **No `AppModule` in integration tests** — boot only the feature module under test
