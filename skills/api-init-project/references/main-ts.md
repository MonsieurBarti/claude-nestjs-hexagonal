# main.ts

File: `src/main.ts`

```ts
import { NestFactory } from "@nestjs/core";
import { FastifyAdapter, NestFastifyApplication } from "@nestjs/platform-fastify";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import { Logger } from "nestjs-pino";
import { AppModule } from "./app.module";
import { ZodValidationPipe } from "./shared/pipes/zod-validation.pipe";
import "./config/env"; // validates env at startup — process.exit(1) if vars are missing

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: false }),
    { bufferLogs: true },
  );

  app.useLogger(app.get(Logger));
  app.useGlobalPipes(new ZodValidationPipe());
  app.enableVersioning();
  app.enableShutdownHooks();

  if (process.env.NODE_ENV !== "production") {
    const config = new DocumentBuilder()
      .setTitle("{app-name}")
      .setDescription("{app-name} API")
      .setVersion("1.0")
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup("docs", app, document);
  }

  const port = process.env.PORT ?? 3000;
  await app.listen(port, "0.0.0.0");
}

bootstrap();
```

## Notes

- `FastifyAdapter({ logger: false })` disables Fastify's built-in logger — pino via `nestjs-pino` handles all logging instead.
- `bufferLogs: true` suppresses default NestJS startup logs until pino takes over.
- `"0.0.0.0"` is required for Fastify in Docker/container environments (not needed locally but harmless).
- `import "./config/env"` side-effects: calls `validateEnv()` which calls `process.exit(1)` on invalid env vars — fail fast before any DI container is built.
- `useGlobalPipes(new ZodValidationPipe())` enables automatic schema validation on all `body`, `query`, and `param` arguments decorated with `@ZodSchema`.
- `enableVersioning()` enables URI version prefix (`/v1/...`) on controllers that declare `version: "1"`.
- `enableShutdownHooks()` ensures graceful shutdown on SIGTERM (required for Kubernetes / Docker).
- **Swagger** is only mounted when `NODE_ENV !== "production"` — `/docs` is never exposed in prod. Update the `DocumentBuilder` title, description, and version to match the project.
- Replace `{app-name}` placeholders with the actual project name in the `DocumentBuilder` calls.
