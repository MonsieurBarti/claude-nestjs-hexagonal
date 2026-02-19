# Hexagonal Architecture — NestJS Modules

## Architecture

4-layer hexagonal: `domain → application → infrastructure → presentation`

CQRS: `TypedCommand<void>` for writes, `TypedQuery<TResult>` for reads.
Command + handler in the **same file**. Same for queries.

## Stack

- **Validation**: Zod only — NO `class-validator`, NO `class-transformer`
- **Tests**: Vitest + `@faker-js/faker`
- **ORM**: Prisma
- **Framework**: NestJS + `@nestjs/cqrs`
- **Logger**: `nestjs-pino` via `BaseLogger` — see [api-setup-shared](skills/api-setup-shared/SKILL.md)

## Configuration

Skills read these values from this file:

```
SHARED_ROOT: src/shared
MODULE_ROOT: src/modules
```

## Module structure

```
{module}/
├── application/
│   ├── commands/{name}/{name}.command.ts
│   ├── queries/{name}/{name}.query.ts
│   └── {module}.module.ts
├── domain/
│   ├── {aggregate}/{aggregate}.ts
│   ├── {aggregate}/{aggregate}.repository.ts
│   ├── {aggregate}/{aggregate}.builder.ts     # tests only
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

## Critical invariants

| Rule                    | Detail                                                                           |
| ----------------------- | -------------------------------------------------------------------------------- |
| `correlationId: string` | Required in every command/query props and domain error                           |
| `super()`               | Required in every command/query constructor                                      |
| `props`                 | Property name (never `payload` or `data`)                                        |
| `Symbol()` tokens       | Never string literals for DI tokens                                              |
| Domain isolated         | No imports from `infrastructure/`, `application/`, or `presentation/`            |
| Domain errors           | `extends BaseDomainError`, `reportToMonitoring: false` (user) or `true` (system) |
| Commands                | `extends TypedCommand<void>` — never return data                                 |
| Queries                 | `extends TypedQuery<TResult>` — no side effects                                  |
| No `any`                | The `any` type is prohibited in all forms — use `z.infer<>`, generics, `unknown` + narrowing, or `as unknown as T` (last resort) |
| No `enum`               | Use `z.enum([...])` — derive type with `z.infer<>`, access values via `.Values`  |

## Available skills

- `/api-init-project` — bootstrap a new NestJS project (run before all other skills)
- `/api-setup-shared` — create all shared base classes (run first on a new project)
- `/api-add-domain-entity` — entity + repository + builder + infra
- `/api-add-command` — command + handler + in-memory test
- `/api-add-query` — query + handler + in-memory test
- `/api-add-module` — full module scaffold (4 layers)

## Rules reference

Per-layer constraints auto-load when editing matching files — links for quick access:

- [api-typing](rules/api-typing.md) — `**/*.ts` global typing conventions (no `any`, no `enum`)
- [api-cqrs-shared](rules/api-cqrs-shared.md) — `*.command.ts` + `*.query.ts` shared invariants
- [api-command](rules/api-command.md) — `*.command.ts`
- [api-query](rules/api-query.md) — `*.query.ts`
- [api-domain-entity](rules/api-domain-entity.md) — `**/domain/**/*.ts`
- [api-infrastructure-repository](rules/api-infrastructure-repository.md) — `**/infrastructure/**/*.ts`
- [api-presentation](rules/api-presentation.md) — `**/presentation/**/*.ts`
