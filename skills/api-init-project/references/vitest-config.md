# vitest.config.ts

File: `vitest.config.ts` (project root)

Single config file — defines the SWC plugin, globals, coverage, and the three test projects inline. No separate `vitest.workspace.ts` file needed (deprecated in Vitest v3.2+, removed in v4).

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
    passWithNoTests: true,
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
    projects: [
      {
        test: {
          name: "unit",
          include: ["src/**/*.spec.ts"],
          exclude: ["src/**/*.integration.spec.ts", "src/**/*.e2e.spec.ts"],
        },
      },
      {
        test: {
          name: "integration",
          include: ["src/**/*.integration.spec.ts"],
        },
      },
      {
        test: {
          name: "e2e",
          include: ["src/**/*.e2e.spec.ts"],
        },
      },
    ],
  },
});
```

## Test file naming convention

| File suffix | Project | Command |
|-------------|---------|---------|
| `*.spec.ts` | unit | `pnpm test:unit` |
| `*.integration.spec.ts` | integration | `pnpm test:int` |
| `*.e2e.spec.ts` | e2e | `pnpm test:e2e` |
| (all) | — | `pnpm test` |

## Notes

- `unplugin-swc` is required because NestJS uses TypeScript decorators (`@Injectable`, `@CommandHandler`, etc.) which Vitest's default esbuild transform does not support.
- `globals: true` enables `describe`, `it`, `expect`, `beforeEach` without explicit imports in test files.
- `passWithNoTests: true` at the root level — prevents failure when no test files exist (e.g. a freshly scaffolded project). Required in Vitest v4.
- `test.projects` (inline) replaces the deprecated `vitest.workspace.ts` file (deprecated in v3.2, unsupported in v4).
- `coverage.exclude` omits module wiring files, builders (test helpers), token files, and all spec files from coverage metrics.
- `pnpm test` (no flags) runs all three projects. `--project unit` selects one.
