# claude-nestjs-hexagonal

A [Claude Code](https://claude.ai/code) plugin that enforces **hexagonal architecture with CQRS** in NestJS projects.

Provides 9 rules (auto-loaded on matching files) and 7 skills (on-demand scaffolding commands).

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- Node.js (v20+)
- pnpm
- Docker (for integration tests with Testcontainers)
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
| `rules/api-typing.md` | `**/*.ts` | Global typing conventions (no `any`, no `enum`, no `as`) |
| `rules/api-cqrs-shared.md` | `*.command.ts` + `*.query.ts` | Shared CQRS invariants (correlationId, super(), props) |
| `rules/api-command.md` | `**/*.command.ts` | Command + handler conventions |
| `rules/api-query.md` | `**/*.query.ts` | Query + handler conventions |
| `rules/api-domain-entity.md` | `**/domain/**/*.ts` | Entity, repository interface, error conventions |
| `rules/api-domain-event.md` | `**/*.event.ts` | Domain event conventions |
| `rules/api-event-handler.md` | `**/*.event-handler.ts` | Event handler conventions |
| `rules/api-infrastructure-repository.md` | `**/infrastructure/**/*.ts` | Repository, mapper, in-memory conventions |
| `rules/api-presentation.md` | `**/presentation/**/*.ts` | Controller, exception filter, DTO conventions |

Rules are loaded automatically by Claude Code when you open or edit a matching file.

### Skills (on-demand slash commands)

| Command | Purpose |
|---------|---------|
| `/api-init-project` | Bootstraps a new NestJS project (run **before** all other skills) |
| `/api-setup-shared` | Creates all shared base classes (run first on an existing project) |
| `/api-add-module` | Scaffolds a full module (4 layers) |
| `/api-add-domain-entity` | Entity + repository interface + builder + tests + SQL/in-memory infra |
| `/api-add-command` | CQRS command + handler + in-memory test |
| `/api-add-query` | CQRS query + handler + in-memory test |
| `/api-add-event-handler` | Domain event handler + test |

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
0. Install the plugin (see above)
1. Configure SHARED_ROOT and MODULE_ROOT in .claude/CLAUDE.md
2. Run /api-init-project   ← bootstraps the NestJS project with all dependencies
3. Run /api-setup-shared   ← creates TypedCommand, TypedQuery, BaseDomainError, BaseLogger, etc.
4. Run /api-add-module     ← scaffolds your first module
5. Run /api-add-domain-entity inside a module
6. Run /api-add-command or /api-add-query inside a module
7. Run /api-add-event-handler for domain event reactions
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
│   ├── events/{entity}-{action}.event.ts      # domain events
│   └── errors/{module}-base.error.ts
├── infrastructure/
│   ├── {aggregate}/sql-{aggregate}.repository.ts
│   ├── {aggregate}/in-memory-{aggregate}.repository.ts
│   └── {aggregate}/sql-{aggregate}.mapper.ts
├── presentation/
│   ├── controllers/{module}.controller.ts
│   ├── dto/{module}.dto.ts
│   └── in-proc/{module}.in-proc.ts
├── {module}-exception.filter.ts
├── {module}.tokens.ts
└── {module}.module.ts
```

**Key invariants enforced by the rules:**
- Validation: Zod only — no `class-validator`, no `class-transformer`
- Commands extend `TypedCommand<void>` and never return data
- Queries extend `TypedQuery<TResult>` and have no side effects
- `correlationId: string` required in every command/query props and domain error
- `super()` required in every command/query constructor
- Domain layer has zero imports from infrastructure, application, or presentation
- DI tokens are `Symbol()` — never string literals
- Domain errors extend `BaseDomainError` with `reportToMonitoring: true` (system) or `false` (user)
- Domain events extend `DomainEvent`, published by repository after write, NOT by handler
- Entities with events extend `AggregateRoot` — `this.apply(event)` in business methods
- No `any` — use `z.infer<>`, generics, `unknown` + narrowing
- No `enum` — use `z.enum([...])` with `.enum` for values
- No `as` casting — type assertions (`as X`, `as unknown as X`) are prohibited; use generics, type guards, or `satisfies`

---

## Tech stack assumed

| Concern | Package |
|---------|---------|
| Framework | NestJS + Fastify + `@nestjs/cqrs` |
| Validation | `zod` |
| ORM | Prisma + `@prisma/adapter-pg` |
| Tests | Vitest + `@faker-js/faker` + Testcontainers |
| Logger | `nestjs-pino` (via `BaseLogger` — swappable) |
| Linter/Formatter | Biome |
| Dates | `date-fns` |

The logger implementation is replaceable: `BaseLogger` is an abstract class. Swap `AppLogger` (pino) with any implementation that satisfies the interface.

---

## License

MIT
