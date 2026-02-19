# .claude/CLAUDE.md template

File: `.claude/CLAUDE.md` (in the new NestJS project)

Substitute `{app-name}` with the actual application name (e.g. `my-api`).

---

```markdown
@plugins/hexagonal/CLAUDE.md

# {app-name} — Project Guide

## Configuration

Skills read these values from this file:
```
SHARED_ROOT: src/shared
MODULE_ROOT: src/modules
```

## Stack

- **Framework**: NestJS + `@nestjs/cqrs`
- **Validation**: Zod — NO `class-validator`, NO `class-transformer`
- **ORM**: Prisma with `@prisma/client`
- **Logger**: `nestjs-pino` via `BaseLogger` (created by `/api-setup-shared`)
- **Tests**: Vitest + `@faker-js/faker` — test files live next to source (`*.spec.ts`)
- **Package manager**: pnpm

## Architecture

4-layer hexagonal: `domain → application → infrastructure → presentation`

All modules live under `src/modules/{module-name}/`. Shared base classes live under `src/shared/`.

### Layer responsibilities

| Layer | Responsibility | Imports allowed from |
|-------|---------------|----------------------|
| `domain` | Entities, repository interfaces, domain errors | Nothing (pure TypeScript) |
| `application` | Commands, queries, application modules | `domain`, `shared` |
| `infrastructure` | Prisma repositories, mappers, in-memory doubles | `domain`, `shared` |
| `presentation` | HTTP controllers, DTOs, exception filters, in-proc facades | `domain`, `application`, `shared` |

### Module structure

```
src/modules/{module}/
├── application/
│   ├── commands/{name}/{name}.command.ts
│   ├── queries/{name}/{name}.query.ts
│   └── {module}.module.ts
├── domain/
│   ├── {aggregate}/{aggregate}.ts
│   ├── {aggregate}/{aggregate}.repository.ts
│   ├── {aggregate}/{aggregate}.builder.ts     # tests only
│   └── errors/{module}-base.error.ts
├── infrastructure/
│   ├── {aggregate}/sql-{aggregate}.repository.ts
│   ├── {aggregate}/in-memory-{aggregate}.repository.ts
│   └── {aggregate}/sql-{aggregate}.mapper.ts
├── presentation/
│   ├── controllers/{module}.controller.ts
│   ├── dto/{module}.dto.ts
│   └── in-proc/{module}.in-proc.ts
├── {module}-exception.filter.ts
├── {module}.tokens.ts
└── {module}.module.ts
```

### Shared structure (after `/api-setup-shared`)

```
src/shared/
├── cqrs/
│   ├── typed-command.ts
│   ├── typed-query.ts
│   └── index.ts
├── errors/
│   ├── base-domain.error.ts
│   ├── base-feature-exception.filter.ts
│   └── index.ts
└── logger/
    ├── logger.ts
    ├── pino-logger.ts
    ├── inject-logger.decorator.ts
    ├── in-memory-logger.ts
    ├── app-logger.module.ts
    └── index.ts
```

## Critical invariants

| Rule | Detail |
|------|--------|
| `correlationId: string` | Required in every command/query props and domain error |
| `super()` | Required in every command/query constructor |
| `props` | Property name is always `props` — never `payload`, `data`, or anything else |
| `Symbol()` tokens | DI tokens are always Symbols, never string literals |
| Domain isolated | Domain layer has zero imports from `infrastructure/`, `application/`, or `presentation/` |
| Domain errors | `extends BaseDomainError`, `reportToMonitoring: false` (user error) or `true` (system error) |
| Commands | `extends TypedCommand<void>` — never return data |
| Queries | `extends TypedQuery<TResult>` — no side effects, no mutations |
| Handler colocation | Command handler lives in the same file as the command class. Same for queries. |
| No buses in handlers | Handlers never inject `CommandBus` or `QueryBus` |
| No try-catch for logging | The exception filter handles all domain errors automatically |

## CQRS command pattern

```ts
// application/commands/{name}/{name}.command.ts
export type XxxCommandProps = {
  someField: string;
  correlationId: string; // REQUIRED
};

export class XxxCommand extends TypedCommand<void> {
  constructor(public readonly props: XxxCommandProps) {
    super(); // REQUIRED
  }
}

@CommandHandler(XxxCommand)
export class XxxCommandHandler implements ICommandHandler<XxxCommand, void> {
  async execute({ props }: XxxCommand): Promise<void> {
    // business logic — no return value
  }
}

export const commandHandlers = [XxxCommandHandler];
```

## CQRS query pattern

```ts
// application/queries/{name}/{name}.query.ts
export type XxxQueryProps = {
  someId: string;
  correlationId: string; // REQUIRED
};

export type XxxQueryResult = SomeDomainEntity | null;

export class XxxQuery extends TypedQuery<XxxQueryResult> {
  constructor(public readonly props: XxxQueryProps) {
    super(); // REQUIRED
  }
}

@QueryHandler(XxxQuery)
@Injectable()
export class XxxQueryHandler implements IQueryHandler<XxxQuery, XxxQueryResult> {
  async execute({ props }: XxxQuery): Promise<XxxQueryResult> {
    // read only — return domain entity, controller maps to DTO
  }
}

export const queryHandlers = [XxxQueryHandler];
```

## Domain entity pattern

```ts
// domain/{entity}/{entity}.ts
export class SomeEntity {
  private constructor(private props: SomeEntityProps) {}

  public static create(props: SomeEntityProps): SomeEntity {
    const validated = SomeEntityPropsSchema.parse(props);
    return new SomeEntity(validated);
  }

  get id(): string { return this.props.id; }
  // ... other getters

  toJSON(): SomeEntityProps { return { ...this.props }; }
}
```

## Domain error pattern

```ts
// domain/errors/{module}-base.error.ts
export abstract class {ModuleName}Error extends BaseDomainError {}

export class SomeNotFoundError extends {ModuleName}Error {
  readonly errorCode = "MODULE_SOME_NOT_FOUND";
  constructor(options: { correlationId: string; someId: string }) {
    super("Some entity not found", {
      reportToMonitoring: false,
      correlationId: options.correlationId,
      metadata: { someId: options.someId },
    });
  }
}
```

## Logger pattern

```ts
private readonly logger: BaseLogger;

constructor(
  @Inject(MODULE_TOKENS.SOME_DEPENDENCY)
  private readonly dep: ISomeDependency,
  @InjectLogger() logger: BaseLogger,
) {
  this.logger = logger.createChild({
    moduleName: "module-name",
    className: XxxHandler.name,
  });
}
```

## Available skills

Run these in order for a new project or feature:

| Skill | When to use |
|-------|-------------|
| `/api-setup-shared` | Once per project — creates `TypedCommand`, `TypedQuery`, `BaseLogger`, `BaseDomainError` |
| `/api-add-module` | Once per feature module — scaffolds all 4 layers |
| `/api-add-domain-entity` | Once per aggregate — creates entity, repository interface, builder, SQL + in-memory implementations |
| `/api-add-command` | Once per write operation — creates command + handler + test |
| `/api-add-query` | Once per read operation — creates query + handler + test |

## Database commands

```bash
pnpm db:migrate        # prisma migrate dev — creates and applies a new migration
pnpm db:migrate:prod   # prisma migrate deploy — applies pending migrations in production
pnpm db:studio         # opens Prisma Studio GUI
pnpm db:generate       # regenerates the Prisma client after schema changes
pnpm db:reset          # drops and recreates the database (dev only)
```

## Test commands

```bash
pnpm test              # run all tests once
pnpm test:watch        # watch mode
pnpm test:cov          # run with coverage report (lcov + text)
```

## Development commands

```bash
pnpm start:dev         # start with hot reload (watch mode)
pnpm build             # compile to dist/
pnpm start:prod        # run compiled output (requires pnpm build first)
```

## Rules reference

Per-layer constraints auto-load when editing matching files:
- [api-cqrs-shared](rules/api-cqrs-shared.md) — `*.command.ts` + `*.query.ts` shared invariants
- [api-command](rules/api-command.md) — `*.command.ts`
- [api-query](rules/api-query.md) — `*.query.ts`
- [api-domain-entity](rules/api-domain-entity.md) — `**/domain/**/*.ts`
- [api-infrastructure-repository](rules/api-infrastructure-repository.md) — `**/infrastructure/**/*.ts`
- [api-presentation](rules/api-presentation.md) — `**/presentation/**/*.ts`
```
