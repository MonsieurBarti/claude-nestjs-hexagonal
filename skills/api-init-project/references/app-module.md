# app.module.ts

File: `src/app.module.ts`

```ts
import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { validateEnvironment } from "./config/env";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, cache: true, validate: validateEnvironment }),
    // AppLoggerModule (added by api-setup-shared — must come after ConfigModule)
    // PrismaModule (added by api-setup-shared)
    // Feature modules...
  ],
})
export class AppModule {}
```

## Notes

- `ConfigModule.forRoot` **must be first** — `AppLoggerModule` uses `LoggerModule.forRootAsync` which injects `ConfigService`.
- `isGlobal: true` makes `ConfigService` available everywhere without re-importing `ConfigModule`.
- `cache: true` avoids repeated env reads in production.
- `validate: validateEnvironment` runs the Zod schema on startup and throws on invalid vars (different from the eager `process.exit` in `main.ts` import — both guard the same schema).
- `@nestjs/config` must be installed: `pnpm add @nestjs/config`.
- After running `/api-setup-shared`, the module will look like:
  ```ts
  imports: [
    ConfigModule.forRoot({ isGlobal: true, cache: true, validate: validateEnvironment }),
    AppLoggerModule,
    PrismaModule,
  ]
  ```
- Add feature modules here as they are scaffolded.
- Do not add `AppController` or `AppService` — they were removed in the boilerplate cleanup step.
