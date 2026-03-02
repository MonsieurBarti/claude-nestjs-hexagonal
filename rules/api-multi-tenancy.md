---
description: Conventions for multi-tenancy and tenant-scoped dependency injection
globs:
  - "**/*.ts"
---

# Rules — Multi-Tenancy and Dependency Injection

Applies when implementing multi-tenant data isolation.

## Tenant context propagation

- **`ClsService`** (continuation-local storage) carries tenant context through the request
- **`TenantGuard`** middleware sets tenant slug from authentication/headers
- **Never hardcode tenant IDs** or pass them as function parameters across layers

```ts
// Correct — tenant from CLS:
const tenantSlug = this.cls.get<string>("tenantSlug");

// Wrong — hardcoded or parameter-passed:
const docs = await model.find({ tenantId: "acme" });
```

## Tenant-scoped data access (Mongoose)

Resolve tenant-scoped models dynamically via `TenantConnectionRegistry`:

```ts
private getModel() {
  const tenantSlug = this.cls.get<string>("tenantSlug");
  return this.registry.getModel<EventDocument>(
    tenantSlug,
    "events",
    EventSchema,
  );
}
```

## Tenant-scoped data access (Prisma)

For Prisma-based multi-tenancy, use tenant-scoped middleware or row-level security:

```ts
// Option 1: Prisma middleware that auto-filters by tenantId
// Option 2: Row-level security policies in PostgreSQL
// Option 3: Schema-per-tenant with dynamic datasource URL
```

## DI tokens

- **`Symbol()` for all tokens** — grouped in `{module}.tokens.ts`, never string literals
- Prevents cross-module collisions in multi-tenant setups

```ts
export const ORDER_TOKENS = {
  ORDER_REPOSITORY: Symbol("ORDER_ORDER_REPOSITORY"),
} as const;
```

## Public operations

- Mark resolver/controller operations that skip tenant validation with `@Public()` decorator

## Prohibited

- No hardcoded tenant IDs
- No tenant context passed as function parameters across layers (use CLS)
- No string-based DI tokens (use `Symbol()`)
- No shared/global collections accessed without tenant scoping
