---
description: Conventions for domain services — stateless cross-aggregate business logic
globs:
  - "**/domain/services/**/*.ts"
---

# Rules — Domain Services

Applies to domain service files in `**/domain/services/`.

## When to use

Domain services encapsulate business logic that:
- Spans **multiple aggregates** (e.g., transferring between two wallets)
- Involves **complex calculations** across entities (e.g., pricing with discounts)
- Does **not naturally belong** in a single entity

If the logic only touches one aggregate, put it in the entity method instead.

## Structure

```ts
// domain/services/transfer.service.ts
export class TransferService {
  execute(from: Wallet, to: Wallet, amount: Money): void {
    from.debit(amount);
    to.credit(amount);
  }
}
```

## Rules

- **Stateless** — receive all data as method parameters, never store mutable state
- **Domain layer only** — no imports from `infrastructure/`, `application/`, or `presentation/`
- **No infrastructure dependencies** — no `PrismaService`, no `ConfigService`, no HTTP clients
- **Dependencies via ports** — if external data is needed, accept a port interface as a constructor parameter
- **Injected into command handlers** — called from the application layer, never from controllers or repositories

## Usage in command handler

```ts
@CommandHandler(TransferFundsCommand)
export class TransferFundsHandler implements ICommandHandler<TransferFundsCommand, void> {
  constructor(
    @Inject(TOKENS.WALLET_REPOSITORY)
    private readonly walletRepo: IWalletRepository,
    private readonly transferService: TransferService,
  ) {}

  async execute({ props }: TransferFundsCommand): Promise<void> {
    const from = await this.walletRepo.findById(props.fromWalletId);
    const to = await this.walletRepo.findById(props.toWalletId);
    this.transferService.execute(from, to, Money.create(props.amount));
    await this.walletRepo.save(from);
    await this.walletRepo.save(to);
  }
}
```

## File naming and location

- File: `{name}.service.ts` (kebab-case)
- Location: `domain/services/` within the module

## Prohibited

- No mutable state across calls — services are stateless
- No infrastructure imports (`PrismaService`, `ConfigService`, HTTP clients)
- No NestJS decorators in the service class itself (injected by handler, not by DI)
- No single-entity logic — that belongs in entity methods
