# Query integration test templates

File: `application/queries/{query-name}/{query-name}.query.spec.ts`

**Prerequisites** (one-time project setup — not part of this skill):
- `@testcontainers/postgresql` installed
- `supertest` + `@types/supertest` installed
- Docker available (local and CI)

**Scope**: each test boots only the **feature module** (`XxxModule`) — which must import `PrismaModule` explicitly in its own `imports` array. These tests cover Prisma query correctness and response shape. Input validation (400 cases) belongs in controller tests, not here.

---

## Standard query integration test

```ts
// Integration test — requires Docker (Testcontainers)
import { describe, it, expect, beforeAll, beforeEach, afterAll } from "vitest";
import { Test, type TestingModule } from "@nestjs/testing";
import { type INestApplication } from "@nestjs/common";
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from "@testcontainers/postgresql";
import request from "supertest";
import { execSync } from "node:child_process";
import { PrismaService } from "{SHARED_ROOT}/prisma/prisma.service";
import { XxxModule } from "../../{module}.module"; // feature module imports PrismaModule

describe("GET /xxx/:id (integration)", () => {
  let container: StartedPostgreSqlContainer;
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();
    process.env.DATABASE_URL = container.getConnectionUri();

    execSync("npx prisma migrate deploy", { stdio: "inherit" });

    const module: TestingModule = await Test.createTestingModule({
      imports: [XxxModule], // XxxModule imports PrismaModule in its own imports array
    }).compile();

    app = module.createNestApplication();
    await app.init();

    prisma = module.get(PrismaService);
  }, 120_000); // allow time for container startup + migrations

  afterAll(async () => {
    await app.close();
    await container.stop();
  });

  beforeEach(async () => {
    // Truncate relevant tables for isolation between tests
    await prisma.$executeRaw`TRUNCATE TABLE "xxx" RESTART IDENTITY CASCADE`;
  });

  it("should return 200 with the read model", async () => {
    await prisma.xxx.create({ data: { id: "test-1" /* required fields */ } });

    await request(app.getHttpServer())
      .get("/xxx/test-1")
      .expect(200)
      .expect(({ body }) => {
        expect(body).toMatchObject({ id: "test-1" });
      });
  });

  it("should return 404 when not found", async () => {
    await request(app.getHttpServer()).get("/xxx/missing").expect(404);
  });
});
```

---

## Paginated query integration test

```ts
// Integration test — requires Docker (Testcontainers)
import { describe, it, expect, beforeAll, beforeEach, afterAll } from "vitest";
import { Test, type TestingModule } from "@nestjs/testing";
import { type INestApplication } from "@nestjs/common";
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from "@testcontainers/postgresql";
import request from "supertest";
import { execSync } from "node:child_process";
import { PrismaService } from "{SHARED_ROOT}/prisma/prisma.service";
import { XxxModule } from "../../{module}.module";
import { ListXxxQuery } from "./list-{name}.query";

describe("GET /xxx (paginated integration)", () => {
  let container: StartedPostgreSqlContainer;
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();
    process.env.DATABASE_URL = container.getConnectionUri();

    execSync("npx prisma migrate deploy", { stdio: "inherit" });

    const module: TestingModule = await Test.createTestingModule({
      imports: [XxxModule], // XxxModule imports PrismaModule in its own imports array
    }).compile();

    app = module.createNestApplication();
    await app.init();

    prisma = module.get(PrismaService);
  }, 120_000);

  afterAll(async () => {
    await app.close();
    await container.stop();
  });

  beforeEach(async () => {
    await prisma.$executeRaw`TRUNCATE TABLE "xxx" RESTART IDENTITY CASCADE`;
  });

  it("should return paginated results with correct total", async () => {
    await prisma.xxx.createMany({
      data: [
        { id: "1" /* fields */ },
        { id: "2" /* fields */ },
        { id: "3" /* fields */ },
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
