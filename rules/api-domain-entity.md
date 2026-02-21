---
description: Conventions for domain layer files in NestJS hexagonal modules
globs:
  - "**/domain/**/*.ts"
---

# Rules — Domain Layer

Applies to every file under `**/domain/`.

## Entities

- **Private constructor** — use `private constructor(props: XxxProps)`
- **Factory method** — expose `public static create(props: XxxProps): Xxx` with Zod validation:
  ```ts
  public static create(props: XxxProps): Xxx {
    try {
      const validated = XxxPropsSchema.parse(props);
      return new Xxx(validated);
    } catch (error) {
      if (error instanceof ZodError) throw error;
      throw error;
    }
  }
  ```
- **`private readonly` fields** — mutable fields for state transitions may be `private` without `readonly`
- **Getters only** — no public setters; mutations go through named business methods
- **`toJSON()`** — provide a serialization method returning the `XxxProps` type
- **Dependencies via parameters** — business methods receive dependencies as arguments (e.g. `isLive(dateProvider: IDateProvider)`)
- **`Decimal.js`** — required for all financial arithmetic (never `number` for monetary amounts)
- **IDs** — use `randomUUID()` from `node:crypto` in creation factory methods

## Repository and reader interfaces

- **Reader** (`{entity}.reader.ts`) — read-only, methods like `findById`, `findAll`, etc.
- **Repository** (`{entity}.repository.ts`) — read + write, `save()` method required
- Interfaces contain only signatures, no logic

## Domain errors

- Create one base class per module: `abstract class XxxModuleError extends BaseDomainError`
- Each error: `readonly errorCode = "MODULE_ENTITY_TYPE"` (SCREAMING_SNAKE_CASE)
- `reportToMonitoring: false` for user errors (bad input, invalid state)
- `reportToMonitoring: true` for system errors (data inconsistency, bug, invalid config)
- Always include useful context in `metadata` (IDs, involved values)
- Never `throw new Error(...)` in the domain — always use `BaseDomainError` instances

## Builders (tests only)

- File `{entity}.builder.ts` in the same folder as the entity
- Realistic default values using `@faker-js/faker`
- Fluent pattern: `withXxx(value): Builder { this.xxx = value; return this; }`
- Semantic preset methods: `asActiveEntity()`, `asExpiredEntity()`, etc.
- Method `build(): Entity` and optionally `buildProps(): EntityProps`

## Entities with domain events

- Extend `AggregateRoot` from `@nestjs/cqrs` + call `super()` in constructor
- Use `this.apply(new XxxEvent(...))` in creation factories + business methods
- `create()` (reconstitution from DB) does NOT emit events
- `createNew()` (new entity) DOES emit events
- Events are collected internally, published by the repository after DB write
- Domain events live in `domain/events/` — see `api-domain-event` rule

## Prohibited

- No imports from `infrastructure/`, `application/`, or `presentation/`
- No NestJS decorators (`@Injectable`, `@Inject`) in pure domain code
- No persistence logic (Prisma, SQL) in entities
- No dependency on `ConfigService` or NestJS services
