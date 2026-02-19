# Env validation

Creates 3 files: the shared helper, its barrel, and a project-specific config template.

---

## File 1: `src/shared/config/validate-env.ts`

```ts
import { z } from "zod";

/**
 * Validates process.env against a Zod schema at startup.
 * Calls process.exit(1) with a readable error if validation fails.
 *
 * Usage:
 *   import { validateEnv } from "@shared/config";
 *   export const env = validateEnv(EnvSchema);
 */
export function validateEnv<T extends z.ZodTypeAny>(schema: T): z.infer<T> {
  const result = schema.safeParse(process.env);

  if (!result.success) {
    const errors = result.error.flatten().fieldErrors;
    console.error(
      "❌ Invalid environment variables:\n",
      JSON.stringify(errors, null, 2),
    );
    process.exit(1);
  }

  return result.data;
}
```

---

## File 2: `src/shared/config/index.ts`

```ts
export * from "./validate-env";
```

---

## File 3: `src/config/env.ts`

This file is **project-specific** — not in `src/shared/`. Customize the schema with all env vars your project requires.

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

- `src/config/env.ts` is imported in `main.ts` as a side-effect (`import "./config/env"`), which runs `validateEnv()` before the NestJS app is created.
- `z.coerce.number()` handles the fact that `process.env` values are always strings — coercion converts `"3000"` to `3000`.
- Add a `.default()` only for vars that are truly optional. Required vars without defaults will fail validation if missing (which is the correct behavior).
- The `env` export can be imported anywhere in the app to access typed env values instead of `process.env.FOO`.
