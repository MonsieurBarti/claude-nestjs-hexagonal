---
name: api-add-query
description: Creates a CQRS query + handler + integration test in a NestJS hexagonal
  module. Use when adding a read operation (data retrieval) to a module. Query and
  handler live in the same file. Handlers bypass the domain and repository layers
  entirely — direct PrismaService only. Requires /api-setup-shared.
---

# api-add-query

Creates `{query-name}.query.ts` (query + handler) and `{query-name}.query.spec.ts` (HTTP integration test with Supertest + Testcontainers), then registers the handler.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}`.

## Steps

1. **Choose variant** — standard (single item or flat list) vs paginated (list with pagination).
   See `rules/api-query.md` for the decision criteria and both templates.

2. **Create folder** — `application/queries/{query-name}/`
   Name in kebab-case, read verb: `get-campaign-details`, `list-live-campaigns`, `get-user-balances`.

3. **Create query file** — `{query-name}.query.ts`
   Load [references/query-template.md](references/query-template.md) and use the matching section (standard or paginated).

4. **Create integration test file** — `{query-name}.query.spec.ts`
   Load [references/test-template.md](references/test-template.md) and use the matching section.
   Tests use Supertest + Testcontainers — a PostgreSQL container starts in `beforeAll`, tables are truncated in `beforeEach`.

5. **Register handler** — add `XxxQueryHandler` to the `providers` array in
   `application/{module-name}.module.ts` and add the corresponding import at the top of that file.

6. **Ensure PrismaService is injectable** — confirm `PrismaModule` (or equivalent) is imported in the feature module so `PrismaService` is available via DI.

## Limitations

- Integration tests require Docker and the following packages installed once per project: `@testcontainers/postgresql`, `supertest`, `@types/supertest`.
- Logger injection is optional. Add `@InjectLogger()` if `BaseLogger` is available (see `/api-setup-shared`).
- `PaginatedQueryBase`, `PaginatedParams`, and `PaginatedResult` require `/api-setup-shared` to have been run (it creates `paginated-query.base.ts`).
