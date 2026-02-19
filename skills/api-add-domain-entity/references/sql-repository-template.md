# SQL repository template

File: `infrastructure/{entity-name}/sql-{entity-name}.repository.ts`

```ts
import { Injectable } from "@nestjs/common";
import { PrismaService } from "{SHARED_ROOT}/prisma/prisma.service";
import { IXxxRepository } from "../../domain/{entity-name}/{entity-name}.repository";
import { Xxx } from "../../domain/{entity-name}/{entity-name}";
import { SqlXxxMapper } from "./sql-{entity-name}.mapper";

@Injectable()
export class SqlXxxRepository implements IXxxRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(entity: Xxx): Promise<void> {
    const data = SqlXxxMapper.toPersistence(entity);
    await this.prisma.xxx.upsert({ where: { id: data.id }, create: data, update: data });
  }

  async findById(id: string): Promise<Xxx | null> {
    const raw = await this.prisma.xxx.findUnique({ where: { id } });
    return raw ? SqlXxxMapper.toDomain(raw) : null;
  }
}
```
