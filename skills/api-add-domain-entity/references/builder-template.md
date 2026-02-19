# Test builder template

File: `domain/{entity-name}/{entity-name}.builder.ts`

```ts
import { faker } from "@faker-js/faker";
import { Xxx, XxxProps } from "./{entity-name}";

export class XxxBuilder {
  private id: string = faker.string.uuid();
  // ... other fields with realistic faker defaults

  public withId(id: string): XxxBuilder { this.id = id; return this; }
  // ... other with*() methods

  // Semantic preset methods when relevant
  public asActiveXxx(): XxxBuilder {
    // set fields that represent an "active" state
    return this;
  }

  public build(): Xxx {
    return Xxx.create({ id: this.id, /* ... */ });
  }

  public buildProps(): XxxProps {
    return { id: this.id, /* ... */ };
  }
}
```
