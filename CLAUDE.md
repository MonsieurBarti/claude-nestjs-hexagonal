# Hexagonal Architecture — NestJS Modules

## Architecture

4-layer hexagonal: `domain → application → infrastructure → presentation`

CQRS: `TypedCommand<void>` for writes, `TypedQuery<TResult>` for reads.
Command + handler live in the **same file**. Same for queries.

## Module structure

```
{module}/
├── application/
│   ├── commands/{name}/{name}.command.ts   # command + handler in same file
│   ├── queries/{name}/{name}.query.ts      # query + handler in same file
│   └── {module}.module.ts                 # NestJS module, commandHandlers[], queryHandlers[]
├── domain/
│   ├── {aggregate}/{aggregate}.ts              # entity (private constructor + factory)
│   ├── {aggregate}/{aggregate}.repository.ts  # port interface
│   ├── {aggregate}/{aggregate}.builder.ts     # fluent builder (tests only)
│   ├── errors/{module}-base.error.ts          # extends BaseDomainError
│   └── events/{module}.event.publisher.ts     # publisher interface
├── infrastructure/
│   ├── {aggregate}/sql-{aggregate}.repository.ts       # Prisma implementation
│   ├── {aggregate}/in-memory-{aggregate}.repository.ts # test double
│   └── {aggregate}/sql-{aggregate}.mapper.ts           # toDomain / toPersistence
├── presentation/
│   ├── controllers/{module}.controller.ts
│   ├── dto/{module}.dto.ts
│   └── in-proc/{module}.in-proc.ts  # cross-module facade (ACL)
├── {module}-exception.filter.ts     # extends BaseFeatureExceptionFilter
├── {module}.tokens.ts               # Symbol() DI tokens
└── {module}.module.ts               # NestJS root module
```

## Critical invariants

| Rule | Detail |
|------|--------|
| `correlationId: string` | Required in every command/query props and domain error |
| `super()` | Required in every command/query constructor |
| `props` | Property name (never `payload` or `data`) |
| `Symbol()` tokens | Never string literals for DI tokens |
| Domain isolated | No imports from `infrastructure/`, `application/`, or `presentation/` |
| Domain errors | `extends BaseDomainError`, `reportToMonitoring: false` (user errors) or `true` (system errors) |
| Commands | `extends TypedCommand<void>` — never return data |
| Queries | `extends TypedQuery<TResult>` — no side effects |

## Tech stack

- **Validation**: Zod only — NO `class-validator`, NO `class-transformer`
- **Tests**: Vitest + `@faker-js/faker`
- **ORM**: Prisma
- **Framework**: NestJS + `@nestjs/cqrs`
- **Logger**: `nestjs-pino` via `BaseLogger` pattern — see `/api-setup-shared`

## Shared base classes

These must exist in `{SHARED_ROOT}/` before using other skills.
Run `/api-setup-shared` to create them on a new project.

- `{SHARED_ROOT}/cqrs/typed-command.ts`
- `{SHARED_ROOT}/cqrs/typed-query.ts`
- `{SHARED_ROOT}/errors/base-domain.error.ts`
- `{SHARED_ROOT}/errors/base-feature-exception.filter.ts`
- `{SHARED_ROOT}/logger/logger.ts`

## Configuration (read by skills)

```
SHARED_ROOT: src/shared
MODULE_ROOT: src/modules
```

## Available skills

- `/api-setup-shared` — create all shared base classes (run first on a new project)
- `/api-add-domain-entity` — entity + repository interface + builder + tests + infra
- `/api-add-command` — command + handler + in-memory test
- `/api-add-query` — query + handler + in-memory test
- `/api-add-module` — full module scaffold (4 layers)
