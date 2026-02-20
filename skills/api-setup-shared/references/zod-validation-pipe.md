# Zod validation infrastructure

Creates 5 files across `{SHARED_ROOT}/pipes/` and `{SHARED_ROOT}/decorators/`.

---

## File 1: `{SHARED_ROOT}/pipes/custom-zod-validation.exception.ts`

```ts
import { HttpException, HttpStatus } from "@nestjs/common";
import { z } from "zod";

export class CustomZodValidationException extends HttpException {
  constructor(error: z.ZodError) {
    super(
      {
        statusCode: HttpStatus.UNPROCESSABLE_ENTITY,
        message: "Validation failed",
        errors: z.flattenError(error).fieldErrors,
      },
      HttpStatus.UNPROCESSABLE_ENTITY,
    );
  }
}
```

---

## File 2: `{SHARED_ROOT}/decorators/zod-schema.decorator.ts`

```ts
import { z } from "zod";

export const ZOD_SCHEMA_KEY = Symbol("ZOD_SCHEMA");

export function ZodSchema(schema: z.ZodTypeAny): ClassDecorator {
  return (target) => {
    Reflect.defineMetadata(ZOD_SCHEMA_KEY, schema, target);
  };
}
```

---

## File 3: `{SHARED_ROOT}/pipes/zod-validation.pipe.ts`

```ts
import { ArgumentMetadata, Injectable, PipeTransform, Type } from "@nestjs/common";
import { z } from "zod";
import { CustomZodValidationException } from "./custom-zod-validation.exception";
import { ZOD_SCHEMA_KEY } from "../decorators/zod-schema.decorator";

/**
 * Zod validation pipe — two modes:
 *
 * 1. Manual: `new ZodValidationPipe(schema)` — validates using the provided schema
 * 2. Global: `new ZodValidationPipe()` — auto-detects schemas from @ZodSchema decorator
 *
 * Registered globally in main.ts:
 *   app.useGlobalPipes(new ZodValidationPipe());
 *
 * Used per-route with explicit schema:
 *   @Body(new ZodValidationPipe(CreateUserSchema)) body: CreateUserDto
 */
@Injectable()
export class ZodValidationPipe implements PipeTransform {
  constructor(private readonly schema?: z.ZodTypeAny) {}

  transform(value: unknown, metadata: ArgumentMetadata) {
    if (!["body", "query", "param"].includes(metadata.type)) return value;
    if (this.schema) return this.validateWithSchema(value, this.schema);
    return this.validateWithMetadata(value, metadata);
  }

  private validateWithMetadata(value: unknown, metadata: ArgumentMetadata) {
    if (!metadata.metatype) return value;
    const schema = this.getSchemaFromMetadata(metadata.metatype);
    if (!schema) return value;
    return this.validateWithSchema(value, schema);
  }

  private validateWithSchema(value: unknown, schema: z.ZodTypeAny) {
    try {
      return schema.parse(value);
    } catch (error) {
      if (error instanceof z.ZodError) throw new CustomZodValidationException(error);
      throw error;
    }
  }

  private getSchemaFromMetadata(metatype: Type<unknown>): z.ZodTypeAny | undefined {
    return Reflect.getMetadata(ZOD_SCHEMA_KEY, metatype);
  }
}

/** Convenience factory for per-route pipes */
export function createZodPipe(schema: z.ZodTypeAny): ZodValidationPipe {
  return new ZodValidationPipe(schema);
}
```

---

## File 4: `{SHARED_ROOT}/pipes/index.ts`

```ts
export * from "./zod-validation.pipe";
export * from "./custom-zod-validation.exception";
```

---

## File 5: `{SHARED_ROOT}/decorators/index.ts`

```ts
export * from "./zod-schema.decorator";
```

---

## Usage examples

**Global mode** (registered in `main.ts`, auto-discovers schema via decorator):
```ts
// presentation/dto/create-user.dto.ts
import { z } from "zod";
import { ZodSchema } from "@shared/decorators";

export const CreateUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
});

@ZodSchema(CreateUserSchema)
export class CreateUserDto {}

// presentation/controllers/users.controller.ts
@Post()
create(@Body() body: CreateUserDto) { ... }
```

**Manual mode** (per-route, no decorator needed):
```ts
@Post()
create(@Body(createZodPipe(CreateUserSchema)) body: z.infer<typeof CreateUserSchema>) { ... }
```
