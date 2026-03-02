---
description: Conventions for GraphQL presentation layer — resolvers, union return types, typed buses
globs:
  - "**/presentation/resolvers/**/*.ts"
  - "**/*.resolver.ts"
---

# Rules — GraphQL Presentation Layer

Applies to GraphQL resolver files.

## Resolvers

- **`TypedCommandBus` and `TypedQueryBus`** — never the native NestJS `CommandBus`/`QueryBus`
- **`correlationId`** via `this.cls.getId() ?? randomUUID()` — required on every operation
- **Return `@ObjectType` instances** — never domain entities or raw documents
- **No business logic** — resolvers are mapping + dispatch only

```ts
@Resolver()
export class OrderResolver {
  constructor(
    private readonly commandBus: TypedCommandBus,
    private readonly queryBus: TypedQueryBus,
    private readonly cls: ClsService,
  ) {}

  @Query(() => OrderType, { nullable: true })
  async order(@Args("id") id: string): Promise<OrderType | null> {
    const correlationId = this.cls.getId() ?? randomUUID();
    const result = await this.queryBus.execute(
      new GetOrderQuery({ id, correlationId }),
    );
    if (!result) return null;
    const type = new OrderType();
    type.id = result.id;
    type.name = result.name;
    return type;
  }
}
```

## Mutations — union return types

Return `createUnionType` combining success and error types instead of throwing exceptions:

```ts
export const CreateOrderResult = createUnionType({
  name: "CreateOrderResult",
  types: () => [CreateOrderSuccess, OrderAlreadyExistsErrorType] as const,
});

@Mutation(() => CreateOrderResult)
async createOrder(
  @Args("input") input: CreateOrderInput,
): Promise<typeof CreateOrderResult> {
  const correlationId = this.cls.getId() ?? randomUUID();
  try {
    await this.commandBus.execute(
      new CreateOrderCommand({ ...input, correlationId }),
    );
    const success = new CreateOrderSuccess();
    success.id = input.id;
    return success;
  } catch (err: unknown) {
    if (err instanceof OrderAlreadyExistsError) {
      const error = new OrderAlreadyExistsErrorType();
      error.message = err.message;
      return error;
    }
    throw err;
  }
}
```

## DTOs

- All `@ObjectType`, `@InputType`, and union types in `presentation/dto/{module}.dto.ts`
- Not in resolver files

## Prohibited

- No business logic in resolvers
- No direct repository access
- No REST decorators (`@Controller`, `@Get`) in resolver files
- No domain entities returned from resolvers
- No exception filters for GraphQL errors — use union return types
- No native NestJS `CommandBus`/`QueryBus`
