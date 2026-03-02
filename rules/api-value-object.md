---
description: Conventions for domain value objects — immutable, no identity, equality by attributes
globs:
  - "**/domain/**/*.ts"
---

# Rules — Value Objects

Applies to value object files in `**/domain/`.

## Structure

- **Private constructor** — same pattern as entities, validated by Zod schema
- **Static `create()` factory** — cannot exist in an invalid state
- **All fields `readonly`** — value objects are immutable after creation
- **No identity** — no `id` field; equality is determined by attributes, not reference

```ts
import { z } from "zod";

const EmailSchema = z.object({
  value: z.string().email(),
});
type EmailProps = z.infer<typeof EmailSchema>;

export class Email {
  private constructor(private readonly props: EmailProps) {}

  static create(value: string): Email {
    return new Email(EmailSchema.parse({ value }));
  }

  get value(): string {
    return this.props.value;
  }

  equals(other: Email): boolean {
    return this.props.value === other.value;
  }

  toJSON(): string {
    return this.props.value;
  }
}
```

## Rules

- **`equals()` method required** — compare all attributes, never use reference equality (`===` on objects)
- **Immutable transformations** — return new instances instead of mutating internal state:
  ```ts
  add(other: Money): Money {
    if (this.props.currency !== other.currency) {
      throw new CurrencyMismatchError(this.props.currency, other.currency);
    }
    return Money.create({
      amount: this.props.amount.plus(other.props.amount),
      currency: this.props.currency,
    });
  }
  ```
- **Replace primitives** — use value objects for domain concepts (Email, Money, Address, PhoneNumber) instead of raw `string` or `number`
- **`toJSON()` method** — return a plain serializable representation for persistence and transport
- **Shareable** — value objects can be freely used across aggregates since they are immutable

## In entity props

```ts
// Use value objects, not primitives:
type OrderProps = {
  id: string;
  customerEmail: Email;
  totalAmount: Money;
  shippingAddress: Address;
};

// Not:
type OrderProps = {
  id: string;
  customerEmail: string; // primitive — no validation
  totalAmount: number; // floating point — loses precision
  shippingAddress: string; // no structure
};
```

## File naming and location

- File: `{name}.value-object.ts` (kebab-case)
- Location: `domain/value-objects/` within the module

## Prohibited

- No mutable fields — all properties `readonly`
- No identity (`id`) — value objects are defined by their attributes
- No NestJS decorators (`@Injectable`, `@Inject`)
- No imports from `infrastructure/`, `application/`, or `presentation/`
