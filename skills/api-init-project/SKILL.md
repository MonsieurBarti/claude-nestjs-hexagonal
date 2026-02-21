---
name: api-init-project
description: Bootstraps a brand-new NestJS backend with hexagonal architecture — creates
  the project via the Nest CLI, removes boilerplate, installs the required stack (Prisma,
  Vitest, pino, CQRS, Fastify, Biome), configures package.json scripts, sets up git
  hooks via lefthook, creates the project-specific env config, and generates a
  .claude/CLAUDE.md project guide. Run once on a fresh directory; follow with
  /api-setup-shared to complete the shared infrastructure.
---

# api-init-project

One-time bootstrap for a new NestJS hexagonal project. Run this before `/api-setup-shared`.

> Requires: `@nestjs/cli` installed globally (`npm i -g @nestjs/cli`) and `pnpm` available.
> If the CLI is not installed globally, prefix the `nest new` command with `npx @nestjs/cli`.

> **Note:** The project will not compile after this skill alone — `src/shared/` does not exist yet.
> Run `/api-setup-shared` next to create all shared infrastructure and make the project compile.

## Steps

1. **Create the NestJS project**
   Run in the parent directory of where the project should live:
   ```bash
   npm install -g @nestjs/cli@11 && npx nest new {app-name} --package-manager pnpm
   cd {app-name}
   ```
   > If running inside an existing git repository (monorepo), add `--skip-git` to avoid a nested git repo.

2. **Remove default boilerplate**
   ```bash
   rm src/app.controller.ts src/app.controller.spec.ts src/app.service.ts
   rm -rf test/
   ```

3. **Enable strict TypeScript**
   Edit `tsconfig.json` — replace the individual strict flags with `"strict": true` and add two additional checks:
   ```json
   {
     "compilerOptions": {
       "module": "commonjs",
       "declaration": true,
       "removeComments": true,
       "emitDecoratorMetadata": true,
       "experimentalDecorators": true,
       "allowSyntheticDefaultImports": true,
       "target": "ES2021",
       "sourceMap": true,
       "outDir": "./dist",
       "baseUrl": "./",
       "incremental": true,
       "skipLibCheck": true,
       "strict": true,
       "noImplicitOverride": true,
       "noUncheckedIndexedAccess": true,
       "forceConsistentCasingInFileNames": true,
       "noFallthroughCasesInSwitch": true
     }
   }
   ```
   > Replaces individual flags (`strictNullChecks`, `noImplicitAny`, `strictBindCallApply`) with the single `"strict": true` umbrella flag.

4. **Install production dependencies**
   ```bash
   pnpm add @nestjs/cqrs @nestjs/platform-fastify fastify @fastify/static nestjs-pino pino-http pino-pretty zod @prisma/client @prisma/adapter-pg @nestjs/swagger date-fns
   ```

5. **Install dev dependencies**
   ```bash
   pnpm add -D prisma vitest @faker-js/faker @vitest/coverage-v8 unplugin-swc @swc/core @biomejs/biome lefthook vite-tsconfig-paths
   ```

6. **Remove Jest, Express platform, ESLint, and Prettier**
   ```bash
   pnpm remove jest @types/jest ts-jest supertest @types/supertest @nestjs/platform-express eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser eslint-config-prettier eslint-plugin-prettier prettier @nestjs/eslint-plugin
   ```
   > Unknown packages are silently skipped — safe to run regardless of which packages `nest new` installed.

7. **Remove ESLint and Prettier config files**
   ```bash
   rm -f .eslintrc.js .eslintrc.json .prettierrc .prettierrc.json .prettierignore
   ```

8. **Update `package.json` scripts and remove the Jest block**
   Load [references/package-json-updates.md](references/package-json-updates.md).
   Apply the changes exactly as described — replace `scripts`, remove the `jest` top-level block.

9. **Create `vitest.config.ts`**
    Load [references/vitest-config.md](references/vitest-config.md).
    Create the file at the project root. This single file defines the SWC plugin, globals, coverage, and all three test projects (unit / integration / e2e) inline — no separate workspace file needed.

10. **Create `biome.json`**
    Load [references/biome-config.md](references/biome-config.md).
    Create the file at the project root.

11. **Create `lefthook.yml`**
    Load [references/git-hooks.md](references/git-hooks.md).
    Create the file at the project root.

12. **Install git hooks**
    ```bash
    pnpm lefthook install
    ```

13. **Create project directories**
    ```bash
    mkdir -p src/modules src/config
    ```

14. **Create `src/config/env.ts`**
    Load [references/env-config.md](references/env-config.md).
    This is the project-specific env schema. The `validateEnv` helper it imports is created by `/api-setup-shared`.

15. **Replace `src/main.ts`**
    Load [references/main-ts.md](references/main-ts.md).
    Overwrite `src/main.ts` with the Fastify + pino + ZodPipe + env version.
    *(Imports from `src/shared/` will resolve once `/api-setup-shared` runs.)*

16. **Replace `src/app.module.ts`**
    Load [references/app-module.md](references/app-module.md).
    Overwrite `src/app.module.ts` with the clean version (no AppController, no AppService).

17. **Initialize Prisma**
    ```bash
    pnpm prisma init
    ```
    This creates `prisma/schema.prisma` and `.env` with a `DATABASE_URL` placeholder.

18. **Create `.claude/CLAUDE.md`**
    ```bash
    mkdir -p .claude
    ```
    Load [references/claude-md.md](references/claude-md.md).
    Create `.claude/CLAUDE.md`, substituting `{app-name}` with the actual project name.

19. **Print next steps for the user**
    ```
    ✓ {app-name} scaffold is ready. Next:

    1. Install the plugin as a git submodule (adjust the URL to your fork/copy):
         git submodule add https://github.com/your-org/claude-nestjs-hexagonal .claude/plugins/hexagonal

    2. Wire rules and skills:
         bash .claude/plugins/hexagonal/install.sh

    3. Add your database connection string to .env (DATABASE_URL).
       Customize src/config/env.ts with all required env vars for your project.

    4. Run /api-setup-shared — creates src/shared/ (TypedCommand, BaseLogger,
       ZodValidationPipe, validateEnv, etc.). The project will compile after this step.

    5. Run /api-add-module to scaffold your first feature module.
    ```

## Limitations

- Does not scaffold Docker Compose or CI pipelines.
- `src/main.ts` imports from `src/shared/` which does not exist yet — the project will not compile until `/api-setup-shared` runs.
- `pino-pretty` is for local development only — production logs are structured JSON automatically (controlled by `NODE_ENV !== "production"`).
- The `src/config/env.ts` schema is a placeholder — customize it with all env vars required by your project before deploying.
- **pre-push runs unit tests only** — integration and e2e tests require a database and run in CI.
