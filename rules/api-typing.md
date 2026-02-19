---
description: Global TypeScript typing conventions — strict mode, no `any` type, no `enum` keyword
globs:
  - "**/*.ts"
---

# Rules — TypeScript Typing Conventions

Applies to every `.ts` file in the project.

## Strict TypeScript configuration

`tsconfig.json` **must** have `"strict": true`. This enables the full strict suite:

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitOverride": true,
    "noUncheckedIndexedAccess": true
  }
}
```

- **`strict: true`** — enables `strictNullChecks`, `noImplicitAny`, `strictFunctionTypes`, `strictPropertyInitialization`, `noImplicitThis`, `useUnknownInCatchVariables`, and `alwaysStrict` in one flag
- **`noImplicitOverride: true`** — requires `override` keyword when overriding a base class method (prevents accidental overrides)
- **`noUncheckedIndexedAccess: true`** — array/object index access returns `T | undefined` instead of `T` (prevents off-by-one and missing-key bugs)

> `nest new` generates individual flags (`strictNullChecks`, `noImplicitAny`) instead of `"strict": true`. Replace them with the block above after scaffolding.

## No `any`

The `any` type is **always prohibited** in all its forms — annotations, casts, and generics. Biome enforces this via `noExplicitAny`. When TypeScript can't infer a type, pick the appropriate alternative:

```ts
// ❌ All prohibited

// Type annotation
function process(data: any): any { ... }

// Cast
const result = someValue as any;

// Generic parameter
const items: Array<any> = [];
const map: Record<string, any> = {};
```

Alternatives:

- **`z.infer<typeof Schema>`** — derive the type from a Zod schema (preferred for domain props and DTOs):
  ```ts
  const UserSchema = z.object({ id: z.string(), name: z.string() });
  type User = z.infer<typeof UserSchema>;
  ```

- **`unknown` + type narrowing** — for catch blocks, external JSON, or event payloads; narrow with `instanceof` or `typeof`:
  ```ts
  try {
    return schema.parse(value);
  } catch (error) {
    if (error instanceof z.ZodError) throw new CustomZodValidationException(error);
    throw error;
  }
  ```

- **`Record<string, unknown>`** — for arbitrary key-value maps (replaces `Record<string, any>`):
  ```ts
  const metadata: Record<string, unknown> = {};
  ```

- **Generic type parameters** — make functions generic rather than annotating with `any`:
  ```ts
  function wrap<T>(value: T): { data: T } {
    return { data: value };
  }
  ```

- **`as unknown as TargetType`** — last resort when two concrete types are structurally compatible at runtime but TypeScript can't prove it. Always add a comment explaining why:
  ```ts
  // FastifyRequest is guaranteed by the platform adapter — safe downcast at runtime
  const req = rawRequest as unknown as FastifyRequest;
  ```

## No TypeScript `enum`

The `enum` keyword is **prohibited**. Use `z.enum()` instead — it is the single source of truth for both runtime validation and the TypeScript type.

```ts
// ❌ Never
enum OrderStatus {
  PENDING = "PENDING",
  CONFIRMED = "CONFIRMED",
  CANCELLED = "CANCELLED",
}

// ✅ Define once with z.enum
const OrderStatusSchema = z.enum(["PENDING", "CONFIRMED", "CANCELLED"]);

// ✅ Derive the TypeScript union type
type OrderStatus = z.infer<typeof OrderStatusSchema>;
// → "PENDING" | "CONFIRMED" | "CANCELLED"

// ✅ Access individual values as a const object (replaces MyEnum.VALUE pattern)
const OrderStatus = OrderStatusSchema.Values;
// OrderStatus.PENDING → "PENDING"

// ✅ Compose into other Zod schemas
const OrderSchema = z.object({
  status: OrderStatusSchema,
  // ...
});
```

**Naming convention:**
- Zod schema: `{Name}Schema` — e.g. `OrderStatusSchema`
- TypeScript type: `{Name}` — e.g. `type OrderStatus = z.infer<typeof OrderStatusSchema>`
- Const values object: `{Name}` — e.g. `const OrderStatus = OrderStatusSchema.Values`

TypeScript allows a `type` and a `const` to share the same name in the same file.

**Importing:** Use `import type` when the identifier is only used as a type at the call site:
```ts
import type { OrderStatus } from "./order-status";
```

## Prohibited

- `any` in any form — type annotations (`: any`), casts (`as any`), generics (`Array<any>`, `Record<string, any>`); Biome enforces `noExplicitAny` as an error
- `enum` keyword — use `z.enum([...])` + `.Values` instead
- `// @ts-ignore` and `// @ts-expect-error` — fix the root cause rather than silencing the compiler
