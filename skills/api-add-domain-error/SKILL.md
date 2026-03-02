---
name: api-add-domain-error
description: Adds a new domain error to an existing module — extends the module base
  error, sets error code and monitoring flag, and updates the exception filter mapping.
  Use when a command or query needs to throw a new business error. Requires /api-add-module.
---

# api-add-domain-error

Adds a new domain error class and wires it into the exception filter.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}`.

## Prerequisites

- Module already scaffolded (`/api-add-module`)
- Base error exists at `domain/errors/{module}-base.error.ts`
- Exception filter exists at `presentation/{module}-exception.filter.ts`

## Steps

1. **Determine error category**:
   - **User error** → `reportToMonitoring: false` — bad input, not found, conflict, invalid state (4xx)
   - **System error** → `reportToMonitoring: true` — data inconsistency, external service failure, bugs (5xx)

2. **Create error class** — append to `domain/errors/{module}.errors.ts`
   - Extend the module base error
   - `errorCode` in `SCREAMING_SNAKE_CASE`: `{MODULE}_{ENTITY}_{TYPE}` (e.g., `USER_EMAIL_ALREADY_EXISTS`)
   - Include `correlationId` and relevant IDs in constructor options
   - Include useful context in `metadata`

   **User error template (reportToMonitoring: false):**
   ```ts
   export class {Entity}NotFoundError extends {Module}Error {
     readonly errorCode = "{MODULE_UPPER}_{ENTITY_UPPER}_NOT_FOUND";
     constructor(options: { correlationId?: string; {entity}Id: string }) {
       super(`{Entity} ${options.{entity}Id} not found`, {
         reportToMonitoring: false,
         correlationId: options.correlationId,
         metadata: { {entity}Id: options.{entity}Id },
       });
     }
   }
   ```

   **Conflict error template:**
   ```ts
   export class {Entity}AlreadyExistsError extends {Module}Error {
     readonly errorCode = "{MODULE_UPPER}_{ENTITY_UPPER}_ALREADY_EXISTS";
     constructor(options: { correlationId?: string; {uniqueField}: string }) {
       super(`{Entity} with {uniqueField} ${options.{uniqueField}} already exists`, {
         reportToMonitoring: false,
         correlationId: options.correlationId,
         metadata: { {uniqueField}: options.{uniqueField} },
       });
     }
   }
   ```

   **Invalid state error template:**
   ```ts
   export class {Entity}InvalidStateError extends {Module}Error {
     readonly errorCode = "{MODULE_UPPER}_{ENTITY_UPPER}_INVALID_STATE";
     constructor(options: { correlationId?: string; {entity}Id: string; currentState: string; attemptedAction: string }) {
       super(`Cannot ${options.attemptedAction} {entity} ${options.{entity}Id} in state ${options.currentState}`, {
         reportToMonitoring: false,
         correlationId: options.correlationId,
         metadata: { {entity}Id: options.{entity}Id, currentState: options.currentState, attemptedAction: options.attemptedAction },
       });
     }
   }
   ```

   **System error template (reportToMonitoring: true):**
   ```ts
   export class {Entity}DataInconsistencyError extends {Module}Error {
     readonly errorCode = "{MODULE_UPPER}_{ENTITY_UPPER}_DATA_INCONSISTENCY";
     constructor(options: { correlationId?: string; {entity}Id: string; details: string }) {
       super(`Data inconsistency for {entity} ${options.{entity}Id}: ${options.details}`, {
         reportToMonitoring: true,
         correlationId: options.correlationId,
         metadata: { {entity}Id: options.{entity}Id, details: options.details },
       });
     }
   }
   ```

   **Exception filter mapping (add to `mapErrorToStatus()`):**
   ```ts
   // System errors FIRST (500)
   if (error instanceof {Entity}DataInconsistencyError) return HttpStatus.INTERNAL_SERVER_ERROR;
   // User errors
   if (error instanceof {Entity}NotFoundError) return HttpStatus.NOT_FOUND;
   if (error instanceof {Entity}AlreadyExistsError) return HttpStatus.CONFLICT;
   if (error instanceof {Entity}InvalidStateError) return HttpStatus.UNPROCESSABLE_ENTITY;
   ```

3. **Update barrel export** — ensure `domain/errors/index.ts` re-exports the errors file

4. **Update exception filter** — add mapping in `presentation/{module}-exception.filter.ts`
   - System errors (500): add BEFORE user errors
   - User errors: add with appropriate HTTP status

   | Error type | HTTP status |
   |-----------|-------------|
   | Not found | `404 NOT_FOUND` |
   | Already exists / conflict | `409 CONFLICT` |
   | Bad input | `400 BAD_REQUEST` |
   | Invalid state | `422 UNPROCESSABLE_ENTITY` |
   | Forbidden | `403 FORBIDDEN` |
   | System / data inconsistency | `500 INTERNAL_SERVER_ERROR` |

5. **Add import** in the exception filter file for the new error class

## Limitations

- Does not create the module base error — run `/api-add-module` first.
- Does not add the `throw` statement in command/query handlers — add manually.
