# Repository interface template

File: `domain/{entity-name}/{entity-name}.repository.ts`

```ts
export interface IXxxRepository {
  save(entity: Xxx): Promise<void>;
  findById(id: string): Promise<Xxx | null>;
  // other necessary methods...
}
```

## Read-only reader variant

File: `domain/{entity-name}/{entity-name}.reader.ts`

```ts
export interface IXxxReader {
  findById(id: string): Promise<Xxx | null>;
  findAll(): Promise<Xxx[]>;
  // query methods only — no mutations
}
```
