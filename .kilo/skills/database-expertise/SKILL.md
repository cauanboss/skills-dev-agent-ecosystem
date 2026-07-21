---
name: database-expertise
description: Metodologia para modelagem, otimização, migração e revisão de bancos de dados SQL, NoSQL, caches e GraphQL
---

# database-expertise

Metodologia abrangente para bancos de dados, caches e GraphQL. Use ao atuar como db-agent.

---

## 1. SQL (PostgreSQL, MySQL, SQLite)

### Modelagem

- Prefira `UUID` sobre `SERIAL` para chaves primárias distribuídas.
- Use `TIMESTAMPTZ` para timestamps com fuso horário.
- Evite `TEXT` sem `CHECK` de tamanho quando o domínio tem limite conhecido.
- Relacionamentos N:N exigem tabela associativa com chave composta.
- `ENUM` é prático, mas `CHECK` ou tabela de referência são mais flexíveis para evolução.

### Indexação

```sql
-- Índice composto: colunas de alta seletividade primeiro
CREATE INDEX idx_orders_user_status_created
ON orders (user_id, status, created_at DESC);

-- Partial index para filtros comuns
CREATE INDEX idx_orders_pending
ON orders (created_at)
WHERE status = 'pending';

-- Covering index para queries que só precisam de algumas colunas
CREATE INDEX idx_users_email_name
ON users (email) INCLUDE (name, avatar_url);
```

- `EXPLAIN ANALYZE` antes e depois de qualquer mudança.
- Sequencial scan em tabela grande (>10k linhas) sem índice é bandeira vermelha.
- Índices em colunas de baixa cardinalidade (ex: `boolean`, `status` com 2-3 valores) raramente são úteis sozinhos.

### Migrations

#### Princípios fundamentais

- **Forward-only**: nova migration sempre adiciona, nunca altera a anterior.
- **Idempotente**: usar `IF NOT EXISTS` / `IF EXISTS` / `CREATE OR REPLACE`.
- **Rollback**: cada migration DEVE ter `DOWN` testado, mesmo que seja `DROP TABLE`.
- **Batch**: migrações que alteram tabelas grandes (>1M linhas) devem ser batch (ex: `batched ALTER`, `pt-online-schema-change`).
- **Lock**: evitar `ADD COLUMN DEFAULT` com valor não nulo em tabelas grandes (lock write). Preferir: `ADD COLUMN`, `UPDATE batch`, `ALTER COLUMN SET NOT NULL`.

#### Estratégias de deploy

| Estratégia | Descrição | Downtime | Rollback | Complexidade |
|---|---|---|---|---|
| **Expand-Contract** | Adicionar coluna/tabela compatível com código antigo, migrar dados, remover old | Zero | Sim (reverter app) | Média |
| **Parallel Run** | Escrever em old e novo simultaneamente, comparar resultados, cortar | Zero | Sim (desligar novo) | Alta |
| **Big Bang** | Parar app, migrar tudo, subir app | Downtime total | Sim (restore) | Baixa |
| **Phase-Out (Feature Flag)** | Feature flag controla qual schema a app usa, migrar gradualmente por usuário | Zero | Sim (toggle flag) | Média |

**Regra geral**: zero-downtime é o padrão esperado. Big bang só é aceitável em janelas de manutenção agendadas e comunicadas.

#### Data backfill

- **Batch size**: 1000–5000 registros por lote (ajustar conforme tamanho da linha e IO do banco).
- **Progress tracking**: tabela de controle `migration_batches` com `(id, total_rows, processed_rows, status, error)`.
- **Idempotência**: usar `ON CONFLICT DO UPDATE` (PostgreSQL) / `MERGE` (SQL Server) / `INSERT ... ON DUPLICATE KEY UPDATE` (MySQL).
- **Validação pós-backfill**: `COUNT(*)` entre old e new deve ser igual; amostragem de registros com diff checksum.
- **Rate limiting**: respeitar `max_connections` e IOPS do banco — pausar N ms entre batches se necessário.

#### Validação pós-migração

Checklist executado APÓS aplicar a migration e antes de considerar concluída:

1. `COUNT(*)` old vs new — mesma contagem
2. Amostragem aleatória de registros — diff de checksum por coluna mapeada
3. Monitorar logs de erro da aplicação por 5–10 min pós-deploy
4. Verificar queries lentas (PG: `pg_stat_activity` com `state = 'active'`)
5. Testar rollback (`DOWN`) em staging com o mesmo volume de dados
6. Verificar se índices foram criados e estão sendo usados (`EXPLAIN ANALYZE`)

#### Ferramentas por stack

| Stack | Ferramenta | Comando / Uso |
|---|---|---|
| Python / SQLAlchemy | Alembic | `alembic revision --autogenerate -m "add_column_x"` |
| Go | `golang-migrate/migrate` | `migrate create -ext sql -dir migrations add_column_x` |
| Node / TypeORM | TypeORM migrations | `typeorm migration:create src/migration/AddColumnX` |
| Node / Prisma | `prisma migrate` | `prisma migrate dev --name add_column_x` |
| Java / Hibernate | Flyway | `flyway migrate` (arquivos `V1__desc.sql`) |
| .NET / EF Core | `dotnet ef migrations` | `dotnet ef migrations add AddColumnX` |
| Ruby / ActiveRecord | `rake db:migrate` | Gerado automaticamente com `rails generate migration` |
| PHP / Laravel | Eloquent migrations | `php artisan make:migration add_column_x` |

#### Migrações em NoSQL

- **MongoDB**: schema é flexível, mas migrations ainda são necessárias para dados existentes:
  - Script de `updateMany` com filtro em documentos sem o campo
  - Validação com `$jsonSchema` para garantir que documentos novos sigam o novo formato
  - Batch com `cursor` + `bulkWrite` para milhões de documentos
- **DynamoDB**: não há schema migration no banco — a migração é no código que lê o atributo (versão de item). Usar campo `v: Int` em cada item para controle de versão.

### Queries

- **Parameterized queries sempre** — proibido string interpolation.
- `SELECT *` só em queries exploratórias. Em produção, listar colunas.
- Subqueries correlacionadas geralmente viram `JOIN` ou `LATERAL`.
- `OFFSET` + `LIMIT` para paginação é O(n). Preferir **keyset pagination** (`WHERE id > $1 ORDER BY id LIMIT $2`).
- `COUNT(*)` em tabelas grandes é caro. Considerar estimativas via `pg_stat_user_tables` ou cache separado.

### Transações

- Escopo mínimo — manter transação aberta pelo menor tempo possível.
- Propagar `context.Context` em Go para suportar cancelamento e timeout.
- Rollback explícito em qualquer caminho de erro.
- Evitar transações que misturam operações lentas (HTTP call + SQL).

---

## 2. NoSQL (MongoDB, DynamoDB, Firestore)

### Modelagem

- **Documentos embedados** para relações 1:1 e 1:N pequenas (até ~100 itens).
- **Referências** para relações N:N ou documentos que crescem sem limite.
- Modelar para o padrão de acesso (read/write ratio), não para a entidade.
- Evitar `$lookup` (JOIN) — se precisa frequentemente, o dado deveria estar embedado ou o banco certo é relacional.

### Indexação

```javascript
// MongoDB: índice composto com sort embedado
db.orders.createIndex(
  { user_id: 1, created_at: -1 },
  { partialFilterExpression: { status: "pending" } }
)
```

- **Índices cobrindo sort** — se a query ordena por `created_at DESC`, o índice precisa dessa coluna por último na direção correta.
- **TTL indexes** para expirar dados temporários (sessions, logs).
- Evitar `not null` como condição de filtro — é contra-intuitivo para o otimizador.

### Aggregation Pipeline

- `$match` e `$limit` no início da pipeline para reduzir documentos processados.
- `$lookup` é caro — preferir `$project` + dados embedados.
- `$group` com `$sort` exige índice no campo do `$group`.
- `$facet` é prático mas executa múltiplos pipelines em paralelo — testar com dados reais.

---

## 3. Caches (Redis, Memcached, CDN)

### Estratégias

| Padrão | Descrição | Quando usar |
|---|---|---|
| **Cache-aside** | App consulta cache, se miss busca no DB e popula cache | Leituras frequentes, escrita moderada |
| **Write-through** | App escreve no cache e no DB simultaneamente | Consistência forte, escrita controlada |
| **Write-behind** | App escreve no cache, DB atualizado async | Alta taxa de escrita, latência crítica |
| **Cache warming** | Popular cache antecipadamente (ex: startup) | Dados de referência, rankings, config |

### Redis

- Usar tipos nativos (`STRING`, `HASH`, `SET`, `ZSET`, `LIST`) em vez de serializar tudo como JSON.
- `SET NX EX` para locks distribuídos (cuidado com deadlock — usar `SET key uuid NX EX 10` e liberar com script Lua).
- **Evitar `KEYS *`** em produção — usar `SCAN` com cursor.
- `PUB/SUB` não garante entrega — para filas, usar `BRPOPLPUSH` ou Redis Streams.
- Monitorar `maxmemory-policy`: `allkeys-lru` para cache, `noeviction` para dados persistentes.

### Cache Invalidation

- **TTL** é a estratégia mais simples e segura.
- **Event-driven**: invalidar cache quando o dado subjacente muda (ex: fila de eventos).
- **Versionamento de chave**: `user:123:v2` — incrementa versão quando o schema muda.
- Evitar invalidação em cascata (ex: invalidar todos os caches de um usuário ao alterar perfil).

---

## 4. GraphQL

### Schema Design

- **Node interface** para tipos que podem ser referenciados globalmente (Relay spec).
- **Input types** separados dos `ObjectType` — `CreateUserInput` vs `User`.
- **Enums** para campos com valores fixos — evita strings mágicas.
- **Connections** (Relay pagination) para listas — suporta `first`, `after`, `last`, `before`.
- **Evitar `JSON`/`JSONB` como scalar** — fere a tipagem forte do GraphQL.

### Resolvers

```
Query.user → resolver busca 1 usuário via WHERE id = $1        ← O(1)
User.posts → resolver busca N posts via WHERE author_id = $1    ← O(N) se N resolvers

Problema: N+1 queries (1 user + N posts)
Solução: DataLoader para batch e cache por request
```

- **DataLoader** obrigatório para qualquer resolver que acessa banco em lista.
- **Batch** resolvers: `SELECT * FROM posts WHERE author_id IN ($1, $2, $3)`.
- **Evitar** resolvers que encadeiam chamadas HTTP síncronas.
- **Complexidade**: limitar profundidade máxima (max 5 níveis) e custo por query.

### Mutations

- Seguir convention: `mutationName(input: MutationInput!): MutationPayload!`
- Retornar o objeto modificado + `clientMutationId` para idempotência.
- Mutations que alteram múltiplos recursos devem ser transacionais.

### N+1 no GraphQL

```graphql
query {
  users {
    posts {        ← 1 query para users + N queries para posts
      comments {   ← + N queries para comments de cada post
      }
    }
  }
}
```

**Detecção**: log de queries SQL com `source` do resolver. Se vir N queries iguais com parâmetros diferentes, é N+1.

**Solução**: DataLoader com batch function + `cacheMap` por request.

### Federation (GraphQL Gateway)

- `@key(fields: "id")` para estender tipos entre subgraphs.
- `@requires` e `@provides` para campos calculados.
- Evitar `@shareable` em campos voláteis — versões diferentes do schema podem retornar valores diferentes.

---

## 5. Anti-padrões

### SQL

- `SELECT N+1` em loops da aplicação.
- Falta de `LIMIT` em queries sem filtro.
- `LIKE '%termo%'` sem índice de texto completo (`tsvector` / `GIN`).
- Migração sem `DOWN`, impossibilitando rollback.
- `ALTER TABLE` com `DEFAULT` não nulo em produção sem batch.

### NoSQL

- Embedar arrays que crescem sem limite (explodem o documento de 16MB).
- `$lookup` como JOIN relacional frequente (banco errado para o caso de uso).
- Falta de TTL em coleções de dados temporários.
- Modelagem relacional em banco documental (normalizar tudo).

### Cache

- Cache sem TTL (stale data permanente).
- Serializar objetos grandes em Redis String (preferir HASH).
- Cache distribuído sem estratégia de invalidação.
- Usar Redis como banco primário sem persistência configurada.

### GraphQL

- Resolver sem DataLoader (causa N+1).
- Schema com `JSON` scalar para evitar modelar tipos.
- Mutations sem retorno do estado modificado.
- Profundidade ilimitada (ataque de recursão).
- Campos com listas sem paginação (explosão de dados).
