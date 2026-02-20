---
name: api-add-module
description: Scaffolds a complete NestJS hexagonal module with all 4 layers — domain,
  application, infrastructure, presentation. Use when starting a new bounded context
  or feature module. Requires /api-setup-shared.
---

# api-add-module

Full scaffold of a new NestJS hexagonal module following the 4-layer architecture.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}`.

## Prerequisites

Verify shared base classes exist before starting:
- `{SHARED_ROOT}/cqrs/typed-command.ts`
- `{SHARED_ROOT}/cqrs/typed-query.ts`
- `{SHARED_ROOT}/errors/base-domain.error.ts`
- `{SHARED_ROOT}/errors/base-feature-exception.filter.ts`

If any are missing, run `/api-setup-shared` first.

## Steps

1. **Create folder structure** under `{MODULE_ROOT}/{module-name}/`:
   ```
   application/commands/   application/queries/
   domain/errors/
   infrastructure/
   presentation/controllers/   presentation/dto/   presentation/in-proc/
   ```

2. **DI tokens** — `{module-name}.tokens.ts`
   Load [references/tokens-template.md](references/tokens-template.md).

3. **Domain errors** — `domain/errors/`
   Load [references/domain-errors-template.md](references/domain-errors-template.md).
   For entities: run `/api-add-domain-entity`.

4. **Application module** — `application/{module-name}.module.ts`
   Load [references/application-module-template.md](references/application-module-template.md).

5. **Infrastructure layer** — for each aggregate, run `/api-add-domain-entity` (steps 5–7).

6. **Presentation layer** — exception filter, controller, DTOs, optional in-proc facade
   Load [references/presentation-template.md](references/presentation-template.md).

7. **Root module** — `{module-name}.module.ts`
   Load [references/root-module-template.md](references/root-module-template.md).

8. **Register** — add `{ModuleName}Module` to `imports` in the app root module.

## Limitations

- Does not create Prisma schema or migrations — add models to `schema.prisma` and run `prisma migrate dev`.
- Does not scaffold domain events or BullMQ processors — add manually as needed.
- In-proc interface path (`{SHARED_ROOT}/in-proc/`) may differ per project — adjust accordingly.
