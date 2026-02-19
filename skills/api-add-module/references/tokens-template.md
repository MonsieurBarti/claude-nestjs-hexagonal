# DI tokens template

File: `{module-name}.tokens.ts`

```ts
export const {MODULE_UPPER}_TOKENS = {
  // Repositories (for aggregates owned by this module)
  SOME_REPOSITORY: Symbol("{MODULE_UPPER}_SOME_REPOSITORY"),
  // Readers (for external or read-only data)
  // SOME_READER: Symbol("{MODULE_UPPER}_SOME_READER"),
  // Event publisher
  // EVENT_PUBLISHER: Symbol("{MODULE_UPPER}_EVENT_PUBLISHER"),
} as const;
```
