---
description: Conventions for domain error classes — BaseDomainError hierarchy, user vs system errors
globs:
  - "**/domain/errors/**/*.ts"
  - "**/*.error.ts"
---

# Rules — Domain Errors

Applies to every domain error file (`*.error.ts`).

## Base error hierarchy

Every module defines a base error, and all module-specific errors extend it:

```ts
// domain/errors/order-base.error.ts
export abstract class OrderBaseError extends BaseDomainError {}

// domain/errors/order-not-found.error.ts
export class OrderNotFoundError extends OrderBaseError {
  readonly reportToMonitoring = false; // user error — 404

  constructor(orderId: string, correlationId: string) {
    super(`Order ${orderId} not found`, correlationId);
  }
}
```

## Error categorization

| Category | `reportToMonitoring` | HTTP mapping | Examples |
|----------|---------------------|--------------|----------|
| User error | `false` | 4xx (400, 404, 409, 422) | Not found, invalid input, conflict, insufficient balance |
| System error | `true` | 5xx (500) | Data inconsistency, unexpected state, config error |

## Rules

- **Extend `BaseDomainError`** — never `throw new Error(...)` in domain code
- **Include `correlationId`** — passed through from command props for tracing
- **`reportToMonitoring: false`** for user errors (expected business cases)
- **`reportToMonitoring: true`** for system errors (needs investigation)
- **Per-module base error** — `abstract class XxxBaseError extends BaseDomainError` in `domain/errors/{module}-base.error.ts`
- **Descriptive `errorCode`** — `readonly errorCode = "MODULE_ENTITY_TYPE"` (SCREAMING_SNAKE_CASE)
- **Include context in `metadata`** — IDs, involved values, anything useful for debugging

## Where to throw

- **Domain entities** — in business methods when invariants are violated
- **Command handlers** — when preconditions fail (e.g., entity not found)
- **Never in**: query handlers, repositories, mappers, or presentation layer

## Where to catch

- **Exception filters only** — `XxxExceptionFilter` maps domain errors to HTTP status codes
- **Never catch in controllers** with `try-catch` — let errors propagate to the filter

## File naming and location

- File: `{error-name}.error.ts` (kebab-case)
- Base: `{module}-base.error.ts`
- Location: `domain/errors/` within the module

## Prohibited

- No `throw new Error(...)` in domain — always use `BaseDomainError` subclasses
- No domain errors thrown in repositories or mappers (repos return `null` for not-found)
- No catching domain errors in controllers — exception filters handle mapping
- No imports from `infrastructure/`, `application/`, or `presentation/`
