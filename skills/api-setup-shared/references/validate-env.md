# Env validation helper

Creates 2 files in `{SHARED_ROOT}/config/`.

The project-specific env schema (`src/config/env.ts`) is created by `/api-init-project` and imports from this helper.

---

## File 1: `{SHARED_ROOT}/config/validate-env.ts`

```ts
import { z } from "zod";

/**
 * Validates process.env against a Zod schema at startup.
 * Calls process.exit(1) with a readable error if validation fails.
 *
 * Usage in src/config/env.ts:
 *   import { validateEnv } from "../shared/config/validate-env";
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

## File 2: `{SHARED_ROOT}/config/index.ts`

```ts
export * from "./validate-env";
```

---

## Notes

- `z.coerce.number()` handles the fact that all `process.env` values are strings.
- Add `.default()` only for genuinely optional vars — missing required vars without defaults will correctly fail validation.
- `src/config/env.ts` (project-specific schema) was created by `/api-init-project`. After this step completes, that file can now resolve its import and the project will compile.
