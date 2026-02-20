# src/config/env.ts

File: `src/config/env.ts`

Project-specific env schema. Customize this file with all env vars your project requires.
The `validateEnv` helper is created by `/api-setup-shared` at `src/shared/config/validate-env.ts`.

```ts
import { z } from "zod";
import { validateEnv } from "../shared/config/validate-env";

const EnvSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  LOG_LEVEL: z
    .enum(["trace", "debug", "info", "warn", "error", "fatal"])
    .default("info"),
  IS_LOCAL: z.coerce.boolean().default(false),
});

export const env = validateEnv(EnvSchema);
export type EnvVars = z.infer<typeof EnvSchema>;

// For NestJS ConfigModule.forRoot validate option — throws instead of process.exit
export function validateEnvironment(config: Record<string, unknown>): EnvVars {
  const result = EnvSchema.safeParse(config);
  if (!result.success) {
    const errors = z.flattenError(result.error).fieldErrors;
    throw new Error(`Invalid environment variables:\n${JSON.stringify(errors, null, 2)}`);
  }
  return result.data;
}
```

## Notes

- This file is imported as a side-effect in `main.ts` (`import "./config/env"`), which runs `validateEnv()` before the NestJS app is created — fail fast on missing vars.
- `z.coerce.number()` / `z.coerce.boolean()` handle string env vars: `"3000"` → `3000`, `"true"` → `true`.
- `IS_LOCAL=true` enables pino-pretty transport and debug-level logging. Set in `.env` only — never in production.
- `validateEnvironment` (separate from `validateEnv`) is for `ConfigModule.forRoot({ validate: validateEnvironment })` — throws an Error on failure instead of calling `process.exit(1)`.
- `EnvVars` (replaces old `Env`) is used as the generic for `ConfigService<EnvVars, true>` in `getLoggerConfig`.
- This file will not compile until `/api-setup-shared` creates `src/shared/config/validate-env.ts`.
