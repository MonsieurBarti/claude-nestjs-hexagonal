---
name: api-add-endpoint
description: Adds a new HTTP endpoint to an existing controller — request/response DTOs,
  Swagger decorators, and command/query wiring. Use after the module, entity, and
  command/query already exist. Requires /api-setup-shared and /api-add-module.
---

# api-add-endpoint

Adds a new endpoint method to an existing controller with full DTO and Swagger support.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}`.

## Prerequisites

- Module already scaffolded (`/api-add-module`)
- Command or query already exists (`/api-add-command` or `/api-add-query`)
- Controller file exists at `presentation/controllers/{module}.controller.ts`
- DTO file exists at `presentation/dto/{module}.dto.ts`

## Steps

1. **Determine endpoint type** — command (write) or query (read)?
   - **Command** → `POST`, `PATCH`, `PUT`, or `DELETE` — returns `void` with `204 No Content`
   - **Query** → `GET` — returns a response DTO

2. **Add request DTO** — append to `presentation/dto/{module}.dto.ts`
   Load [references/dto-template.md](references/dto-template.md).
   - Zod schema + `@ZodSchema()` for request body/params/query
   - `@ApiProperty()` on every property
   - Follow naming: `{Action}{Module}BodyDto`, `{Action}{Module}ParamsDto`, `{Action}{Module}QueryDto`

3. **Add response DTO** (query endpoints only) — append to `presentation/dto/{module}.dto.ts`
   - Plain class with `@ApiProperty()` on every property
   - No `@ZodSchema` — output-only

4. **Add endpoint method** — append to the controller class
   Load [references/endpoint-template.md](references/endpoint-template.md).
   - `@CorrelationId()` parameter — required on every endpoint
   - Full Swagger decoration: `@ApiOperation`, `@ApiResponse`, `@ApiBody`/`@ApiParam`/`@ApiQuery`
   - Command endpoints: `@HttpCode(HttpStatus.NO_CONTENT)`
   - Add necessary imports at the top of the controller file

5. **Update exception filter** (if new error types) — add mappings to `{module}-exception.filter.ts`

## Limitations

- Does not create the command or query — run `/api-add-command` or `/api-add-query` first.
- Does not create integration tests — add manually following the `api-testing` rule.
- Does not modify route prefixes or versioning — assumes the controller already has `@Controller({ version, path })`.
