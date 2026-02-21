---
description: Global TypeScript typing conventions — strict mode, no `any` type, no `enum` keyword, no `as` casting
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
const OrderStatus = OrderStatusSchema.enum;
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
- Const values object: `{Name}` — e.g. `const OrderStatus = OrderStatusSchema.enum`

TypeScript allows a `type` and a `const` to share the same name in the same file.

**Importing:** Use `import type` when the identifier is only used as a type at the call site:
```ts
import type { OrderStatus } from "./order-status";
```

## No `as` casting

Type assertions (`as`) are **prohibited in all forms** — including `as unknown as T`. They bypass the type system and hide bugs that generics, type guards, or `satisfies` would catch at compile time.

```ts
// ❌ All prohibited
const req = rawRequest as FastifyRequest;
const id = value as string;
const user = data as unknown as User;
const config = {} as AppConfig;
```

Alternatives:

- **`satisfies`** — validates that a value conforms to a type without widening:
  ```ts
  const config = {
    port: 3000,
    host: "localhost",
  } satisfies AppConfig;
  ```

- **Type guards** — narrow types at runtime with full type safety:
  ```ts
  function isFastifyRequest(req: unknown): req is FastifyRequest {
    return typeof req === "object" && req !== null && "raw" in req;
  }
  ```

- **Generics** — let TypeScript infer or constrain the type:
  ```ts
  function getRepository<T>(token: symbol): T {
    return module.get<T>(token);
  }
  ```

- **`z.infer<>`** — derive types from Zod schemas instead of casting parsed results:
  ```ts
  const result = schema.parse(input); // already typed as z.infer<typeof schema>
  ```

- **Function overloads** — provide multiple call signatures instead of casting return types:
  ```ts
  function parse(input: string): number;
  function parse(input: string[]): number[];
  function parse(input: string | string[]): number | number[] {
    return Array.isArray(input) ? input.map(Number) : Number(input);
  }
  ```

## Prohibited

- `any` in any form — type annotations (`: any`), casts (`as any`), generics (`Array<any>`, `Record<string, any>`); Biome enforces `noExplicitAny` as an error
- `as` in any form — type assertions (`as X`), double casts (`as unknown as X`), const assertions (`as const` is the sole exception, allowed for literal types)
- `enum` keyword — use `z.enum([...])` + `.enum` instead
- `// @ts-ignore` and `// @ts-expect-error` — fix the root cause rather than silencing the compiler
