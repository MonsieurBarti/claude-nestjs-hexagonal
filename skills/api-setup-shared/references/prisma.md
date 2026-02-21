# PrismaService + PrismaModule

## File 1: `{SHARED_ROOT}/prisma/prisma.service.ts`

```ts
import { Injectable, OnModuleInit } from "@nestjs/common";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  constructor() {
    const adapter = new PrismaPg({
      connectionString: process.env["DATABASE_URL"]!,
    });
    super({ adapter });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
  }
}
```

## File 2: `{SHARED_ROOT}/prisma/prisma.module.ts`

```ts
import { Global, Module } from "@nestjs/common";
import { PrismaService } from "./prisma.service";

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
```

`@Global()` means `PrismaModule` is imported once in `AppModule` — every feature module can inject `PrismaService` without importing `PrismaModule` individually.

## Notes

- **Prisma v7+** requires a driver adapter — `PrismaClient` no longer reads `DATABASE_URL` from the environment automatically. The `prisma.config.ts` file is only used by the Prisma CLI (migrations, generate), not by the runtime client.
- `@prisma/adapter-pg` provides the PostgreSQL adapter. Install it as a prod dependency: `pnpm add @prisma/adapter-pg`.
- The `connectionString` reads from `process.env["DATABASE_URL"]` at construction time. For integration tests, set `process.env.DATABASE_URL` **before** NestJS instantiates `PrismaService`.
- If using Prisma v6, the adapter is not needed — `PrismaClient` reads `DATABASE_URL` from env automatically. In that case, remove the constructor and the adapter import.
