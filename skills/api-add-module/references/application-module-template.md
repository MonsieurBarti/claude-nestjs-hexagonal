# Application module template

## Module — `application/{module-name}.module.ts`

Each handler is imported and listed explicitly in `providers` — no barrel files, no spread arrays.
When you add a command or query (via `/api-add-command` or `/api-add-query`), add the handler
import and its class to `providers` directly.

```ts
import { Module } from "@nestjs/common";
import { CqrsModule } from "@nestjs/cqrs";
import { PrismaModule } from "{SHARED_ROOT}/prisma/prisma.module";
import { {MODULE_UPPER}_TOKENS } from "../{module-name}.tokens";
import { SqlSomeRepository } from "../infrastructure/some/sql-some.repository";
// import { CreateXxxCommandHandler } from "./commands/create-xxx/create-xxx.command";
// import { GetXxxQueryHandler } from "./queries/get-xxx/get-xxx.query";

@Module({
  imports: [CqrsModule, PrismaModule],
  providers: [
    {
      provide: {MODULE_UPPER}_TOKENS.SOME_REPOSITORY,
      useClass: SqlSomeRepository,
    },
    // CreateXxxCommandHandler,
    // GetXxxQueryHandler,
  ],
})
export class {ModuleName}ApplicationModule {}
```

> `PrismaModule` is imported here (not just in the root module) so that integration tests
> can instantiate `{ModuleName}ApplicationModule` standalone without the full app.
