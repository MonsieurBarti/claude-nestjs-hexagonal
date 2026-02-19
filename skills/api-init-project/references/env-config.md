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
});

export const env = validateEnv(EnvSchema);
export type Env = z.infer<typeof EnvSchema>;
```

## Notes

- This file is imported as a side-effect in `main.ts` (`import "./config/env"`), which runs `validateEnv()` before the NestJS app is created — fail fast on missing vars.
- `z.coerce.number()` handles the fact that all `process.env` values are strings — coercion converts `"3000"` to `3000`.
- Add `.default()` only for genuinely optional vars. Missing required vars without defaults will correctly fail validation.
- The `env` export can be imported anywhere in the app for typed env access instead of `process.env.FOO`.
- This file will not compile until `/api-setup-shared` creates `src/shared/config/validate-env.ts`.
