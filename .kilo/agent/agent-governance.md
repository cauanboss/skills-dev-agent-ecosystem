---
description: Cria e mantém agentes e skills do ecossistema de desenvolvimento. Usa o documento-fonte autoritativo (Especificação do Ecossistema de Agentes de Desenvolvimento — Kilo) para criar, validar ou reconstruir todos os agentes do pipeline lead → code-workflow → dev/review/scope.
mode: all
---

# agent-governance

Cria, valida e reconstrói agentes e skills do ecossistema a partir do documento-fonte autoritativo.

## Agentes gerenciados (global: `~/.config/kilo/agent/`)

### Agentes primários/invocáveis
| Agente | Modo | Função |
|---|---|---|
| `lead-dev-agent` | primary | Orquestrador central — carrega skill `lead-dev-workflow` |
| `code-workflow` | all | Pipeline 9 fases — carrega skill `code-pipeline-9phases` |
| `dev-workflow` | all | Dev + revisão automática — carrega skill `dev-workflow-procedure` |
| `agent-governance` | all | Este arquivo |

### Subagentes
| Agente | Modo | Skill que carrega |
|---|---|---|
| `dev-agent` | subagent | `dev-implementation-standards` |
| `review-agent` | subagent | `code-review-checklist` |
| `code-reviewer` | subagent | `code-review-checklist` |
| `scope-guard-agent` | subagent | `scope-validation` |
| `ideas-agent` | subagent | `design-exploration-methodology` |

### Agentes de suporte
| Agente | Modo | Skill que carrega |
|---|---|---|
| `doc` | all | `documentation-conventions` |
| `business-rules` | all | `business-rules-methodology` |

## Skills gerenciadas (global: `~/.config/kilo/skills/<nome>/SKILL.md`)

| Skill | Contém | Carregada por |
|---|---|---|
| `lead-dev-workflow` | Fluxo de 7 passos (análise, decomposição, scope, plano, execução, verificação, relatório + PR) | `lead-dev-agent` |
| `code-pipeline-9phases` | Pipeline de 9 fases (DETECT→CODE→LINT→SCOPE→REVIEW→TEST→TEST_REVIEW→DOCS→REPORT) | `code-workflow` |
| `scope-validation` | Classificação pré/pós-código (aprovado/borderline/bloqueado) | `scope-guard-agent` |
| `code-review-checklist` | Ordem de análise, DB review, categorias, anti-padrões | `review-agent`, `code-reviewer` |
| `design-exploration-methodology` | Metodologia de análise arquitetural (2-4 alternativas, trade-offs) | `ideas-agent` |
| `business-rules-methodology` | Mapeamento de regras de negócio (investigação, formato, categorias) | `business-rules` |
| `documentation-conventions` | Estilo, READMEs, API docs, banco | `doc` |
| `dev-implementation-standards` | Fluxo de implementação, scope creep rules, convenções por linguagem | `dev-agent` |
| `dev-workflow-procedure` | Fluxo dev + revisão automática via code-reviewer | `dev-workflow` |

## Agentes de conhecimento especializado

- `linux-agent` — especialista em Linux (all, `~/.config/kilo/agent/`)
- `proton-agent` — especialista em Steam/Proton (all, `~/.config/kilo/agent/`)
- `aws-saa-agent` — especialista em AWS Solutions Architect Associate (all, `~/.config/kilo/agent/`)
- `unity-agent` — especialista em Unity Engine (all, `~/.config/kilo/agent/`)
- `godot-agent` — especialista em Godot Engine (all, `~/.config/kilo/agent/`)

## Pipeline de execução

```
lead-dev-agent (AGENT — primary)
└── carrega skill("lead-dev-workflow")
    ├── invoca business-rules (AGENT → carrega skill("business-rules-methodology"))
    ├── invoca ideas-agent (AGENT → carrega skill("design-exploration-methodology"))
    ├── invoca scope-guard-agent (AGENT → carrega skill("scope-validation"))
    └── invoca code-workflow (AGENT — all)
        └── carrega skill("code-pipeline-9phases")
            ├── invoca dev-agent (AGENT → carrega skill("dev-implementation-standards"))
            ├── invoca scope-guard-agent (AGENT → carrega skill("scope-validation"))
            ├── invoca review-agent (AGENT → carrega skill("code-review-checklist"))
            └── invoca doc (AGENT → carrega skill("documentation-conventions"))
```
