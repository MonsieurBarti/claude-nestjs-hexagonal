# Presentation layer templates

See the `api-presentation` rule (`rules/api-presentation.md`) for the complete controller and in-proc patterns.

## Exception filter — `{module-name}-exception.filter.ts`

```ts
import { Catch, HttpStatus } from "@nestjs/common";
import { BaseFeatureExceptionFilter } from "{SHARED_ROOT}/errors/base-feature-exception.filter";
import { {ModuleName}Error, SomeNotFoundError } from "../domain/errors";

@Catch({ModuleName}Error)
export class {ModuleName}ExceptionFilter extends BaseFeatureExceptionFilter<{ModuleName}Error> {
  protected mapErrorToStatus(error: {ModuleName}Error): number {
    // System errors FIRST (500)
    // if (error instanceof SomeSystemError) return HttpStatus.INTERNAL_SERVER_ERROR;
    // User errors
    if (error instanceof SomeNotFoundError) return HttpStatus.NOT_FOUND;
    return HttpStatus.INTERNAL_SERVER_ERROR;
  }
}
```

## DTOs — `presentation/dto/{module-name}.dto.ts`

```ts
import { ApiProperty } from "@nestjs/swagger";
import { z } from "zod";
import { ZodSchema } from "{SHARED_ROOT}/decorators/zod-schema.decorator";

// ─── Request DTOs ────────────────────────────────────────────────────────────

export const Create{ModuleName}BodySchema = z.object({
  name: z.string().min(1).max(100),
});

@ZodSchema(Create{ModuleName}BodySchema)
export class Create{ModuleName}BodyDto {
  @ApiProperty({ example: "My {module-name}", description: "Display name", minLength: 1, maxLength: 100 })
  name!: string;
}

// ─── Response DTOs ───────────────────────────────────────────────────────────

export class {ModuleName}ResponseDto {
  @ApiProperty({ example: "550e8400-e29b-41d4-a716-446655440000" })
  id!: string;

  @ApiProperty({ example: "My {module-name}" })
  name!: string;
}
```

> **Rule**: every public property on every DTO class must have `@ApiProperty()`.
> Request DTOs keep `@ZodSchema(...)` on the class for runtime validation; `@ApiProperty()` per property is for Swagger only.
> Response DTOs are plain classes — no Zod schema needed.

## Controller — `presentation/controllers/{module-name}.controller.ts`

```ts
import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post } from "@nestjs/common";
import { ApiBody, ApiOperation, ApiParam, ApiResponse, ApiTags } from "@nestjs/swagger";
import { TypedCommandBus } from "{SHARED_ROOT}/cqrs/typed-command-bus";
import { TypedQueryBus } from "{SHARED_ROOT}/cqrs/typed-query-bus";
import { ErrorResponseDto } from "{SHARED_ROOT}/errors/base-feature-exception.filter";
import { BaseLogger } from "{SHARED_ROOT}/logger/logger";
import { InjectLogger } from "{SHARED_ROOT}/logger/inject-logger.decorator";
import { CorrelationId } from "{SHARED_ROOT}/decorators/correlation-id.decorator";
import { Create{ModuleName}BodyDto, {ModuleName}ResponseDto } from "../dto/{module-name}.dto";
import { Create{ModuleName}Command } from "../../application/commands/create-{module-name}/{module-name}.command";

@ApiTags("{module-name}")
@Controller({ version: "1", path: "{module-name}" })
export class {ModuleName}Controller {
  private readonly logger: BaseLogger;

  constructor(
    private readonly commandBus: TypedCommandBus,
    private readonly queryBus: TypedQueryBus,
    @InjectLogger() logger: BaseLogger,
  ) {
    this.logger = logger.createChild({
      moduleName: "{module-name}",
      className: {ModuleName}Controller.name,
    });
  }

  @Post()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: "Create a {module-name}" })
  @ApiBody({ type: Create{ModuleName}BodyDto })
  @ApiResponse({ status: 204, description: "Created successfully" })
  @ApiResponse({ status: 422, description: "Validation error", type: ErrorResponseDto })
  async create(
    @Body() body: Create{ModuleName}BodyDto,
    @CorrelationId() correlationId: string,
  ): Promise<void> {
    await this.commandBus.execute(
      new Create{ModuleName}Command({ ...body, correlationId }),
    );
  }
}
```

> Add further endpoints following the same pattern:
> - `@Get("/:id")` → `@ApiParam({ name: "id", type: String })` + `@ApiResponse({ status: 200, type: {ModuleName}ResponseDto })`
> - `@Get()` with pagination → `@ApiQuery({ name: "page", type: Number, required: false })`

## In-proc facade (if consumed by other modules)

Interface: `{SHARED_ROOT}/in-proc/{module-name}.in-proc.ts`
```ts
export interface I{ModuleName}InProc {
  // methods exposed to other modules
}
```

Implementation: `presentation/in-proc/{module-name}.in-proc.ts`
```ts
import { Injectable } from "@nestjs/common";
import { TypedCommandBus } from "{SHARED_ROOT}/cqrs/typed-command-bus";
import { TypedQueryBus } from "{SHARED_ROOT}/cqrs/typed-query-bus";
import { I{ModuleName}InProc } from "{SHARED_ROOT}/in-proc/{module-name}.in-proc";

@Injectable()
export class {ModuleName}InProc implements I{ModuleName}InProc {
  constructor(
    private readonly commandBus: TypedCommandBus,
    private readonly queryBus: TypedQueryBus,
  ) {}
}
```
