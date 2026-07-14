# AGENTS.md — dev-agent-ecosystem

Ecossistema auto-gerido de agentes de desenvolvimento. Orquestra todo o ciclo: análise, decomposição, implementação, revisão e documentação.

## Estrutura

```
.kilo/
├── agent/                    ← 11 agentes finos (carregam skills)
│   ├── lead-dev-agent.md     primary — carrega skill("lead-dev-workflow")
│   ├── code-workflow.md      all    — carrega skill("code-pipeline-9phases")
│   ├── dev-workflow.md       all    — carrega skill("dev-workflow-procedure")
│   ├── dev-agent.md          subagent — carrega skill("dev-implementation-standards")
│   ├── review-agent.md       subagent — carrega skill("code-review-checklist")
│   ├── code-reviewer.md      subagent — carrega skill("code-review-checklist")
│   ├── scope-guard-agent.md  subagent — carrega skill("scope-validation")
│   ├── ideas-agent.md        subagent — carrega skill("design-exploration-methodology")
│   ├── business-rules.md     all    — carrega skill("business-rules-methodology")
│   ├── doc.md                all    — carrega skill("documentation-conventions")
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
    └── dev-workflow-procedure/SKILL.md
```

## Pipeline de execução

```
lead-dev-agent (primary)
└── carrega skill("lead-dev-workflow")
    ├── invoca business-rules → skill("business-rules-methodology")
    ├── invoca ideas-agent → skill("design-exploration-methodology")
    ├── invoca scope-guard-agent → skill("scope-validation")
    └── invoca code-workflow (all)
        └── carrega skill("code-pipeline-9phases")
            ├── invoca dev-agent → skill("dev-implementation-standards")
            ├── invoca scope-guard-agent
            ├── invoca review-agent → skill("code-review-checklist")
            └── invoca doc → skill("documentation-conventions")
```

## Como usar

1. Selecione `lead-dev-agent` como agente primário (`@lead-dev-agent`)
2. Ele carrega a skill `lead-dev-workflow` automaticamente
3. Siga o fluxo de 7 passos: Análise → Decomposição → Scope → Plano → Execução → Verificação → Relatório
