# claude-nestjs-hexagonal

A [Claude Code](https://claude.ai/code) plugin that enforces **hexagonal architecture with CQRS** in NestJS projects.

Provides 5 rules (auto-loaded on matching files) and 5 skills (on-demand scaffolding commands).

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- NestJS project with `@nestjs/cqrs`

---

## Installation

Run these three commands from your **project root**:

```bash
# 1. Clone the plugin
mkdir -p .claude/plugins
git clone https://github.com/MonsieurBarti/claude-nestjs-hexagonal.git .claude/plugins/hexagonal

# 2. Create symlinks in .claude/rules/ and .claude/skills/
bash .claude/plugins/hexagonal/install.sh

# 3. Wire the architecture doc into your Claude config
echo "@plugins/hexagonal/CLAUDE.md" >> .claude/CLAUDE.md
```

> If `.claude/CLAUDE.md` doesn't exist yet, create it first: `mkdir -p .claude && touch .claude/CLAUDE.md`

---

## Updating

```bash
cd .claude/plugins/hexagonal && git pull
```

Symlinks always point to the plugin files, so no re-installation needed after a pull.

---

## What's included

### Rules (auto-triggered by file pattern)

| File | Glob | Purpose |
|------|------|---------|
| `rules/api-command.md` | `**/*.command.ts` | Command + handler conventions |
| `rules/api-query.md` | `**/*.query.ts` | Query + handler conventions |
| `rules/api-domain-entity.md` | `**/domain/**/*.ts` | Entity, repository interface, error conventions |
| `rules/api-infrastructure-repository.md` | `**/infrastructure/**/*.ts` | Repository, mapper, in-memory conventions |
| `rules/api-presentation.md` | `**/presentation/**/*.ts` | Controller, exception filter, DTO conventions |

Rules are loaded automatically by Claude Code when you open or edit a matching file.

### Skills (on-demand slash commands)

| Command | Purpose |
|---------|---------|
| `/api-setup-shared` | Creates all shared base classes (run **first** on a new project) |
| `/api-add-module` | Scaffolds a full module (4 layers) |
| `/api-add-domain-entity` | Entity + repository interface + builder + tests + SQL/in-memory infra |
| `/api-add-command` | CQRS command + handler + in-memory test |
| `/api-add-query` | CQRS query + handler + in-memory test |

---

## Configuration

After installation, add a `## Configuration` section to `.claude/CLAUDE.md` to tell skills where to create files:

```
@plugins/hexagonal/CLAUDE.md

## Configuration

SHARED_ROOT: src/shared
MODULE_ROOT: src/modules
```

Adjust the paths to match your project structure. The default values are `src/shared` and `src/modules`.

---

## First use on a new project

```
1. Install the plugin (see above)
2. Configure SHARED_ROOT and MODULE_ROOT in .claude/CLAUDE.md
3. Run /api-setup-shared  ← creates TypedCommand, TypedQuery, BaseDomainError, BaseLogger, etc.
4. Run /api-add-module    ← scaffolds your first module
5. Run /api-add-command or /api-add-query inside a module
```

---

## Architecture overview

4-layer hexagonal: `domain → application → infrastructure → presentation`

```
{module}/
├── application/
│   ├── commands/{name}/{name}.command.ts   # command + handler in same file
│   ├── queries/{name}/{name}.query.ts      # query + handler in same file
│   └── {module}.module.ts
├── domain/
│   ├── {aggregate}/{aggregate}.ts              # entity (private constructor + Zod factory)
│   ├── {aggregate}/{aggregate}.repository.ts  # port interface
│   ├── {aggregate}/{aggregate}.builder.ts     # fluent builder (tests only)
│   └── errors/
├── infrastructure/
│   ├── {aggregate}/sql-{aggregate}.repository.ts
│   ├── {aggregate}/in-memory-{aggregate}.repository.ts
│   └── {aggregate}/sql-{aggregate}.mapper.ts
└── presentation/
    ├── controllers/{module}.controller.ts
    ├── dto/{module}.dto.ts
    └── in-proc/{module}.in-proc.ts
```

**Key invariants enforced by the rules:**
- Validation: Zod only — no `class-validator`, no `class-transformer`
- Commands extend `TypedCommand<void>` and never return data
- Queries extend `TypedQuery<TResult>` and have no side effects
- `correlationId: string` required in every command/query props
- `super()` required in every command/query constructor
- Domain layer has zero imports from infrastructure, application, or presentation
- DI tokens are `Symbol()` — never string literals
- Domain errors set `reportToMonitoring: true` for system errors, `false` for user errors

---

## Tech stack assumed

| Concern | Package |
|---------|---------|
| Framework | NestJS + `@nestjs/cqrs` |
| Validation | `zod` |
| ORM | Prisma |
| Tests | Vitest + `@faker-js/faker` |
| Logger | `nestjs-pino` (via `BaseLogger` — swappable) |

The logger implementation is replaceable: `BaseLogger` is an abstract class. Swap `AppLogger` (pino) with any implementation that satisfies the interface.

---

## License

MIT
