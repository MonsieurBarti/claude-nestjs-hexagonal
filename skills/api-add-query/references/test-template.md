# Query integration test templates

File: `application/queries/{query-name}/{query-name}.query.integration.spec.ts`

**Prerequisites** (one-time project setup — not part of this skill):
- `@testcontainers/postgresql` installed
- `supertest` + `@types/supertest` installed
- Docker available (local and CI)

**Scope**: each test boots only the **feature module** (`XxxModule`) — which must import `PrismaModule` explicitly in its own `imports` array. These tests cover Prisma query correctness and response shape. Input validation (400 cases) belongs in controller tests, not here.

**Important (Prisma v7)**: `process.env.DATABASE_URL` must be set **before** NestJS instantiates `PrismaService`, because the adapter reads the connection string at construction time.

---

## Standard query integration test

```ts
// Integration test — requires Docker (Testcontainers)
import { describe, it, expect, beforeAll, beforeEach, afterAll } from "vitest";
import { Test, type TestingModule } from "@nestjs/testing";
import { FastifyAdapter, type NestFastifyApplication } from "@nestjs/platform-fastify";
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from "@testcontainers/postgresql";
import request from "supertest";
import { execSync } from "node:child_process";
import { PrismaService } from "{SHARED_ROOT}/prisma/prisma.service";
import { ZodValidationPipe } from "{SHARED_ROOT}/pipes/zod-validation.pipe";
import { XxxModule } from "../../{module}.module"; // feature module imports PrismaModule
import { TestLoggerModule } from "{SHARED_ROOT}/testing/test-logger.module";

describe("GET /xxx/:id (integration)", () => {
  let container: StartedPostgreSqlContainer;
  let app: NestFastifyApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    container = await new PostgreSqlContainer("postgres:16").start();
    const databaseUrl = container.getConnectionUri();

    // IMPORTANT: set DATABASE_URL BEFORE NestJS creates PrismaService
    // (Prisma v7 adapter reads connectionString at construction time)
    process.env.DATABASE_URL = databaseUrl;

    // Push schema to test database (use --url to override prisma.config.ts)
    execSync(`pnpm prisma db push --url "${databaseUrl}"`, {
      cwd: process.cwd(),
    });

    const module: TestingModule = await Test.createTestingModule({
      imports: [TestLoggerModule, XxxModule], // XxxModule imports PrismaModule in its own imports array
    }).compile();

    app = module.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter({ logger: false }),
    );
    app.useGlobalPipes(new ZodValidationPipe());
    app.enableVersioning(); // only if the controller uses versioning
    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    prisma = module.get(PrismaService);
  }, 120_000); // allow time for container startup + schema push

  afterAll(async () => {
    await prisma?.$disconnect();
    await app?.close();
    await container?.stop();
  });

  beforeEach(async () => {
    // Truncate relevant tables for isolation between tests
    await prisma.$executeRaw`TRUNCATE TABLE "xxx" RESTART IDENTITY CASCADE`;
  });

  it("should return 200 with the read model", async () => {
    const id = "550e8400-e29b-41d4-a716-446655440001";
    await prisma.xxx.create({ data: { id /* required fields */ } });

    await request(app.getHttpServer())
      .get(`/xxx/${id}`)
      .expect(200)
      .expect(({ body }) => {
        expect(body).toMatchObject({ id });
      });
  });

  it("should return 404 when not found", async () => {
    await request(app.getHttpServer())
      .get("/xxx/00000000-0000-0000-0000-000000000000")
      .expect(404);
  });
});
```

---

## Paginated query integration test

```ts
// Integration test — requires Docker (Testcontainers)
import { describe, it, expect, beforeAll, beforeEach, afterAll } from "vitest";
import { Test, type TestingModule } from "@nestjs/testing";
import { FastifyAdapter, type NestFastifyApplication } from "@nestjs/platform-fastify";
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from "@testcontainers/postgresql";
import request from "supertest";
import { execSync } from "node:child_process";
import { PrismaService } from "{SHARED_ROOT}/prisma/prisma.service";
import { ZodValidationPipe } from "{SHARED_ROOT}/pipes/zod-validation.pipe";
import { XxxModule } from "../../{module}.module";
import { ListXxxQuery } from "./list-{name}.query";
import { TestLoggerModule } from "{SHARED_ROOT}/testing/test-logger.module";

describe("GET /xxx (paginated integration)", () => {
  let container: StartedPostgreSqlContainer;
  let app: NestFastifyApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    container = await new PostgreSqlContainer("postgres:16").start();
    const databaseUrl = container.getConnectionUri();

    // IMPORTANT: set DATABASE_URL BEFORE NestJS creates PrismaService
    process.env.DATABASE_URL = databaseUrl;

    execSync(`pnpm prisma db push --url "${databaseUrl}"`, {
      cwd: process.cwd(),
    });

    const module: TestingModule = await Test.createTestingModule({
      imports: [TestLoggerModule, XxxModule], // XxxModule imports PrismaModule in its own imports array
    }).compile();

    app = module.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter({ logger: false }),
    );
    app.useGlobalPipes(new ZodValidationPipe());
    app.enableVersioning(); // only if the controller uses versioning
    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    prisma = module.get(PrismaService);
  }, 120_000);

  afterAll(async () => {
    await prisma?.$disconnect();
    await app?.close();
    await container?.stop();
  });

  beforeEach(async () => {
    await prisma.$executeRaw`TRUNCATE TABLE "xxx" RESTART IDENTITY CASCADE`;
  });

  it("should return paginated results with correct total", async () => {
    await prisma.xxx.createMany({
      data: [
        { id: "550e8400-e29b-41d4-a716-000000000001" /* fields */ },
        { id: "550e8400-e29b-41d4-a716-000000000002" /* fields */ },
        { id: "550e8400-e29b-41d4-a716-000000000003" /* fields */ },
      ],
    });

    await request(app.getHttpServer())
      .get("/xxx?page=1&limit=2")
      .expect(200)
      .expect(({ body }) => {
        expect(body.data).toHaveLength(2);
        expect(body.total).toBe(3);
        expect(body.page).toBe(1);
        expect(body.limit).toBe(2);
      });
  });

  it("should apply default pagination when params are omitted", async () => {
    const { body } = await request(app.getHttpServer()).get("/xxx").expect(200);

    expect(body.limit).toBe(20);
    expect(body.page).toBe(1);
  });
});

// Pagination math — pure unit tests, no DB needed
describe("ListXxxQuery pagination math", () => {
  it("computes correct offset for page 3 with limit 10", () => {
    const q = new ListXxxQuery({ page: 3, limit: 10, correlationId: "c" });
    expect(q.offset).toBe(20);
  });

  it("defaults to page 1, limit 20, offset 0", () => {
    const q = new ListXxxQuery({ correlationId: "c" });
    expect(q.page).toBe(1);
    expect(q.limit).toBe(20);
    expect(q.offset).toBe(0);
  });
});
```

## Notes

- **File naming**: use `.integration.spec.ts` suffix so vitest's `integration` project picks it up (not the `unit` project).
- **Prisma v7**: use `pnpm prisma db push --url "..."` instead of `npx prisma migrate deploy`. The `--url` flag overrides `prisma.config.ts`. The old `--skip-generate` flag was removed in v7.
- **DATABASE_URL timing**: set `process.env.DATABASE_URL` before `Test.createTestingModule()` — `PrismaService` reads it in its constructor via the adapter.
- **Cleanup**: use `prisma?.$disconnect()` and `container?.stop()` with optional chaining in `afterAll` to avoid errors if `beforeAll` failed partway through.
