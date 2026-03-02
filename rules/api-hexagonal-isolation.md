---
description: Hexagonal layer isolation — dependency rule enforcement across 4 layers
globs:
  - "**/*.ts"
---

# Rules — Hexagonal Layer Isolation

Applies to all `.ts` files. Enforces the dependency rule in the 4-layer hexagonal architecture.

## Layer hierarchy

```
domain (innermost) → application → infrastructure → presentation (outermost)
```

**Dependency rule:** Outer layers depend on inner layers, never the reverse. Layers at the same level do not depend on each other.

## Domain layer (innermost core)

- **No imports from** `infrastructure/`, `application/`, or `presentation/`
- **No NestJS decorators** (`@Injectable`, `@Inject`) in domain files
- **No external libraries** except pure computation: `zod`, `decimal.js`, `node:crypto`
- **No framework or persistence logic** (Prisma, SQL, ConfigService, HTTP clients)
- **Dependencies via method parameters** — not constructor injection:

```ts
// Correct — dependency passed as parameter:
static createNew(name: string, dateProvider: IDateProvider): Order {
  return new Order(OrderPropsSchema.parse({
    id: randomUUID(),
    name,
    createdAt: dateProvider.now(),
  }));
}

// Wrong — NestJS DI in domain entity:
@Injectable()
export class Order {
  constructor(
    @Inject('DATE_PROVIDER')
    private readonly dateProvider: IDateProvider,
  ) {}
}
```

## Application layer

- May import from `domain/`
- **No imports from** `infrastructure/` or `presentation/`
- Uses **ports** (abstract classes/interfaces) defined in domain for infrastructure needs
- Orchestrates domain logic — does not implement business rules

## Infrastructure layer

- May import from `domain/` and `application/`
- **No imports from** `presentation/`
- Implements ports defined in domain (repository interfaces, reader interfaces)
- Returns **domain entities** — never exposes persistence models outside this layer

## Presentation layer (outermost)

- May import from `application/` (via buses) and `domain/` (for error types)
- **No direct imports** from `infrastructure/`
- Uses `TypedCommandBus`/`TypedQueryBus` — never accesses repositories directly
- Maps domain entities to DTOs — never returns domain entities in responses

## Repository contracts

Define as abstract classes in the domain layer, implement in infrastructure:

```ts
// domain/order/order.repository.ts — contract
export abstract class IOrderRepository {
  abstract save(order: Order): Promise<void>;
  abstract findById(id: string): Promise<Order | null>;
}

// infrastructure/order/sql-order.repository.ts — implementation
@Injectable()
export class SqlOrderRepository implements IOrderRepository {
  constructor(private readonly prisma: PrismaService) {}
  // ...
}
```

## Prohibited

- Inner layers importing from outer layers
- Same-level imports between unrelated modules (use in-proc facades or buses)
- NestJS decorators in domain entity files
- External libraries in domain (except `zod`, `decimal.js`, `node:crypto`)
- Persistence models leaked outside infrastructure
- Direct repository access from presentation layer
