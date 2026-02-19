---
description: Conventions for CQRS query files in NestJS hexagonal modules
globs:
  - "**/*.query.ts"
---

# Rules — CQRS Queries

Applies to every `*.query.ts` file in a NestJS hexagonal module.

## File structure (query + handler in the SAME file)

```ts
// Props type
export type XxxQueryProps = {
  // business fields...
  correlationId: string; // REQUIRED
};

// Explicit return type
export type XxxQueryResult = SomeDomainType | SomeDomainType[] | null;

// Query class
export class XxxQuery extends TypedQuery<XxxQueryResult> {
  constructor(public readonly props: XxxQueryProps) {
    super(); // REQUIRED
  }
}

// Handler in the same file
@QueryHandler(XxxQuery)
@Injectable() // REQUIRED on query handlers
export class XxxQueryHandler implements IQueryHandler<XxxQuery, XxxQueryResult> {
  constructor(
    @Inject(MODULE_TOKENS.SOME_REPOSITORY)
    private readonly someRepository: ISomeRepository,
  ) {}

  async execute({ props }: XxxQuery): Promise<XxxQueryResult> {
    const { correlationId } = props;
    const result = await this.someRepository.findById(props.id);
    if (!result) {
      throw new XxxNotFoundError({ correlationId, id: props.id });
    }
    return result; // Return domain entity — controller transforms to DTO
  }
}
```

## Mandatory rules

- **`extends TypedQuery<TResult>`** — the return type must be explicit and precise
- **`props` required** — never `payload`, `data`, or any other name
- **`correlationId: string`** — required field in `XxxQueryProps`
- **`super()`** — required in the constructor
- **`@Injectable()`** — required decorator on the query handler
- **Handler in the same file** — no separate `*.query.handler.ts` file
- **No side effects** — queries read only, they never mutate state
- **`execute({ props }: XxxQuery)`** — destructure props in the signature
- **Return domain entities** — the controller is responsible for mapping to DTOs

## Prohibited

- **No `CommandBus` or `QueryBus` injected** in a query handler
- **No writes** to the database or state mutation in a query handler
- **No `try-catch` just for logging**
- **No DTO transformation** in the handler — return domain entities directly

## Registration

Export the handler in the `queryHandlers` array in `application/{module}.module.ts`:
```ts
export const queryHandlers = [
  XxxQueryHandler,
];
```
