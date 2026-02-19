---
name: api-add-query
description: Creates a CQRS query + handler + in-memory test in a NestJS hexagonal
  module. Use when adding a read operation (data retrieval) to a module. Query and
  handler live in the same file. Requires /api-setup-shared.
---

# api-add-query

Creates `{query-name}.query.ts` (query + handler) and `{query-name}.query.spec.ts` (in-memory test), then registers the handler.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}`.

## Steps

1. **Create folder** — `application/queries/{query-name}/`
   Name in kebab-case, read verb: `get-campaign-details`, `list-live-campaigns`, `get-user-balances`.

2. **Create query file** — `{query-name}.query.ts`
   Load [references/query-template.md](references/query-template.md) for the exact structure.

3. **Create test file** — `{query-name}.query.spec.ts`
   Load [references/test-template.md](references/test-template.md) for the exact structure.

4. **Register handler** — add `XxxQueryHandler` to the `queryHandlers` array in `application/{module}.module.ts`.

## Limitations

- Does not scaffold `InMemorySomeRepository` or `SomeBuilder` — run `/api-add-domain-entity` first.
- Logger injection is optional. Add `@InjectLogger()` if `BaseLogger` is available (see `/api-setup-shared`).
