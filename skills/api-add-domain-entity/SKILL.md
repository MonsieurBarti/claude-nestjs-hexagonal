---
name: api-add-domain-entity
description: Creates a complete domain entity in a NestJS hexagonal module — entity,
  repository interface, test builder, unit tests, SQL repository, in-memory repository,
  mapper, and optionally domain events. Supports both standalone entities and AggregateRoot
  entities with domain event publishing. Use when adding a new aggregate to a module's domain layer.
---

# api-add-domain-entity

Creates the full domain + infrastructure stack for one entity. Run before `/api-add-command` or `/api-add-query`.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}`.

## Steps

1. **Determine entity type** — Ask: "Does this entity publish domain events?"
   - **Yes** → use AggregateRoot variant (extends `AggregateRoot` from `@nestjs/cqrs`)
   - **No** → use standard variant (standalone class)

2. **Domain entity** — `domain/{entity-name}/{entity-name}.ts`
   Load [references/entity-template.md](references/entity-template.md).
   Use the AggregateRoot variant if the entity publishes domain events, standard variant otherwise.

3. **Domain events** (AggregateRoot entities only) — `domain/events/{entity}-{action}.event.ts`
   Load [references/domain-event-template.md](references/domain-event-template.md).
   Create one event class per domain action (e.g., `XxxCreatedEvent`, `XxxUpdatedEvent`).

4. **Repository interface** — `domain/{entity-name}/{entity-name}.repository.ts`
   Load [references/repository-template.md](references/repository-template.md).
   For read-only access: `{entity-name}.reader.ts` with `IXxxReader`.

5. **Test builder** — `domain/{entity-name}/{entity-name}.builder.ts`
   Load [references/builder-template.md](references/builder-template.md).

6. **Unit tests** — `domain/{entity-name}/{entity-name}.spec.ts`
   Load [references/entity-template.md](references/entity-template.md) (spec section) for the pattern.
   Test business methods using the builder.
   For AggregateRoot entities, also test that domain events are emitted correctly.

7. **SQL repository** — `infrastructure/{entity-name}/sql-{entity-name}.repository.ts`
   Load [references/sql-repository-template.md](references/sql-repository-template.md).
   - AggregateRoot entities: use `SqlRepositoryBase` variant (inherits `save()`, `findById()`, `delete()` with auto event publishing)
   - Standard entities: use standalone variant

8. **In-memory repository** — `infrastructure/{entity-name}/in-memory-{entity-name}.repository.ts`
   Load [references/in-memory-repository-template.md](references/in-memory-repository-template.md).
   - AggregateRoot entities: use variant with `entity.uncommit()` after save
   - Standard entities: use standard variant

9. **Mapper** — `infrastructure/{entity-name}/sql-{entity-name}.mapper.ts`
   Load [references/mapper-template.md](references/mapper-template.md).
   - AggregateRoot entities: use `EntityMapper` instance variant (implements `EntityMapper<E, R>`)
   - Standard entities: use static methods variant

10. **DI token** — add `XXX_REPOSITORY: Symbol("{MODULE_UPPER}_XXX_REPOSITORY")` to `{module}.tokens.ts`.

11. **Register provider** — add the SQL repository binding to `application/{module}.module.ts` providers.

## Limitations

- Does not create Prisma schema migrations — add the model to `schema.prisma` and run `prisma migrate dev` separately.
- `IDateProvider` is created by `/api-setup-shared` — pass it as a parameter to `createNew()` factories (domain code does not use DI).
