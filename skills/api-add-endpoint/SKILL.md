---
name: api-add-endpoint
description: Adds a new HTTP endpoint to an existing controller — request/response DTOs,
  Swagger decorators, and command/query wiring. Use after the module, entity, and
  command/query already exist. Requires /api-setup-shared and /api-add-module.
---

# api-add-endpoint

Adds a new endpoint method to an existing controller with full DTO and Swagger support.

## Project context

Read the `## Configuration` section in `.claude/CLAUDE.md` for `{SHARED_ROOT}` and `{MODULE_ROOT}`.

## Prerequisites

- Module already scaffolded (`/api-add-module`)
- Command or query already exists (`/api-add-command` or `/api-add-query`)
- Controller file exists at `presentation/controllers/{module}.controller.ts`
- DTO file exists at `presentation/dto/{module}.dto.ts`

## Steps

1. **Determine endpoint type** — command (write) or query (read)?
   - **Command** → `POST`, `PATCH`, `PUT`, or `DELETE` — returns `void` with `204 No Content`
   - **Query** → `GET` — returns a response DTO

2. **Add request DTO** — append to `presentation/dto/{module}.dto.ts`
   - Zod schema + `@ZodSchema()` for request body/params/query
   - `@ApiProperty()` on every property
   - Follow naming: `{Action}{Module}BodyDto`, `{Action}{Module}ParamsDto`, `{Action}{Module}QueryDto`

   **Request body DTO template:**
   ```ts
   export const {Action}{Entity}BodySchema = z.object({
     name: z.string().min(1).max(100),
   });

   @ZodSchema({Action}{Entity}BodySchema)
   export class {Action}{Entity}BodyDto {
     @ApiProperty({ example: "My entity", description: "Display name", minLength: 1, maxLength: 100 })
     name!: string;
   }
   ```

   **Path params DTO template:**
   ```ts
   export const Get{Entity}ParamsSchema = z.object({
     id: z.string().uuid(),
   });

   @ZodSchema(Get{Entity}ParamsSchema)
   export class Get{Entity}ParamsDto {
     @ApiProperty({ example: "550e8400-e29b-41d4-a716-446655440000", description: "{Entity} identifier" })
     id!: string;
   }
   ```

   **Query params DTO template (pagination):**
   ```ts
   export const List{Entity}QuerySchema = z.object({
     page: z.coerce.number().int().positive().optional(),
     limit: z.coerce.number().int().positive().max(100).optional(),
   });

   @ZodSchema(List{Entity}QuerySchema)
   export class List{Entity}QueryDto {
     @ApiProperty({ example: 1, description: "Page number", required: false })
     page?: number;

     @ApiProperty({ example: 20, description: "Items per page", required: false })
     limit?: number;
   }
   ```

3. **Add response DTO** (query endpoints only) — append to `presentation/dto/{module}.dto.ts`
   - Plain class with `@ApiProperty()` on every property
   - No `@ZodSchema` — output-only

   ```ts
   export class {Entity}ResponseDto {
     @ApiProperty({ example: "550e8400-e29b-41d4-a716-446655440000" })
     id!: string;

     @ApiProperty({ example: "My entity" })
     name!: string;

     @ApiProperty({ example: "2025-01-15T10:30:00.000Z" })
     createdAt!: string;
   }
   ```

4. **Add endpoint method** — append to the controller class
   - `@CorrelationId()` parameter — required on every endpoint
   - Full Swagger decoration: `@ApiOperation`, `@ApiResponse`, `@ApiBody`/`@ApiParam`/`@ApiQuery`
   - Command endpoints: `@HttpCode(HttpStatus.NO_CONTENT)`
   - Add necessary imports at the top of the controller file

   **Command endpoint (POST — 204):**
   ```ts
   @Post()
   @HttpCode(HttpStatus.NO_CONTENT)
   @ApiOperation({ summary: "Create a {entity}" })
   @ApiBody({ type: Create{Entity}BodyDto })
   @ApiResponse({ status: 204, description: "Created successfully" })
   @ApiResponse({ status: 422, description: "Validation error", type: ErrorResponseDto })
   async create(
     @Body() body: Create{Entity}BodyDto,
     @CorrelationId() correlationId: string,
   ): Promise<void> {
     await this.commandBus.execute(new Create{Entity}Command({ ...body, correlationId }));
   }
   ```

   **Command endpoint (PATCH — 204):**
   ```ts
   @Patch("/:id")
   @HttpCode(HttpStatus.NO_CONTENT)
   @ApiOperation({ summary: "Update a {entity}" })
   @ApiParam({ name: "id", type: String, description: "{Entity} identifier" })
   @ApiBody({ type: Update{Entity}BodyDto })
   @ApiResponse({ status: 204, description: "Updated successfully" })
   @ApiResponse({ status: 404, description: "Not found", type: ErrorResponseDto })
   async update(
     @Param("id") id: string,
     @Body() body: Update{Entity}BodyDto,
     @CorrelationId() correlationId: string,
   ): Promise<void> {
     await this.commandBus.execute(new Update{Entity}Command({ id, ...body, correlationId }));
   }
   ```

   **Command endpoint (DELETE — 204):**
   ```ts
   @Delete("/:id")
   @HttpCode(HttpStatus.NO_CONTENT)
   @ApiOperation({ summary: "Delete a {entity}" })
   @ApiParam({ name: "id", type: String, description: "{Entity} identifier" })
   @ApiResponse({ status: 204, description: "Deleted successfully" })
   @ApiResponse({ status: 404, description: "Not found", type: ErrorResponseDto })
   async delete(
     @Param("id") id: string,
     @CorrelationId() correlationId: string,
   ): Promise<void> {
     await this.commandBus.execute(new Delete{Entity}Command({ id, correlationId }));
   }
   ```

   **Query endpoint (GET single — 200):**
   ```ts
   @Get("/:id")
   @ApiOperation({ summary: "Get {entity} by ID" })
   @ApiParam({ name: "id", type: String, description: "{Entity} identifier" })
   @ApiResponse({ status: 200, description: "Found", type: {Entity}ResponseDto })
   @ApiResponse({ status: 404, description: "Not found", type: ErrorResponseDto })
   async getById(
     @Param("id") id: string,
     @CorrelationId() correlationId: string,
   ): Promise<{Entity}ResponseDto> {
     const result = await this.queryBus.execute(new Get{Entity}Query({ id, correlationId }));
     if (!result) throw new NotFoundException();
     return { id: result.id /* map read model fields to response DTO */ };
   }
   ```

   **Query endpoint (GET paginated — 200):**
   ```ts
   @Get()
   @ApiOperation({ summary: "List {entity}s" })
   @ApiQuery({ name: "page", type: Number, required: false, description: "Page number (default: 1)" })
   @ApiQuery({ name: "limit", type: Number, required: false, description: "Items per page (default: 20)" })
   @ApiResponse({ status: 200, description: "Paginated list", type: List{Entity}ResponseDto })
   async list(
     @Query() query: List{Entity}QueryDto,
     @CorrelationId() correlationId: string,
   ): Promise<List{Entity}ResponseDto> {
     return this.queryBus.execute(new List{Entity}Query({ ...query, correlationId }));
   }
   ```

   **Required imports:**
   ```ts
   import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post, Query } from "@nestjs/common";
   import { ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from "@nestjs/swagger";
   import { ErrorResponseDto } from "{SHARED_ROOT}/errors/base-feature-exception.filter";
   import { CorrelationId } from "{SHARED_ROOT}/decorators/correlation-id.decorator";
   ```

5. **Update exception filter** (if new error types) — add mappings to `{module}-exception.filter.ts`

## Limitations

- Does not create the command or query — run `/api-add-command` or `/api-add-query` first.
- Does not create integration tests — add manually following the `api-testing` rule.
- Does not modify route prefixes or versioning — assumes the controller already has `@Controller({ version, path })`.
