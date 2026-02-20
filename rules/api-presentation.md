---
description: Conventions for presentation layer files in NestJS hexagonal modules
globs:
  - "**/presentation/**/*.ts"
---

# Rules — Presentation Layer

Applies to every file under `**/presentation/`.

## HTTP Controllers

- **`TypedCommandBus` and `TypedQueryBus`** — never the native NestJS buses
- **`@CorrelationId()`** — required decorator on all HTTP endpoints
- **Transform domain entities to DTOs** before returning in the response
- **Mapping layer only** — no business logic, no business validation
- **Logger child** — create in constructor with context (`moduleName`, `className`)

```ts
@ApiTags("xxx")
@Controller({ version: "1", path: "xxx" })
export class XxxController {
  private readonly logger: BaseLogger;

  constructor(
    private readonly queryBus: TypedQueryBus,
    private readonly commandBus: TypedCommandBus,
    @InjectLogger() logger: BaseLogger,
  ) {
    this.logger = logger.createChild({
      moduleName: "module-name",
      className: XxxController.name,
    });
  }

  @Get("/:id")
  @ApiOperation({ summary: "Get an xxx by ID" })
  @ApiParam({ name: "id", type: String, description: "Xxx identifier" })
  @ApiResponse({ status: 200, description: "Found", type: XxxResponseDto })
  @ApiResponse({ status: 404, description: "Not found", type: ErrorResponseDto })
  async getById(
    @Param() params: GetXxxParamsDto,
    @CorrelationId() correlationId: string, // REQUIRED
  ): Promise<XxxResponseDto> {
    const entity = await this.queryBus.execute(
      new GetXxxQuery({ id: params.id, correlationId }),
    );
    return { id: entity.id, name: entity.name }; // map domain → DTO here
  }

  @Post()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: "Create an xxx" })
  @ApiBody({ type: CreateXxxBodyDto })
  @ApiResponse({ status: 204, description: "Created successfully" })
  @ApiResponse({ status: 422, description: "Validation error", type: ErrorResponseDto })
  async create(
    @Body() body: CreateXxxBodyDto,
    @CorrelationId() correlationId: string,
  ): Promise<void> {
    await this.commandBus.execute(new CreateXxxCommand({ ...body, correlationId }));
  }
}
```

> **Logger note**: `@InjectLogger()` is a custom decorator wrapping `Inject(LOGGER_TOKEN)`.
> Replace with `new Logger(XxxController.name)` (NestJS native) or your own injection pattern.

## Exception filters

- **`extends BaseFeatureExceptionFilter<XxxBaseError>`** — override only `mapErrorToStatus()`
- **`@Catch(XxxBaseError)`** — catch the module's base error class
- **Check system errors (500) FIRST** — before user errors (4xx)
- **Fallback `INTERNAL_SERVER_ERROR`** at the end — indicates a bug or missing mapping
- **Register via `APP_FILTER`** in the NestJS module

```ts
@Catch(XxxBaseError)
export class XxxExceptionFilter extends BaseFeatureExceptionFilter<XxxBaseError> {
  protected mapErrorToStatus(error: XxxBaseError): number {
    // 500 first — system errors
    if (error instanceof XxxSystemError) return HttpStatus.INTERNAL_SERVER_ERROR;
    // 404 — resource not found
    if (error instanceof XxxNotFoundError) return HttpStatus.NOT_FOUND;
    // 409 — state conflict
    if (error instanceof XxxConflictError) return HttpStatus.CONFLICT;
    // 400 — bad client input
    if (error instanceof XxxBadRequestError) return HttpStatus.BAD_REQUEST;
    // 422 — invalid state
    if (error instanceof XxxInvalidStateError) return HttpStatus.UNPROCESSABLE_ENTITY;
    // Fallback — bug or missing mapping
    return HttpStatus.INTERNAL_SERVER_ERROR;
  }
}
```

## In-proc (cross-module facade)

- **Implement the interface** defined in the shared in-proc directory
- **Delegate to `TypedQueryBus`/`TypedCommandBus`** — never import handlers directly
- **Pass `correlationId`** on all operations
- **Log** incoming and outgoing operations with context

## DTOs

- **Validation with Zod** on request DTOs — NO `class-validator`, NO `class-transformer`
- **Simple types** on response DTOs (no domain entities)
- **Clear naming**: `XxxBodyDto`, `XxxParamsDto`, `XxxQueryDto`, `XxxResponseDto`

## OpenAPI

### Controller class

- **`@ApiTags('xxx')`** — required on every controller class; groups endpoints in the Swagger UI

### Endpoint methods

| Decorator | When required |
|-----------|--------------|
| `@ApiOperation({ summary })` | Every public endpoint — one-line human description |
| `@ApiResponse({ status, description, type })` | Every possible HTTP status the endpoint can return |
| `@ApiBody({ type: XxxBodyDto })` | Every `@Body()` parameter (NestJS may not infer it with custom pipes) |
| `@ApiParam({ name, type, description })` | Every `@Param()` path parameter |
| `@ApiQuery({ name, type, required, description })` | Every `@Query()` query parameter |

**Response types:**
- Success (2xx): `type` is the response DTO class (e.g. `type: XxxResponseDto`)
- Void commands: `@HttpCode(HttpStatus.NO_CONTENT)` + `@ApiResponse({ status: 204 })` (no `type`)
- All errors: `type: ErrorResponseDto` imported from `{SHARED_ROOT}/errors/base-feature-exception.filter`

### DTO properties

- **`@ApiProperty({ description, example })`** — required on every public property of every DTO class
- Request DTOs: keep `@ZodSchema(...)` on the class for validation; add `@ApiProperty()` per property for Swagger
- Response DTOs: plain class with `@ApiProperty()` — no Zod schema needed

```ts
// Request DTO
const CreateXxxBodySchema = z.object({ name: z.string().min(1).max(100) });

@ZodSchema(CreateXxxBodySchema)
export class CreateXxxBodyDto {
  @ApiProperty({ example: "My xxx", description: "Display name", minLength: 1, maxLength: 100 })
  name!: string;
}

// Response DTO
export class XxxResponseDto {
  @ApiProperty({ example: "550e8400-e29b-41d4-a716-446655440000" })
  id!: string;

  @ApiProperty({ example: "My xxx" })
  name!: string;
}
```

## Prohibited

- **No business logic** in controllers
- **No direct imports** of repositories or infrastructure services
- **No `try-catch`** for error handling (the exception filter handles it)
- **No domain entities** returned directly in the HTTP response
- **No native NestJS `CommandBus`/`QueryBus`** (use typed wrappers)
- **No public endpoint without `@ApiOperation`**
- **No `@ApiResponse` `type` pointing to a domain entity** — use response DTOs only
