---
name: api-add-domain-entity
description: Creates a complete domain entity in a NestJS hexagonal module — entity,
  repository interface, test builder, unit tests, SQL repository, in-memory repository,
  and mapper. Use when adding a new aggregate or value object to a module's domain layer.
---

# api-add-domain-entity

Creates the full domain + infrastructure stack for one entity. Run before `/api-add-command` or `/api-add-query`.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}`.

## Steps

1. **Domain entity** — `domain/{entity-name}/{entity-name}.ts`
   Load [references/entity-template.md](references/entity-template.md).

2. **Repository interface** — `domain/{entity-name}/{entity-name}.repository.ts`
   Load [references/repository-template.md](references/repository-template.md).
   For read-only access: `{entity-name}.reader.ts` with `IXxxReader`.

3. **Test builder** — `domain/{entity-name}/{entity-name}.builder.ts`
   Load [references/builder-template.md](references/builder-template.md).

4. **Unit tests** — `domain/{entity-name}/{entity-name}.spec.ts`
   Load [references/entity-template.md](references/entity-template.md) (spec section) for the pattern.
   Test business methods using the builder.

5. **SQL repository** — `infrastructure/{entity-name}/sql-{entity-name}.repository.ts`
   Load [references/sql-repository-template.md](references/sql-repository-template.md).

6. **In-memory repository** — `infrastructure/{entity-name}/in-memory-{entity-name}.repository.ts`
   Load [references/in-memory-repository-template.md](references/in-memory-repository-template.md).

7. **Mapper** — `infrastructure/{entity-name}/sql-{entity-name}.mapper.ts`
   Load [references/mapper-template.md](references/mapper-template.md).

8. **DI token** — add `XXX_REPOSITORY: Symbol("{MODULE_UPPER}_XXX_REPOSITORY")` to `{module}.tokens.ts`.

9. **Register provider** — add the SQL repository binding to `application/{module}.module.ts` providers.

## Limitations

- Does not create Prisma schema migrations — add the model to `schema.prisma` and run `prisma migrate dev` separately.
- Does not create domain events — add an `events/` folder and publisher interface manually.
- Does not scaffold `IDateProvider` — inject it as needed for `createNew()` factories.
