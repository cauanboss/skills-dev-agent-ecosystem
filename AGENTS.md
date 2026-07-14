# AGENTS.md — dev-agent-ecosystem

Ecossistema auto-gerido de agentes de desenvolvimento. Orquestra todo o ciclo: análise, decomposição, implementação, revisão e documentação.

## Estrutura

```
.kilo/
├── agent/                    ← 10 agentes finos (carregam skills)
│   ├── lead-dev-agent.md     primary — carrega skill("lead-dev-workflow")
│   ├── code-workflow.md      all    — carrega skill("code-pipeline-9phases")
│   ├── dev-agent.md          subagent — carrega skill("dev-implementation-standards")
│   ├── review-agent.md       subagent — carrega skill("code-review-checklist")
│   ├── scope-guard-agent.md  subagent — carrega skill("scope-validation")
│   ├── ideas-agent.md        subagent — carrega skill("design-exploration-methodology")
│   ├── business-rules.md     subagent — carrega skill("business-rules-methodology")
│   ├── doc.md                subagent — carrega skill("documentation-conventions")
│   ├── db-agent.md           all    — carrega skill("database-expertise")
│   └── agent-governance.md   all    — gerencia todo o ecossistema
└── skills/                   ← 9 skills (workflows detalhados)
    ├── lead-dev-workflow/SKILL.md
    ├── code-pipeline-9phases/SKILL.md
    ├── scope-validation/SKILL.md
    ├── code-review-checklist/SKILL.md
    ├── design-exploration-methodology/SKILL.md
    ├── business-rules-methodology/SKILL.md
    ├── documentation-conventions/SKILL.md
    ├── dev-implementation-standards/SKILL.md
    └── database-expertise/SKILL.md
```

## Pipeline de execução

```
lead-dev-agent (primary)
└── carrega skill("lead-dev-workflow")
    ├── invoca business-rules → skill("business-rules-methodology")
    ├── invoca ideas-agent → skill("design-exploration-methodology")
    ├── invoca scope-guard-agent → skill("scope-validation")
    ├── invoca db-agent → skill("database-expertise")       ← se houver banco
    └── invoca code-workflow (all)
        └── carrega skill("code-pipeline-9phases")
            ├── invoca dev-agent → skill("dev-implementation-standards")
            ├── invoca scope-guard-agent
            ├── invoca review-agent → skill("code-review-checklist")
            ├── invoca db-agent → skill("database-expertise")  ← se houver banco
            └── invoca doc → skill("documentation-conventions")
```

## Como usar

1. Selecione `lead-dev-agent` como agente primário (`@lead-dev-agent`)
2. Ele carrega a skill `lead-dev-workflow` automaticamente
3. Siga o fluxo de 7 passos: Análise → Decomposição → Scope → Plano → Execução → Verificação → Relatório

## Integração com projetos

Este ecossistema é a **fonte canônica** de agentes e skills. A sincronização é feita em duas camadas:

### Camada 1 — Global (`~/.config/kilo/`)
- Contém a cópia atualizada de todos os agentes e skills.
- Carregado automaticamente em qualquer projeto Kilo.
- Define `default_agent: lead-dev-agent` e `instructions: [AGENTS.md]`.

### Camada 2 — Projetos
Cada projeto pode ter:
- **Cópias locais** (ex: `rondas-microservices/.kilo/agent/`) — sincronizadas manualmente via `/sync-ecosystem`.
- **`kilo.json`** — define `default_agent` e permissões específicas do projeto.
- **`AGENTS.md` próprio** — convenções específicas do projeto (naming, pacotes, produção, testes).

### Projetos vinculados

| Projeto | Agentes locais | Skills locais | `kilo.json` | `AGENTS.md` próprio |
|---|---|---|---|---|
| `rondas-microservices` | Sim (sincronizado) | Sim (sincronizado) | Sim | Sim (convenções Go) |
| `patrol` | Não (usa global) | Não (usa global) | Sim | Sim (stack Node/Zflow) |
| `linux` | Não (ecossistema Cursor) | Não (ecossistema Cursor) | Não | Sim (adaptação Cursor) |

## Manter atualizado

### Auto-sync via git hooks (recomendado)

O ecossistema usa hooks git para sincronizar automaticamente após commits, merges ou checkouts.

```bash
# Ativar hooks (uma vez por clone):
git config core.hooksPath .githooks
```

Após ativar, toda alteração em `.kilo/agent/` ou `.kilo/skills/` dispara sync automático
para `~/.config/kilo/`. Os hooks **não** sincronizam projetos automaticamente (apenas global)
para evitar surpresas.

### Sync manual via comando

```
/sync-ecosystem
```

### Sync via script

```bash
# Global apenas
./scripts/sync-ecosystem.sh

# Global + todos os projetos
./scripts/sync-ecosystem.sh --all

# Apenas verificar diferenças (dry-run)
./scripts/sync-ecosystem.sh --check
```

### De dentro de um projeto

Projetos com cópias locais (ex: `rondas-microservices`):

```
/pull-ecosystem
```

### Cadeia completa de sincronização

```
skills-dev-agent-ecosystem/.kilo/    ← fonte canônica
       │
       ├── git hooks (post-commit/post-merge/post-checkout)
       │     └── auto → ~/.config/kilo/   ← global (todos os projetos)
       │
       ├── /sync-ecosystem (comando Kilo)
       │     └── ~/.config/kilo/ + rondas-microservices/.kilo/
       │
       └── scripts/sync-ecosystem.sh (script shell)
             └── ~/.config/kilo/ + rondas-microservices/.kilo/
```
