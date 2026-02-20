# Query + Handler templates

File: `application/queries/{query-name}/{query-name}.query.ts`

Choose the variant that fits the use case. See `rules/api-query.md` for guidance.

---

## Standard — single item or flat list

Use for single-item lookups (`get-xxx-by-id`) or flat lists (`list-xxx`).

```ts
import { QueryHandler, IQueryHandler } from "@nestjs/cqrs";
import { TypedQuery } from "{SHARED_ROOT}/cqrs/typed-query";
import { Injectable } from "@nestjs/common";
import { PrismaService } from "{SHARED_ROOT}/prisma/prisma.service";

// Read model — plain typed object (not a domain entity, not a DTO class)
export type XxxReadModel = {
  id: string;
  // projected fields only — do NOT include sensitive columns
};

// Props type
export type XxxQueryProps = {
  someId: string;
  correlationId: string; // REQUIRED
};

// Result type
export type XxxQueryResult = XxxReadModel | null;

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
  constructor(private readonly prisma: PrismaService) {}

  async execute({ props }: XxxQuery): Promise<XxxQueryResult> {
    return this.prisma.xxx.findUnique({
      where: { id: props.someId },
      select: { id: true, /* projected fields */ },
    });
  }
}
```

> Register by adding `XxxQueryHandler` to the `providers` array in
> `application/{module-name}.module.ts` (see `/api-add-query` Step 5).

---

## Paginated — list with pagination

Use for paginated list endpoints (`list-xxx`, `search-xxx`).
Import pagination types from `{SHARED_ROOT}/cqrs/paginated-query.base`.

```ts
import { QueryHandler, IQueryHandler } from "@nestjs/cqrs";
import { TypedQuery } from "{SHARED_ROOT}/cqrs/typed-query";
import {
  PaginatedParams,
  PaginatedQueryParams,
  PaginatedResult,
} from "{SHARED_ROOT}/cqrs/paginated-query.base";
import { Injectable } from "@nestjs/common";
import { PrismaService } from "{SHARED_ROOT}/prisma/prisma.service";

// Read model
export type XxxReadModel = {
  id: string;
  // projected fields only
};

// Props: pagination fields are optional (defaults applied in constructor)
export type ListXxxQueryProps = PaginatedParams<PaginatedQueryParams> & {
  correlationId: string; // REQUIRED
  // additional filter fields
};

// Result type
export type ListXxxQueryResult = PaginatedResult<XxxReadModel>;

// Query class — extends TypedQuery<TResult> only (TypeScript allows one extends)
// Pagination fields are set inline mirroring PaginatedQueryBase constructor logic
export class ListXxxQuery extends TypedQuery<ListXxxQueryResult> {
  readonly limit: number;
  readonly offset: number;
  readonly page: number;
  readonly orderBy: { field: string; direction: "asc" | "desc" };

  constructor(public readonly props: ListXxxQueryProps) {
    super(); // REQUIRED
    this.limit = props.limit ?? 20;
    this.page = props.page ?? 1;
    this.offset = this.page > 0 ? (this.page - 1) * this.limit : 0;
    this.orderBy = props.orderBy ?? { field: "createdAt", direction: "desc" };
  }
}

// Handler — use execute(query) not execute({ props }) to access pagination fields
@QueryHandler(ListXxxQuery)
@Injectable()
export class ListXxxQueryHandler
  implements IQueryHandler<ListXxxQuery, ListXxxQueryResult>
{
  constructor(private readonly prisma: PrismaService) {}

  async execute(query: ListXxxQuery): Promise<ListXxxQueryResult> {
    const where = { /* filter from query.props */ };

    const [rows, total] = await this.prisma.$transaction([
      this.prisma.xxx.findMany({
        where,
        take: query.limit,
        skip: query.offset,
        orderBy: { [query.orderBy.field]: query.orderBy.direction } as Record<string, "asc" | "desc">,
        select: { id: true, /* projected fields */ },
      }),
      this.prisma.xxx.count({ where }),
    ]);

    return { data: rows, total, page: query.page, limit: query.limit };
  }
}
```

> Register by adding `ListXxxQueryHandler` to the `providers` array in
> `application/{module-name}.module.ts` (see `/api-add-query` Step 5).
