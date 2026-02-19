# Root module template

File: `{module-name}.module.ts`

```ts
import { Module } from "@nestjs/common";
import { APP_FILTER } from "@nestjs/core";
import { {ModuleName}ApplicationModule } from "./application/{module-name}.module";
import { {ModuleName}ExceptionFilter } from "./presentation/{module-name}-exception.filter";
import { {ModuleName}Controller } from "./presentation/controllers/{module-name}.controller";

@Module({
  imports: [{ModuleName}ApplicationModule],
  controllers: [{ModuleName}Controller],
  providers: [
    {
      provide: APP_FILTER,
      useClass: {ModuleName}ExceptionFilter,
    },
  ],
})
export class {ModuleName}Module {}
```

Register in the app root module (e.g. `app.module.ts`):
```ts
imports: [
  // existing modules...
  {ModuleName}Module,
],
```
