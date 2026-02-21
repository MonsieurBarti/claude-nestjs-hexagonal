# DateProvider

Creates `{SHARED_ROOT}/date/date-provider.ts`, `{SHARED_ROOT}/date/date-provider.impl.ts`,
`{SHARED_ROOT}/testing/fake-date-provider.ts`, and `{SHARED_ROOT}/date/index.ts`.

## date-provider.ts — abstract interface

File: `{SHARED_ROOT}/date/date-provider.ts`

```ts
export abstract class IDateProvider {
  abstract now(): Date;
}
```

`IDateProvider` is an abstract class (not a TypeScript interface) so it serves as both a
type annotation and a NestJS injection token — no separate `Symbol()` token is needed.
This follows the same pattern as `BaseLogger`.

## date-provider.impl.ts — real implementation

File: `{SHARED_ROOT}/date/date-provider.impl.ts`

```ts
import { Injectable } from "@nestjs/common";
import { IDateProvider } from "./date-provider";

@Injectable()
export class DateProvider extends IDateProvider {
  now(): Date {
    return new Date();
  }
}
```

## fake-date-provider.ts — test fake

File: `{SHARED_ROOT}/testing/fake-date-provider.ts`

```ts
import { IDateProvider } from "../date/date-provider";

export class FakeDateProvider extends IDateProvider {
  private currentDate: Date;

  constructor(fixedDate?: Date) {
    super();
    this.currentDate = fixedDate ?? new Date("2024-01-15T10:00:00.000Z");
  }

  now(): Date {
    return this.currentDate;
  }

  setCurrentDate(date: Date): void {
    this.currentDate = date;
  }

  advanceBy(ms: number): void {
    this.currentDate = new Date(this.currentDate.getTime() + ms);
  }
}
```

`FakeDateProvider` supports:
- Fixed date at construction (defaults to `2024-01-15T10:00:00.000Z` for deterministic tests)
- Mid-test date override via `setCurrentDate()`
- Time advancement via `advanceBy(ms)` for testing time-sensitive logic

## index.ts — barrel

File: `{SHARED_ROOT}/date/index.ts`

```ts
export { IDateProvider } from "./date-provider";
export { DateProvider } from "./date-provider.impl";
```

## Usage notes

`DateProvider` itself only wraps `new Date()`. date-fns is available for date arithmetic
in domain/application code that consumes dates from the provider (formatting, comparison,
add/subtract). Import date-fns utilities directly in the consuming code — not in the provider.

## Design notes

- `IDateProvider` is an abstract class — doubles as both a TypeScript type and a NestJS DI token.
  No separate `Symbol()` is needed for injection.
- `DateProvider` is registered globally in `src/app.module.ts` (see step 15 of api-setup-shared).
  Domain code receives it as a method parameter in `createNew()` factories — it is NOT injected
  into the entity class itself (domain isolation).
- `FakeDateProvider` lives in `{SHARED_ROOT}/testing/` alongside other test helpers
  (`InMemoryLogger`, `TestLoggerModule`) — import it in unit and integration tests only.
- date-fns is available for date arithmetic in consuming code — installed by `/api-init-project`.
