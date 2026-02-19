# Application module template

## Module — `application/{module-name}.module.ts`

```ts
import { Module } from "@nestjs/common";
import { CqrsModule } from "@nestjs/cqrs";
import { {MODULE_UPPER}_TOKENS } from "../{module-name}.tokens";
import { SqlSomeRepository } from "../infrastructure/some/sql-some.repository";
import { commandHandlers } from "./commands";
import { queryHandlers } from "./queries";

@Module({
  imports: [CqrsModule],
  providers: [
    {
      provide: {MODULE_UPPER}_TOKENS.SOME_REPOSITORY,
      useClass: SqlSomeRepository,
    },
    ...commandHandlers,
    ...queryHandlers,
  ],
})
export class {ModuleName}ApplicationModule {}
```

## Handler barrel exports

`application/commands/index.ts`:
```ts
export const commandHandlers = [];
```

`application/queries/index.ts`:
```ts
export const queryHandlers = [];
```
