---
name: api-add-event-handler
description: Creates a domain event handler that reacts to events from another module
  (or the same module). Includes handler class and unit test. Use after domain events
  have been created with /api-add-domain-entity.
---

# api-add-event-handler

Creates a domain event handler in the application layer. Event handlers react to domain events published by repositories after DB writes.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}`.

## Steps

1. **Create handler** — `application/event-handlers/{action}-when-{event}.event-handler.ts`
   Load [references/event-handler-template.md](references/event-handler-template.md).
   - Class name: `{Action}When{Event}Handler` (e.g., `CreateWalletWhenUserCreatedHandler`)
   - Decorate with `@EventsHandler(XxxEvent)`
   - Implement `IEventHandler<XxxEvent>` with `handle(event)` method
   - Inject dependencies via `@Inject(TOKEN)` — same pattern as command handlers

2. **Create unit test** — `application/event-handlers/{action}-when-{event}.event-handler.spec.ts`
   Load [references/test-template.md](references/test-template.md).
   - Test using in-memory repositories
   - Construct the event directly and pass to `handler.handle(event)`
   - Assert on side effects (created entities, state changes)

3. **Register handler** — add the handler class to `application/{module-name}.module.ts` providers array.
   List the handler directly — no barrel file.

## Limitations

- Does not create the domain event itself — events are created by `/api-add-domain-entity`.
- Event handlers are application-layer only — no HTTP/presentation logic.
- Cross-module event handlers: the handler module does NOT need to import the source module — only import the event class directly from the source module's domain layer.
