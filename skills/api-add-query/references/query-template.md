# Query + Handler template

File: `application/queries/{query-name}/{query-name}.query.ts`

```ts
import { QueryHandler, IQueryHandler } from "@nestjs/cqrs";
import { TypedQuery } from "{SHARED_ROOT}/cqrs/typed-query";
import { Inject, Injectable } from "@nestjs/common";
import { MODULE_TOKENS } from "../../{module}.tokens";
import type { ISomeRepository } from "../../domain/{aggregate}/{aggregate}.repository";
import { SomeNotFoundError } from "../../domain/errors";
import type { SomeDomainType } from "../../domain/{aggregate}/{aggregate}";

// 1. Props type
export type XxxQueryProps = {
  someId: string;
  correlationId: string; // REQUIRED
};

// 2. Explicit return type
export type XxxQueryResult = SomeDomainType;
// or: SomeDomainType[] | null | { data: SomeDomainType[]; total: number }

// 3. Query class
export class XxxQuery extends TypedQuery<XxxQueryResult> {
  constructor(public readonly props: XxxQueryProps) {
    super(); // REQUIRED
  }
}

// 4. Handler in the same file
@QueryHandler(XxxQuery)
@Injectable() // REQUIRED on query handlers
export class XxxQueryHandler implements IQueryHandler<XxxQuery, XxxQueryResult> {
  constructor(
    @Inject(MODULE_TOKENS.SOME_REPOSITORY)
    private readonly someRepository: ISomeRepository,
  ) {}

  async execute({ props }: XxxQuery): Promise<XxxQueryResult> {
    const { someId, correlationId } = props;

    const entity = await this.someRepository.findById(someId);
    if (!entity) {
      throw new SomeNotFoundError({ correlationId, someId });
    }

    return entity; // Return domain entity — controller transforms to DTO
  }
}
```
