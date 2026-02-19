# biome.json

File: `biome.json` (project root)

Replaces ESLint + Prettier. Handles linting, formatting, and import sorting in a single tool.

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
  "organizeImports": {
    "enabled": true
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
        "noNonNullAssertion": "warn"
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
    "formatter": {
      "quoteStyle": "double",
      "trailingCommas": "all",
      "semicolons": "always"
    }
  },
  "files": {
    "ignore": [
      "dist/**",
      "node_modules/**",
      "prisma/migrations/**"
    ]
  }
}
```

## Notes

- `recommended: true` enables the full set of Biome's recommended lint rules for TypeScript and JavaScript.
- `noNonNullAssertion: "warn"` instead of `"error"` — NestJS DI occasionally requires `!` (e.g. `@InjectRepository()` or optional chaining patterns); error-level would be too noisy out of the box.
- `lineWidth: 100` — wider than Prettier's default 80; common in NestJS/TypeScript projects.
- `organizeImports: true` — import statements are sorted and deduplicated on every `biome check --write` or `biome format --write` run.
- `quoteStyle: "double"` — matches the TypeScript community convention (and NestJS's own codebase).
- `$schema` pins the version for editor autocompletion. Update the version number if you install a newer Biome, or omit the version pin (`"https://biomejs.dev/schemas/schema.json"`) for always-latest.
- Add project-specific paths to `files.ignore` as needed (e.g. `"coverage/**"`, generated client code).
