# In-memory repository template

File: `infrastructure/{entity-name}/in-memory-{entity-name}.repository.ts`

```ts
import { Injectable } from "@nestjs/common";
import { IXxxRepository } from "../../domain/{entity-name}/{entity-name}.repository";
import { Xxx } from "../../domain/{entity-name}/{entity-name}";

@Injectable()
export class InMemoryXxxRepository implements IXxxRepository {
  private readonly store = new Map<string, Xxx>();

  async save(entity: Xxx): Promise<void> { this.store.set(entity.id, entity); }
  async findById(id: string): Promise<Xxx | null> { return this.store.get(id) ?? null; }

  // Test helpers
  public clear(): void { this.store.clear(); }
  public getAll(): Xxx[] { return Array.from(this.store.values()); }
  public count(): number { return this.store.size; }
}
```
