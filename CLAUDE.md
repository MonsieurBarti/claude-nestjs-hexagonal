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
│   ├── value-objects/{name}.value-object.ts  # value objects
│   ├── services/{name}.service.ts            # domain services
│   ├── events/{entity}-{action}.event.ts     # domain events
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
| No `any`                | The `any` type is prohibited in all forms — use `z.infer<>`, generics, `unknown` + narrowing |
| No `enum`               | Use `z.enum([...])` — derive type with `z.infer<>`, access values via `.enum`    |
| No `as` casting         | Type assertions (`as X`, `as unknown as X`) are prohibited — use generics, type guards, or `satisfies` (`as const` is allowed) |
| Domain events           | `extends DomainEvent`, published by repository after write, NOT by handler       |
| AggregateRoot           | Entities with events `extends AggregateRoot` — `this.apply(event)` in business methods |
| Aggregate boundaries    | Only root referenced externally, inner entities via root, cross-aggregate refs by ID only |
| Value objects           | Immutable, no identity, `equals()` by attributes, replace primitives with rich types |
| No anemic model         | Business logic in entity methods — handlers only orchestrate (fetch, call, save) |
| No command chains       | `Command → Event → Command` — never chain `CommandBus.execute()` in handlers |
| Domain services         | Stateless, multi-aggregate logic, lives in domain layer, no infrastructure imports |
| Integration events      | Published by event handlers after DB commit, minimal payloads (IDs only) |
| No domain libs          | No external libraries in domain except `zod`, `decimal.js`, `node:crypto` |

## Available skills

Run in this order for a new project:

1. `/api-init-project` — bootstrap a new NestJS project
2. `/api-setup-shared` — create all shared base classes
3. `/api-add-module` — full module scaffold (4 layers)
4. `/api-add-domain-entity` — entity + repository + builder + infra
5. `/api-add-command` — command + handler + in-memory test
6. `/api-add-query` — query + handler + integration test
7. `/api-add-event-handler` — domain event handler + test
8. `/api-add-endpoint` — add HTTP endpoint to existing controller + DTOs
9. `/api-add-domain-error` — add domain error + exception filter mapping

## Rules reference

Per-layer constraints auto-load when editing matching files — links for quick access:

- [api-typing](rules/api-typing.md) — `**/*.ts` global typing conventions (no `any`, no `enum`)
- [api-cqrs-shared](rules/api-cqrs-shared.md) — `*.command.ts` + `*.query.ts` shared invariants
- [api-command](rules/api-command.md) — `*.command.ts`
- [api-query](rules/api-query.md) — `*.query.ts` (includes mandatory `select` clause)
- [api-domain-entity](rules/api-domain-entity.md) — `**/domain/**/*.ts` (includes Decimal.js guidance)
- [api-infrastructure-repository](rules/api-infrastructure-repository.md) — `**/infrastructure/**/*.ts` (static vs instance mapper)
- [api-domain-event](rules/api-domain-event.md) — `**/*.event.ts` domain event conventions
- [api-event-handler](rules/api-event-handler.md) — `**/*.event-handler.ts` event handler conventions
- [api-presentation](rules/api-presentation.md) — `**/presentation/**/*.ts`
- [api-value-object](rules/api-value-object.md) — `**/domain/**/*.ts` value object conventions
- [api-domain-error](rules/api-domain-error.md) — `**/*.error.ts` domain error hierarchy
- [api-domain-service](rules/api-domain-service.md) — `**/domain/services/**/*.ts` domain services
- [api-integration-event](rules/api-integration-event.md) — `**/*.integration-event.ts` cross-service events
- [api-testing](rules/api-testing.md) — `**/*.spec.ts` + `**/*.integration.spec.ts` test conventions
- [api-dto](rules/api-dto.md) — `**/presentation/dto/*.ts` DTO conventions
- [api-module-wiring](rules/api-module-wiring.md) — `**/*.module.ts` module composition
