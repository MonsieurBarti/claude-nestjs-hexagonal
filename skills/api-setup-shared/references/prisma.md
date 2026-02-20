# PrismaService + PrismaModule

## File 1: `{SHARED_ROOT}/prisma/prisma.service.ts`

```ts
import { Injectable, OnModuleInit } from "@nestjs/common";
import { PrismaClient } from "@prisma/client";

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
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
