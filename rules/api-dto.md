---
description: Conventions for DTO files in NestJS hexagonal modules
globs:
  - "**/presentation/dto/*.ts"
---

# Rules — DTOs

Applies to every file under `**/presentation/dto/`.

## Request DTOs

- **Zod schema in same file** — define `const XxxSchema = z.object({...})` above the class
- **`@ZodSchema(XxxSchema)`** — required decorator on the class for runtime validation
- **`@ApiProperty({ description, example })`** — required on every public property (for Swagger)
- **Property type from schema** — DTO properties must match the Zod schema fields exactly

```ts
export const CreateXxxBodySchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
});

@ZodSchema(CreateXxxBodySchema)
export class CreateXxxBodyDto {
  @ApiProperty({ example: "John Doe", description: "Display name", minLength: 1, maxLength: 100 })
  name!: string;

  @ApiProperty({ example: "john@example.com", description: "Email address" })
  email!: string;
}
```

## Response DTOs

- **No `@ZodSchema`** — response DTOs are output-only, no runtime validation needed
- **`@ApiProperty({ example })`** — required on every public property
- **Plain classes** — no Zod schema, no domain entity inheritance

```ts
export class XxxResponseDto {
  @ApiProperty({ example: "550e8400-e29b-41d4-a716-446655440000" })
  id!: string;

  @ApiProperty({ example: "John Doe" })
  name!: string;
}
```

## Naming conventions

| DTO type | Naming | When |
|----------|--------|------|
| Request body | `{Action}{Module}BodyDto` | `@Body()` parameter |
| Path params | `{Action}{Module}ParamsDto` | `@Param()` parameter |
| Query params | `{Action}{Module}QueryDto` | `@Query()` parameter |
| Response | `{Module}ResponseDto` | Return type |

Examples: `CreateUserBodyDto`, `GetUserParamsDto`, `ListUsersQueryDto`, `UserResponseDto`

## Zod schema naming

- Schema: `{ClassName}Schema` — e.g. `CreateUserBodySchema` matches `CreateUserBodyDto`
- Exported alongside the DTO class in the same file

## Prohibited

- **No domain entity imports** — DTOs must not reference domain types; map in the controller
- **No `class-validator`** — use Zod via `@ZodSchema()` only
- **No `class-transformer`** — plain property assignment in controller mapping
- **No `@ApiProperty()` without `example`** — every property needs a realistic example value
- **No `@ZodSchema` on response DTOs** — output classes are never validated
- **No DTO inheritance from domain classes** — DTOs are presentation-layer only
