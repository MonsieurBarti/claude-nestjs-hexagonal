# vitest.workspace.ts

File: `vitest.workspace.ts` (project root)

Defines three test projects that extend the base `vitest.config.ts`. Each project runs independently and can be targeted with `--project`.

```ts
import { defineWorkspace } from "vitest/config";

export default defineWorkspace([
  {
    extends: "./vitest.config.ts",
    test: {
      name: "unit",
      include: ["src/**/*.spec.ts"],
      exclude: ["src/**/*.integration.spec.ts", "src/**/*.e2e.spec.ts"],
    },
  },
  {
    extends: "./vitest.config.ts",
    test: {
      name: "integration",
      include: ["src/**/*.integration.spec.ts"],
    },
  },
  {
    extends: "./vitest.config.ts",
    test: {
      name: "e2e",
      include: ["src/**/*.e2e.spec.ts"],
    },
  },
]);
```

## Test file naming convention

| File suffix | Project | Command |
|-------------|---------|---------|
| `*.spec.ts` | unit | `pnpm test:unit` |
| `*.integration.spec.ts` | integration | `pnpm test:int` |
| `*.e2e.spec.ts` | e2e | `pnpm test:e2e` |
| (all of the above) | — | `pnpm test` |

## Notes

- `extends: "./vitest.config.ts"` inherits the SWC plugin, globals, and coverage config from the base config file.
- `pnpm test` (no flags) runs all three projects in parallel via the workspace.
- `pnpm test:unit` targets only the `unit` project, skipping integration and e2e tests.
- Unit tests are the default — all `*.spec.ts` files that do **not** end in `.integration.spec.ts` or `.e2e.spec.ts`.
- Integration tests (`*.integration.spec.ts`) typically spin up an in-memory database or test a full application layer stack without HTTP.
- E2E tests (`*.e2e.spec.ts`) test the full HTTP stack using a real Fastify instance with `@nestjs/testing`.
