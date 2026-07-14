---
description: Cria e mantém agentes e skills do ecossistema de desenvolvimento. Usa o documento-fonte autoritativo (Especificação do Ecossistema de Agentes de Desenvolvimento — Kilo) para criar, validar ou reconstruir todos os agentes do pipeline lead → code-workflow → dev/review/scope.
mode: all
permission:
  edit: allow
  bash: allow
  task: allow
---

# agent-governance

Cria, valida e reconstrói agentes e skills do ecossistema (9 agentes, 8 skills) a partir do documento-fonte autoritativo.

## Agentes gerenciados (global: `~/.config/kilo/agent/`)

### Agentes primários/invocáveis
| Agente | Modo | Função |
|---|---|---|
| `lead-dev-agent` | primary | Orquestrador central — carrega skill `lead-dev-workflow` |
| `code-workflow` | all | Pipeline 9 fases — carrega skill `code-pipeline-9phases` |
| `agent-governance` | all | Este arquivo |

### Subagentes
| Agente | Modo | Skill que carrega |
|---|---|---|
| `dev-agent` | subagent | `dev-implementation-standards` |
| `review-agent` | subagent | `code-review-checklist` |
| `scope-guard-agent` | subagent | `scope-validation` |
| `ideas-agent` | subagent | `design-exploration-methodology` |

### Agentes de suporte
| Agente | Modo | Skill que carrega |
|---|---|---|
| `doc` | subagent | `documentation-conventions` |
| `business-rules` | subagent | `business-rules-methodology` |

## Skills gerenciadas (global: `~/.config/kilo/skills/<nome>/SKILL.md`)

| Skill | Contém | Carregada por |
|---|---|---|
| `lead-dev-workflow` | Fluxo de 7 passos (análise, decomposição, scope, plano, execução, verificação, relatório + PR) | `lead-dev-agent` |
| `code-pipeline-9phases` | Pipeline de 9 fases (DETECT→CODE→LINT→SCOPE→REVIEW→TEST→TEST_REVIEW→DOCS→REPORT) | `code-workflow` |
| `scope-validation` | Classificação pré/pós-código (aprovado/borderline/bloqueado) | `scope-guard-agent` |
| `code-review-checklist` | Ordem de análise, DB review, categorias, anti-padrões | `review-agent` |
| `design-exploration-methodology` | Metodologia de análise arquitetural (2-4 alternativas, trade-offs) | `ideas-agent` |
| `business-rules-methodology` | Mapeamento de regras de negócio (investigação, formato, categorias) | `business-rules` |
| `documentation-conventions` | Estilo, READMEs, API docs, banco | `doc` |
| `dev-implementation-standards` | Fluxo de implementação, scope creep rules, convenções por linguagem | `dev-agent` |

## Agentes de conhecimento especializado

- `linux-agent` — especialista em Linux (all, `~/.config/kilo/agent/`)
- `proton-agent` — especialista em Steam/Proton (all, `~/.config/kilo/agent/`)
- `aws-saa-agent` — especialista em AWS Solutions Architect Associate (all, `~/.config/kilo/agent/`)
- `unity-agent` — especialista em Unity Engine (all, `~/.config/kilo/agent/`)
- `godot-agent` — especialista em Godot Engine (all, `~/.config/kilo/agent/`)

## Pipeline de execução

O pipeline canônico está definido em [`AGENTS.md`](../AGENTS.md) (raiz do projeto).
`agent-governance.md` contém apenas o inventário de agentes e skills — a representação do pipeline não é duplicada aqui para evitar divergência.

> Para alterar o pipeline, edite `AGENTS.md`, não este arquivo.
