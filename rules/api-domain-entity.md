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
- **`Decimal.js`** — required for all financial arithmetic (never `number` for monetary amounts):
  ```ts
  import { Decimal } from "decimal.js";

  // In Zod schema — accept string/number input, validate as Decimal
  const AmountSchema = z.union([z.string(), z.number()]).transform((val) => new Decimal(val));

  // In entity — store as Decimal, expose via getter
  private readonly _amount: Decimal;
  public get amount(): Decimal { return this._amount; }

  // In toJSON — serialize as string (avoids floating-point issues)
  public toJSON() { return { amount: this._amount.toString() }; }

  // In mapper — convert between Prisma Decimal and domain Decimal
  // toDomain:  new Decimal(raw.amount.toString())
  // toPersistence: new PrismaDecimal(entity.amount.toString())
  ```
- **IDs** — use `randomUUID()` from `node:crypto` in creation factory methods

## Repository and reader interfaces

- **Reader** (`{entity}.reader.ts`) — read-only, methods like `findById`, `findAll`, etc.
- **Repository** (`{entity}.repository.ts`) — read + write, `save()` method required
- Interfaces contain only signatures, no logic

## Aggregate boundaries

- **Only reference aggregate roots from outside** — inner entities and value objects are accessed exclusively through the root
- **Cross-aggregate references by ID only** — never hold direct object references to other aggregate roots:
  ```ts
  // Correct — reference by ID:
  type OrderProps = {
    id: string;
    customerId: string;   // ID reference
    warehouseId: string;  // ID reference
  };

  // Wrong — direct object reference:
  type OrderProps = {
    id: string;
    customer: Customer;   // tight coupling
    warehouse: Warehouse; // breaks aggregate boundary
  };
  ```
- **Access inner entities through root methods** — never reach into aggregate internals directly:
  ```ts
  // Correct:
  order.removeItem(itemId);
  order.updateItemQuantity(itemId, 3);

  // Wrong:
  const item = order.items.find(i => i.id === itemId);
  item.quantity = 3; // bypasses invariant checks
  ```

## No anemic domain model

Entities must contain business logic as named methods — not just hold state with getters:

```ts
// Rich entity — logic inside:
cancel(reason: string): void {
  if (this.props.status !== OrderStatus.ACTIVE) {
    throw new OrderNotActiveError(this.id);
  }
  this.props.status = OrderStatus.CANCELLED;
  this.apply(new OrderCancelledEvent({ aggregateId: this.id, reason }));
}

// Anemic — logic leaked to handler:
// order.status = 'CANCELLED'; // public setter, no validation
```

## Domain errors

See dedicated rule: `api-domain-error` — domain errors have their own conventions file.

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
- No external libraries in domain except pure computation: `zod`, `decimal.js`, `node:crypto` — abstract all other dependencies through ports
- No public setters — mutate via named business methods only (avoid anemic model)
- No direct object references to other aggregate roots — use ID references
