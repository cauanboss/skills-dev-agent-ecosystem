---
name: solutions-architecture
description: Metodologia de arquitetura de software — decisões arquiteturais, padrões, cross-cutting concerns, stack selection e fitness functions
---

# solutions-architecture

Metodologia para arquitetura de sistemas. Use ao planejar a estrutura de um novo projeto, avaliar trade-offs arquiteturais, ou revisar a arquitetura existente.

---

## 1. ADR — Architecture Decision Records

Toda decisão arquitetural significativa DEVE ser registrada como ADR.

### Template

```markdown
# ADR-NNN: Título da decisão

## Contexto
Descreva o problema, forças atuantes, restrições técnicas e de negócio.

## Decisão
Descreva a decisão tomada. Use linguagem afirmativa: "Vamos adotar X porque Y".

## Consequências
- **Positivas**: o que ganhamos com esta decisão
- **Negativas**: o que sacrificamos / riscos assumidos
- **Neutras**: mudanças de processo ou ferramentas

## Alternativas consideradas
| Alternativa | Prós | Contras | Motivo da rejeição |
|---|---|---|---|
| A | ... | ... | ... |
| B | ... | ... | ... |

## Status
[Proposto | Aceito | Depreciado | Substituído por ADR-NNN]
```

### Quando criar um ADR

- Escolha de linguagem, framework, banco, message broker
- Mudança de arquitetura (monólito → microsserviços, CQRS, etc.)
- Decisão de infraestrutura (cloud provider, deploy strategy)
- Decisão de protocolo/API (REST vs gRPC vs GraphQL)
- Decisão de segurança (authN/authZ, encryption)

---

## 2. Catálogo de padrões arquiteturais

| Padrão | Descrição | Quando usar | Quando evitar |
|---|---|---|---|
| **Monólito Modular** | Único deploy, módulos bem delimitados por domínio | Time pequeno, produto em validação, complexidade moderada | Time > 10 pessoas, requisitos de deploy independente |
| **Microsserviços** | Serviços independentes por bounded context | Time > 3 squads, deploy independente, escalabilidade seletiva | Time pequeno, domínio não mapeado, sem maturidade em DevOps |
| **CQRS** | Separa comandos (write) de queries (read) | Read/write ratios muito diferentes, performance crítica de leitura | Domínio simples, CRUD puro sem complexidade |
| **Event Sourcing** | Estado é derivado de eventos imutáveis | Audit trail obrigatório, reconstrução de estado temporal, eventos como fonte da verdade | Domínio sem necessidade de histórico, conflitos de concorrência altos |
| **Saga** | Transação distribuída orquestrada ou coreografada | Operação que cruza múltiplos serviços | Operação pode ser transacional com 2PC ou eventualmente consistente |
| **Strangler Fig** | Substituir sistema legado incrementalmente | Sistema legado grande, sem rewrite viável | Sistema pequeno que justifica rewrite total |
| **Hexagonal (Ports & Adapters)** | Lógica de negócio isolada de infraestrutura | Testabilidade crítica, múltiplos adaptadores (DB, fila, API) | Projeto simples sem troca de infra |
| **Event-Driven** | Comunicação assíncrona via eventos | Desacoplamento, escalabilidade, processamento em background | Fluxo síncrono obrigatório, consistência forte imediata |

---

## 3. Cross-cutting concerns

### Observabilidade (3 pilares)

| Pilar | O que monitorar | Ferramentas sugeridas |
|---|---|---|
| **Logs** | Erros, warnings, decisões de negócio, request lifecycle | Estrututrado (JSON), level (debug/info/warn/error), correlation ID |
| **Métricas** | RED (Rate, Errors, Duration) para cada serviço; USE (Utilization, Saturation, Errors) para infra | Prometheus + Grafana |
| **Tracing** | Request span entre serviços; latência por hop | OpenTelemetry + Jaeger/Zipkin |

### Segurança

- **AuthN**: OAuth2 / OIDC como padrão; JWT com curta expiração; refresh tokens
- **AuthZ**: RBAC para times pequenos, ABAC/ReBAC para domínios complexos
- **Segurança em trânsito**: TLS 1.3 obrigatório entre todos os serviços
- **Secrets**: vault externo (HashiCorp Vault, AWS Secrets Manager), nunca em env ou repo
- **Input validation**: sanitizar na borda da aplicação, não confiar em nada vindo do cliente

### Resiliência

| Padrão | Descrição | Biblioteca (Go) | Biblioteca (Node) |
|---|---|---|---|
| **Retry** | Reintentar com backoff exponencial + jitter | `cenkalti/backoff` | `p-retry` |
| **Circuit Breaker** | Falhar rápido quando serviço está down | `sony/gobreaker` | `opossum` |
| **Bulkhead** | Isolar recursos por consumidor | `channel` + context | `cockatiel` |
| **Timeout** | Deadline em toda chamada externa | `context.WithTimeout` | `AbortController` |
| **Rate Limit** | Limitar requisições por client | `golang.org/x/time/rate` | `express-rate-limit` |

---

## 4. Stack decision matrix

### Perfil de projeto → Stack recomendada

| Perfil | Linguagem | Framework | Banco | Mensageria | Infra |
|---|---|---|---|---|---|
| **CRUD-heavy (ERP, Dashboard)** | TypeScript | NestJS / Next.js | PostgreSQL | Redis (cache) | Container (Docker) |
| **Event-Driven / Streaming** | Go ou Java | Go net/http ou Spring Boot | PostgreSQL + Kafka | Kafka / NATS | Kubernetes |
| **Real-time (collab, live)** | Go | WebSocket / WebRTC | Redis + PostgreSQL | Redis PubSub | Kubernetes + edge |
| **Batch / ETL / ML** | Python | FastAPI / Airflow | S3 + DuckDB / ClickHouse | SQS / RabbitMQ | Serverless + spot |
| **Mobile / SPA** | TypeScript | React Native / Next.js | Supabase / Firebase | — | Vercel / Cloudflare |
| **Game server** | Go ou C# | godot / Unity netcode | Redis | NATS | Bare metal / dedicated |

### Critérios de decisão (em ordem de prioridade)

1. **Produtividade do time** — a stack que o time conhece
2. **Domínio do problema** — o padrão arquitetural que melhor se encaixa
3. **Restrições operacionais** — orçamento, compliance, SLA
4. **Ecossistema** — maturidade da lib, comunidade, suporte
5. **Performance** — throughput, latência, escalabilidade

---

## 5. Architecture fitness functions

Definições automatizáveis que garantem que a implementação respeita a arquitetura.

### Exemplos

```bash
# 1. Proibido import de domínio transversal (ex: billing importar de user)
# Usar ferramenta: go vet com analisador customizado, archunit (Java), dependency-cruiser (Node)

# 2. Camadas respeitadas (handler → service → repository, nunca o inverso)
# Verificar nas regras de lint da linguagem

# 3. Tabela de dependências proibidas
# Ex: módulo A não pode depender de módulo B

# 4. Número máximo de linhas por handler/service
# Lint rule: max 200 linhas por handler, max 300 por service
```

### Ferramentas

| Linguagem | Ferramenta | O que verifica |
|---|---|---|
| Go | `go vet` + custom analyzer | Dependências entre pacotes |
| TypeScript | `dependency-cruiser` | Dependências entre módulos, forbidden zones |
| Java | `ArchUnit` | Package dependency, layering, annotations |
| Python | `import-linter` | Regras de import entre camadas |
| .NET | `NetArchTest` | Similar ao ArchUnit para C# |

---

## 6. Anti-padrões arquiteturais

- **Big Ball of Mud**: sem estrutura, sem boundaries, tudo acoplado
- **Distributed Monolith**: microsserviços que são implantados juntos e dependem uns dos outros sincronamente
- **Premature Distribution**: microsserviços quando um monólito modular resolveria
- **Golden Hammer**: usar a mesma tecnologia/solução para todo problema
- **Vendor Lock-in**: depender de características proprietárias sem justificativa
- **Over-engineering**: camadas de abstração para casos que nunca acontecem
- **Anemic Architecture**: serviços sem lógica de negócio (CRUD puro)
- **No ADR**: decisões arquiteturais não documentadas, perdendo o racional
