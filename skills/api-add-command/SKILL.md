---
name: api-add-command
description: Creates a CQRS command + handler + in-memory test in a NestJS hexagonal
  module. Use when adding a write operation (state change) to a module. Command and
  handler live in the same file. Requires /api-setup-shared.
---

# api-add-command

Creates `{command-name}.command.ts` (command + handler) and `{command-name}.command.spec.ts` (in-memory test), then registers the handler.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}`.

## Steps

1. **Create folder** — `application/commands/{command-name}/`
   Name in kebab-case, imperative verb: `join-campaign`, `create-order`, `cancel-subscription`.

2. **Create command file** — `{command-name}.command.ts`
   Load [references/command-template.md](references/command-template.md) for the exact structure.

3. **Create test file** — `{command-name}.command.spec.ts`
   Load [references/test-template.md](references/test-template.md) for the exact structure.
   If using `BaseLogger`, pass `new InMemoryLogger()` as the second constructor argument.

4. **Register handler** — add `XxxCommandHandler` to the `commandHandlers` array in `application/{module}.module.ts`.

## Limitations

- Does not scaffold `InMemorySomeRepository` or `SomeBuilder` — run `/api-add-domain-entity` first.
- Logger injection is optional. If not using `BaseLogger`, use NestJS native `Logger` or omit.
