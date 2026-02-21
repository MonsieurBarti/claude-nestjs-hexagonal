# biome.json

File: `biome.json` (project root)

Replaces ESLint + Prettier. Handles linting, formatting, and import sorting in a single tool.

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "assist": {
    "actions": {
      "source": {
        "organizeImports": "on"
      }
    }
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "correctness": {
        "noUnusedVariables": "error",
        "noUnusedImports": "error"
      },
      "style": {
        "noNonNullAssertion": "warn",
        "useImportType": "off"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "parser": {
      "unsafeParameterDecoratorsEnabled": true
    },
    "formatter": {
      "quoteStyle": "double",
      "trailingCommas": "all",
      "semicolons": "always"
    }
  },
  "files": {
    "includes": ["**", "!dist/**", "!prisma/migrations/**"]
  }
}
```

## Notes

- **Biome v2+**: `organizeImports` moved to `assist.actions.source.organizeImports: "on"` (the old top-level `organizeImports` key and `files.ignore` were removed in v2).
- `recommended: true` enables the full set of Biome's recommended lint rules for TypeScript and JavaScript.
- `noNonNullAssertion: "warn"` instead of `"error"` — NestJS DI occasionally requires `!` (e.g. `@InjectRepository()` or optional chaining patterns); error-level would be too noisy out of the box.
- `useImportType: "off"` — **critical for NestJS**. Biome's `useImportType` rule converts `import { X }` to `import type { X }` when it detects X is only used as a type. But NestJS DI relies on `emitDecoratorMetadata` which needs the runtime import. With `import type`, the DI token becomes `undefined` at runtime and NestJS throws "can't resolve dependency".
- `unsafeParameterDecoratorsEnabled: true` — enables parameter decorators (`@Inject()`, `@InjectLogger()`, `@CorrelationId()`) which are non-standard TC39 but required by NestJS.
- `lineWidth: 100` — wider than Prettier's default 80; common in NestJS/TypeScript projects.
- `organizeImports: "on"` — import statements are sorted and deduplicated on every `biome check --write` or `biome format --write` run.
- `quoteStyle: "double"` — matches the TypeScript community convention (and NestJS's own codebase).
- `$schema` version: update to match your installed Biome version (run `pnpm biome --version`). The `2.0.0` schema is compatible with all Biome v2.x releases.
- `files.includes` uses negation patterns (`!dist/**`) to exclude paths — replaces the old `files.ignore` array.
