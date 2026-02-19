# vitest.config.ts

File: `vitest.config.ts` (project root)

This is the **base config** — it defines shared settings (SWC plugin, globals, coverage). The workspace file (`vitest.workspace.ts`) defines the three test projects and their include patterns.

```ts
import swc from "unplugin-swc";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [
    swc.vite({
      module: { type: "es6" },
    }),
  ],
  test: {
    globals: true,
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      include: ["src/**/*.ts"],
      exclude: [
        "src/**/*.spec.ts",
        "src/**/*.integration.spec.ts",
        "src/**/*.e2e.spec.ts",
        "src/**/*.module.ts",
        "src/main.ts",
        "src/**/*.builder.ts",
        "src/**/*.tokens.ts",
      ],
    },
  },
});
```

## Notes

- `unplugin-swc` is required because NestJS uses TypeScript decorators (`@Injectable`, `@CommandHandler`, etc.) which Vitest's default esbuild transform does not support.
- `globals: true` enables `describe`, `it`, `expect`, `beforeEach` without explicit imports in test files.
- No `include` at the top level — each workspace project in `vitest.workspace.ts` declares its own include pattern.
- `coverage.exclude` omits module wiring files, builders (test helpers), token files, and all spec files from coverage metrics.
- If the project uses TypeScript path aliases (e.g. `@app/*`), add a `resolve.alias` block matching your `tsconfig.json` `paths`.
