---
description: Conventions for CQRS query files in NestJS hexagonal modules
globs:
  - "**/*.query.ts"
---

# Rules — CQRS Queries

Applies to every `*.query.ts` file. Shared CQRS invariants (props naming, correlationId, super(), execute destructuring, handler colocation, no buses, no try-catch, logger pattern) are in `api-cqrs-shared`.

## Query-specific rules

- **`extends TypedQuery<TResult>`** — the return type must be explicit and precise
- **`@Injectable()`** — required decorator on the query handler
- **No side effects** — queries read only, they never mutate state
- **Return domain entities** — the controller is responsible for mapping to DTOs

## Prohibited

- **No writes** to the database or state mutation in a query handler
- **No DTO transformation** in the handler — return domain entities directly

## File structure

```ts
export type XxxQueryProps = {
  // business fields...
  correlationId: string;
};

export type XxxQueryResult = SomeDomainType | SomeDomainType[] | null;

export class XxxQuery extends TypedQuery<XxxQueryResult> {
  constructor(public readonly props: XxxQueryProps) {
    super();
  }
}

@QueryHandler(XxxQuery)
@Injectable()
export class XxxQueryHandler implements IQueryHandler<XxxQuery, XxxQueryResult> {
  async execute({ props }: XxxQuery): Promise<XxxQueryResult> {
    return result; // Return domain entity — controller transforms to DTO
  }
}
```

## Registration

```ts
export const queryHandlers = [XxxQueryHandler];
```
