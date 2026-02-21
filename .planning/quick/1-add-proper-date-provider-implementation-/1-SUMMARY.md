---
phase: quick
plan: "01"
subsystem: skills
tags: [date-provider, skill-docs, shared-infrastructure, testing]
dependency_graph:
  requires: []
  provides: [date-provider-reference, IDateProvider, DateProvider, FakeDateProvider]
  affects:
    - skills/api-setup-shared/SKILL.md
    - skills/api-init-project/SKILL.md
    - skills/api-add-domain-entity/SKILL.md
    - skills/api-add-domain-entity/references/entity-template.md
tech_stack:
  added: [date-fns]
  patterns:
    - abstract-class-as-di-token
    - fake-provider-test-pattern
    - domain-isolation-method-parameter
key_files:
  created:
    - skills/api-setup-shared/references/date-provider.md
  modified:
    - skills/api-setup-shared/SKILL.md
    - skills/api-init-project/SKILL.md
    - skills/api-add-domain-entity/SKILL.md
    - skills/api-add-domain-entity/references/entity-template.md
decisions:
  - "IDateProvider as abstract class (not TS interface) so it doubles as NestJS DI token — follows BaseLogger pattern, no separate Symbol() needed"
  - "FakeDateProvider placed in {SHARED_ROOT}/testing/ alongside InMemoryLogger and TestLoggerModule"
  - "DateProvider only wraps new Date() — date-fns used by consuming code (domain/application layer)"
  - "Domain entities receive IDateProvider as a method parameter in createNew() — not injected into entity class (domain isolation)"
metrics:
  duration: "~3 minutes"
  completed: "2026-02-21"
  tasks_completed: 2
  files_created: 1
  files_modified: 4
---

# Quick Plan 01: Add Proper Date Provider Implementation — Summary

One-liner: IDateProvider abstract class + DateProvider (real) + FakeDateProvider (test fake) added as skill reference templates, wired into api-setup-shared step 8d, api-init-project deps, and entity-template import.

## What Was Built

### Task 1: date-provider.md reference template

Created `skills/api-setup-shared/references/date-provider.md` following the same structure as `logger.md` and `domain-event.md`.

The reference file documents four artifacts:

1. **`{SHARED_ROOT}/date/date-provider.ts`** — `IDateProvider` abstract class. Uses abstract class (not TS interface) so it serves as both a type annotation and a NestJS DI token — no separate `Symbol()` needed.

2. **`{SHARED_ROOT}/date/date-provider.impl.ts`** — `DateProvider` real implementation. `@Injectable()`, wraps `new Date()`. date-fns is used by consuming code (not the provider itself).

3. **`{SHARED_ROOT}/testing/fake-date-provider.ts`** — `FakeDateProvider` test fake with `setCurrentDate()` and `advanceBy()` for deterministic time-sensitive tests. Default fixed date: `2024-01-15T10:00:00.000Z`.

4. **`{SHARED_ROOT}/date/index.ts`** — barrel exporting `IDateProvider` and `DateProvider`.

Commit: `2ebadf8`

### Task 2: Wire date provider into skill pipeline

Updated four existing files:

- **`skills/api-setup-shared/SKILL.md`**: Updated frontmatter description, added step 8d (DateProvider creation), updated step 15 (app.module.ts with `{ provide: IDateProvider, useClass: DateProvider }`), added limitation noting date-fns requirement.

- **`skills/api-init-project/SKILL.md`**: Added `date-fns` to the step 4 `pnpm add` production dependencies command.

- **`skills/api-add-domain-entity/SKILL.md`**: Replaced the orphaned "Does not scaffold IDateProvider" limitation with a pointer to `/api-setup-shared` and the method-parameter pattern.

- **`skills/api-add-domain-entity/references/entity-template.md`**: Added `import type { IDateProvider } from "{SHARED_ROOT}/date/date-provider"` to both the standard entity and AggregateRoot variants. Uses `type` import for domain isolation.

Commit: `2e4f4e1`

## Decisions Made

1. **Abstract class pattern for IDateProvider**: Follows `BaseLogger` precedent — the abstract class doubles as both a TypeScript type and NestJS injection token, eliminating the need for a separate `Symbol()`. This is more ergonomic and consistent with the existing codebase conventions.

2. **FakeDateProvider in `{SHARED_ROOT}/testing/`**: Collocated with other test infrastructure (`InMemoryLogger`, `TestLoggerModule`). Tests import from a well-known location.

3. **DateProvider only returns `new Date()`**: date-fns utilities belong in the consuming code (domain methods, command/query handlers), not in the provider itself. The provider's single responsibility is abstracting the system clock.

4. **`type` import in entity template**: Domain code uses `IDateProvider` only as a type annotation for the parameter in `createNew()` factories. Using `import type` enforces domain isolation and prevents accidental value usage.

## Deviations from Plan

None — plan executed exactly as written.

## Verification

- `grep -c "date-provider" skills/api-setup-shared/SKILL.md` → 4 (at least 2 required)
- `grep "date-fns" skills/api-init-project/SKILL.md` → match in step 4
- `grep "IDateProvider.*api-setup-shared" skills/api-add-domain-entity/SKILL.md` → match
- `grep "IDateProvider" skills/api-add-domain-entity/references/entity-template.md` → import lines in both variants

## Self-Check

### Files created/modified
- `skills/api-setup-shared/references/date-provider.md` — FOUND (created by Task 1)
- `skills/api-setup-shared/SKILL.md` — FOUND (updated by Task 2)
- `skills/api-init-project/SKILL.md` — FOUND (updated by Task 2)
- `skills/api-add-domain-entity/SKILL.md` — FOUND (updated by Task 2)
- `skills/api-add-domain-entity/references/entity-template.md` — FOUND (updated by Task 2)

### Commits
- `2ebadf8` — feat(quick-01): add date-provider.md reference template
- `2e4f4e1` — feat(quick-01): wire date provider into skill pipeline

## Self-Check: PASSED
