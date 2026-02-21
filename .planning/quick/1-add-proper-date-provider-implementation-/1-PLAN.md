---
phase: 1-add-proper-date-provider-implementation
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - skills/api-setup-shared/references/date-provider.md
  - skills/api-setup-shared/SKILL.md
  - skills/api-init-project/SKILL.md
  - skills/api-add-domain-entity/SKILL.md
  - skills/api-add-domain-entity/references/entity-template.md
autonomous: true
requirements: [DATE-01]

must_haves:
  truths:
    - "IDateProvider interface exists as a shared reference template with now() method"
    - "DateProvider real implementation uses date-fns and is injectable"
    - "FakeDateProvider allows setting a fixed date for deterministic tests"
    - "api-setup-shared SKILL.md includes a step to create the date provider files"
    - "api-init-project SKILL.md mentions date-fns as a dependency to install"
    - "Entity template imports IDateProvider from the shared date path"
  artifacts:
    - path: "skills/api-setup-shared/references/date-provider.md"
      provides: "Reference template for IDateProvider, DateProvider, FakeDateProvider, DI token, barrel"
    - path: "skills/api-setup-shared/SKILL.md"
      provides: "Updated skill with new step for date provider creation"
    - path: "skills/api-init-project/SKILL.md"
      provides: "Updated limitations/deps mentioning date-fns"
    - path: "skills/api-add-domain-entity/SKILL.md"
      provides: "Updated limitations removing orphan IDateProvider mention"
    - path: "skills/api-add-domain-entity/references/entity-template.md"
      provides: "Updated entity template with IDateProvider import from shared"
  key_links:
    - from: "skills/api-setup-shared/SKILL.md"
      to: "skills/api-setup-shared/references/date-provider.md"
      via: "Step reference link"
      pattern: "references/date-provider\\.md"
    - from: "skills/api-add-domain-entity/references/entity-template.md"
      to: "{SHARED_ROOT}/date/date-provider.ts"
      via: "import statement in template"
      pattern: "IDateProvider.*shared/date"
---

<objective>
Add IDateProvider interface, DateProvider (date-fns) real implementation, and FakeDateProvider (test fake) as reference templates in the api-setup-shared skill, then wire all related skills to reference it.

Purpose: Entities already use `IDateProvider` in their `createNew()` factories (see entity-template.md) but the interface and implementations do not exist as skill-generated artifacts. This closes that gap.

Output: One new reference file (date-provider.md), updates to three SKILL.md files and one reference template.
</objective>

<execution_context>
@/Users/monsieurbarti/.claude/get-shit-done/workflows/execute-plan.md
@/Users/monsieurbarti/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@skills/api-setup-shared/SKILL.md
@skills/api-setup-shared/references/logger.md
@skills/api-setup-shared/references/domain-event.md
@skills/api-init-project/SKILL.md
@skills/api-add-domain-entity/SKILL.md
@skills/api-add-domain-entity/references/entity-template.md
@rules/api-domain-entity.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create date-provider.md reference template</name>
  <files>skills/api-setup-shared/references/date-provider.md</files>
  <action>
Create `skills/api-setup-shared/references/date-provider.md` following the same structure as existing reference files (see `logger.md` or `domain-event.md` for pattern).

The file must contain these sections:

**1. date-provider.ts -- abstract interface**
File: `{SHARED_ROOT}/date/date-provider.ts`

```ts
export abstract class IDateProvider {
  abstract now(): Date;
}
```

Use an abstract class (not a TS interface) so it can serve as both a type AND a NestJS injection token without a separate Symbol. This follows the same pattern as `BaseLogger` (abstract class used as both interface and DI token).

**2. date-provider.impl.ts -- real implementation**
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

Note: date-fns is available for date manipulation in consuming code (commands, queries, domain methods). The real provider itself just returns `new Date()` -- date-fns utilities are used by code that receives dates from the provider (formatting, comparison, add/subtract). Mention this in a "Usage notes" section.

**3. fake-date-provider.ts -- test fake**
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

The `FakeDateProvider` allows: setting a fixed date at construction, changing the date mid-test with `setCurrentDate()`, and advancing time with `advanceBy()`.

**4. Barrel -- date/index.ts**
File: `{SHARED_ROOT}/date/index.ts`

```ts
export { IDateProvider } from "./date-provider";
export { DateProvider } from "./date-provider.impl";
```

**5. Design notes section** at the bottom explaining:
- `IDateProvider` is an abstract class (not interface) so it doubles as a DI token -- no separate Symbol needed
- `DateProvider` is registered in the root module; domain code receives it as a method parameter (not injected)
- `FakeDateProvider` lives in `{SHARED_ROOT}/testing/` alongside other test helpers (InMemoryLogger, TestLoggerModule)
- date-fns is available for date arithmetic in domain/application code that consumes dates from the provider
  </action>
  <verify>
File exists at `skills/api-setup-shared/references/date-provider.md`. Contains all four code blocks (date-provider.ts, date-provider.impl.ts, fake-date-provider.ts, index.ts). No use of `any` type. Abstract class pattern for IDateProvider (not TS interface).
  </verify>
  <done>Reference template file contains IDateProvider abstract class, DateProvider real impl, FakeDateProvider test fake with setCurrentDate/advanceBy, barrel export, and design notes.</done>
</task>

<task type="auto">
  <name>Task 2: Update SKILL.md files to wire date provider into the skill pipeline</name>
  <files>
    skills/api-setup-shared/SKILL.md
    skills/api-init-project/SKILL.md
    skills/api-add-domain-entity/SKILL.md
    skills/api-add-domain-entity/references/entity-template.md
  </files>
  <action>
**A. Update `skills/api-setup-shared/SKILL.md`:**

1. Update the `description` in the frontmatter to include "IDateProvider + DateProvider + FakeDateProvider" in the list.

2. Add a new step **8d** (after 8c SqlRepositoryBase, before step 9 TypedCommandBus):

```
8d. **DateProvider** — `{SHARED_ROOT}/date/date-provider.ts`, `{SHARED_ROOT}/date/date-provider.impl.ts`, `{SHARED_ROOT}/testing/fake-date-provider.ts`
    Load [references/date-provider.md](references/date-provider.md).
    Creates `IDateProvider` abstract class (doubles as DI token), `DateProvider` real implementation,
    `FakeDateProvider` test fake, and `{SHARED_ROOT}/date/index.ts` barrel.
```

3. In step 15 (Update `src/app.module.ts`), add `DateProvider` registration to providers:
```ts
import { IDateProvider } from "./shared/date/date-provider";
import { DateProvider } from "./shared/date/date-provider.impl";

// In providers array, add:
{ provide: IDateProvider, useClass: DateProvider },
```

4. Add a new limitation line:
```
- `DateProvider` requires `date-fns` for date manipulation in consuming code — installed by `/api-init-project`.
```

**B. Update `skills/api-init-project/SKILL.md`:**

In step 4 (Install production dependencies), add `date-fns` to the `pnpm add` command:
```bash
pnpm add @nestjs/cqrs @nestjs/platform-fastify fastify @fastify/static nestjs-pino pino-http pino-pretty zod @prisma/client @nestjs/swagger date-fns
```

**C. Update `skills/api-add-domain-entity/SKILL.md`:**

Replace the last limitation line:
```
- Does not scaffold `IDateProvider` — inject it as needed for `createNew()` factories.
```
With:
```
- `IDateProvider` is created by `/api-setup-shared` — pass it as a parameter to `createNew()` factories (domain code does not use DI).
```

**D. Update `skills/api-add-domain-entity/references/entity-template.md`:**

In both the standard entity and AggregateRoot variants, add an import comment near the top of each code block showing where `IDateProvider` comes from:

```ts
import type { IDateProvider } from "{SHARED_ROOT}/date/date-provider";
```

Add this import to both template variants (standard and AggregateRoot) right after the existing imports. Use `type` import since domain code only uses it as a type annotation for the parameter.
  </action>
  <verify>
1. `grep -c "date-provider" skills/api-setup-shared/SKILL.md` returns at least 2 matches (step + limitation).
2. `grep "date-fns" skills/api-init-project/SKILL.md` returns a match in step 4.
3. `grep "IDateProvider.*api-setup-shared" skills/api-add-domain-entity/SKILL.md` returns a match.
4. `grep "IDateProvider" skills/api-add-domain-entity/references/entity-template.md` returns import lines.
  </verify>
  <done>All four SKILL/reference files updated: api-setup-shared has step 8d + app.module provider + limitation, api-init-project installs date-fns, api-add-domain-entity references IDateProvider from shared with proper import.</done>
</task>

</tasks>

<verification>
- All reference template code blocks compile conceptually (no `any`, no `enum`, abstract class pattern)
- IDateProvider uses abstract class pattern consistent with BaseLogger
- FakeDateProvider lives in `{SHARED_ROOT}/testing/` consistent with InMemoryLogger and TestLoggerModule
- Entity template imports use `type` import (domain isolation)
- date-fns added to api-init-project production dependencies
- Step numbering in api-setup-shared is consistent (8d follows 8c)
</verification>

<success_criteria>
- Reference template `date-provider.md` exists with IDateProvider, DateProvider, FakeDateProvider, and barrel
- api-setup-shared SKILL.md has step 8d creating date provider files and app.module registration
- api-init-project SKILL.md installs date-fns
- api-add-domain-entity entity template imports IDateProvider from shared
- api-add-domain-entity limitations updated to reference api-setup-shared
</success_criteria>

<output>
After completion, create `.planning/quick/1-add-proper-date-provider-implementation-/1-SUMMARY.md`
</output>
