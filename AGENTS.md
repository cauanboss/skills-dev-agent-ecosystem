# AGENTS.md — dev-agent-ecosystem

Ecossistema auto-gerido de agentes de desenvolvimento. Orquestra todo o ciclo: alinhamento, análise, decomposição, implementação, revisão, debugging e documentação.

## Estrutura

```
.kilo/
├── agent/                    ← 11 agentes finos (carregam skills)
│   ├── lead-dev-agent.md     primary — carrega skill("lead-dev-workflow")
│   ├── code-workflow.md      all    — carrega skill("code-pipeline-9phases")
│   ├── dev-agent.md          subagent — carrega skill("dev-implementation-standards")
│   ├── review-agent.md       subagent — carrega skill("code-review-checklist")
│   ├── scope-guard-agent.md  subagent — carrega skill("scope-validation")
│   ├── ideas-agent.md        subagent — carrega skill("design-exploration-methodology")
│   ├── business-rules.md     subagent — carrega skill("business-rules-methodology")
│   ├── doc.md                subagent — carrega skill("documentation-conventions")
│   ├── db-agent.md           all    — carrega skill("database-expertise")
│   ├── bug-hunter.md         all    — carrega skill("bug-diagnosis")
│   └── agent-governance.md   all    — gerencia todo o ecossistema
└── skills/                   ← 10 skills (workflows detalhados)
    ├── lead-dev-workflow/SKILL.md
    ├── code-pipeline-9phases/SKILL.md
    ├── scope-validation/SKILL.md
    ├── code-review-checklist/SKILL.md
    ├── design-exploration-methodology/SKILL.md
    ├── business-rules-methodology/SKILL.md
    ├── documentation-conventions/SKILL.md
    ├── dev-implementation-standards/SKILL.md
    ├── database-expertise/SKILL.md
    └── bug-diagnosis/SKILL.md
```

## Pipeline de execução (8 passos)

```
lead-dev-agent (primary)
└── carrega skill("lead-dev-workflow")
    ├── Passo 0 — Alinhamento (entrevista o usuário)
    ├── Passo 1 — Análise
    │   ├── invoca business-rules → skill("business-rules-methodology")
    │   ├── invoca ideas-agent → skill("design-exploration-methodology")
    │   ├── invoca db-agent → skill("database-expertise")
    │   └── invoca doc
    ├── Passo 2 — Decomposição
    │   └── Passo 2.1 — Publicar no tracker (opcional)
    ├── Passo 3 — Validação de escopo (scope-guard-agent)
    ├── Passo 4 — Apresentação do plano
    ├── Passo 5 — Execução orquestrada
    │   └── invoca code-workflow (all)
    │       └── carrega skill("code-pipeline-9phases")
    │           ├── Fase 1: DETECT
    │           ├── Fase 2: CODE (RED→GREEN se TDD strict/relaxed)
    │           ├── Fase 3: LINT  ──┐
    │           ├── Fase 4: SCOPE ──┤ paralelo
    │           ├── Fase 5: CODE REVIEW
    │           ├── Fase 5.1: DB REVIEW (se aplicável)
    │           ├── Fase 6: TEST
    │           │   └── falha não-trivial → invoca bug-hunter → skill("bug-diagnosis")
    │           ├── Fase 7: TEST REVIEW ──┐
    │           ├── Fase 8: DOCS        ──┤ paralelo
    │           └── Fase 9: REPORT
    ├── Passo 6 — Verificação cross-task
    └── Passo 7 — Relatório + PR Description + Handoff
```

## Como usar

1. Selecione `lead-dev-agent` como agente primário (`@lead-dev-agent`)
2. Ele carrega a skill `lead-dev-workflow` automaticamente
3. Siga o fluxo de 8 passos: **Alinhamento → Análise → Decomposição → Scope → Plano → Execução → Verificação → Relatório**

### Novos agentes

| Agente | Skill | Quando usar |
|---|---|---|
| **`bug-hunter`** | `bug-diagnosis` | Debugging estruturado de bugs/regressões. Invocável diretamente (`@bug-hunter`) ou automaticamente pelo code-workflow em falhas não-triviais. |

### Novos modos TDD

O `code-workflow` agora aceita `tdd_mode` no contexto da tarefa:
- `strict`: RED→GREEN obrigatório. Para lógica de negócio e contracts de API.
- `relaxed`: RED→GREEN sugerido. Default. Prossegue se inviável.
- `off`: sem TDD. Para config, docs, explore.

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

## Manter atualizado

### Sync manual via comando

```
/sync-ecosystem
/sync-ecosystem --all
/sync-ecosystem --check
```

### Sync via script

```bash
./scripts/sync-ecosystem.sh              # global apenas
./scripts/sync-ecosystem.sh --all        # global + todos os projetos
./scripts/sync-ecosystem.sh --check      # dry-run
```
