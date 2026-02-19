# app.module.ts

File: `src/app.module.ts`

```ts
import { Module } from "@nestjs/common";
import { LoggerModule } from "nestjs-pino";

@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.LOG_LEVEL ?? "info",
        transport:
          process.env.NODE_ENV !== "production"
            ? { target: "pino-pretty" }
            : undefined,
      },
    }),
  ],
})
export class AppModule {}
```

## Notes

- `AppLoggerModule` (the `BaseLogger` abstraction created by `/api-setup-shared`) is **not** imported here yet. Add it to `imports` after running that skill: `imports: [LoggerModule.forRoot(...), AppLoggerModule]`.
- `LoggerModule.forRoot` configures global pino-http request logging. `AppLoggerModule` imports this same module internally — no double-registration occurs because `LoggerModule` is marked `@Global()` by `nestjs-pino`.
- Add feature modules here as they are scaffolded: `imports: [LoggerModule.forRoot(...), UsersModule, OrdersModule]`.
- Do not add `AppController` or `AppService` — they were removed in the boilerplate cleanup step.
