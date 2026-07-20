# Dev Agent Ecosystem

Ecossistema auto-gerido de agentes de desenvolvimento para o [Kilo CLI](https://kilo.ai). Orquestra todo o ciclo de vida de uma feature: alinhamento, análise, decomposição, implementação (com TDD), debugging, revisão e documentação — sem duplicação, sem dispersão.

```
skills-dev-agent-ecosystem/
├── .kilo/
│   ├── agent/       ← 11 agentes (cada um carrega uma skill)
│   ├── skills/      ← 10 skills (workflows detalhados)
│   ├── command/     ← comandos Kilo (/sync-ecosystem)
│   └── kilo.json    ← config do ecossistema
├── .githooks/       ← hooks auto-sync (post-commit, post-merge, post-checkout)
├── scripts/         ← script de sync reutilizável
├── AGENTS.md        ← pipeline canônico + integração com projetos
└── README.md        ← este arquivo
```

---

## Agentes

Cada agente é um arquivo `.kilo/agent/<nome>.md` com modo, modelo, permissões e instruções.

### Primários (invocáveis diretamente)

| Agente | Modo | Função |
|---|---|---|
| **`lead-dev-agent`** | `primary` | Orquestrador central. Fluxo de 8 passos: Alinhamento → Análise → Decomposição → Scope → Plano → Execução → Verificação → Relatório + PR + Handoff. NUNCA edita código fonte. |
| **`code-workflow`** | `all` | Pipeline de 9 fases com TDD (strict/relaxed/off), fases paralelizáveis e integração com bug-hunter. Detecta stack, implementa via dev-agent, valida escopo, revisa código e testes, roda lint, atualiza docs e reporta. |
| **`agent-governance`** | `all` | Cria, valida e reconstrói agentes e skills do ecossistema a partir do documento-fonte autoritativo. |
| **`bug-hunter`** | `all` | Diagnostica bugs com loop estruturado de 6 fases. Invocável diretamente ou automaticamente pelo code-workflow em falhas não-triviais. |

### Subagentes (invocados via Task)

| Agente | Modo | Função |
|---|---|---|
| **`dev-agent`** | `subagent` | Escreve código seguindo convenções do projeto. Suporta TDD (RED→GREEN). NÃO delega. |
| **`review-agent`** | `subagent` | Revisa código (qualquer linguagem). Foco em bugs, segurança, regressões, SQL, UX, manutenibilidade e performance. NÃO edita código. |
| **`scope-guard-agent`** | `subagent` | Valida escopo pré e pós-código. Classifica cada item como aprovado, borderline ou bloqueado. NÃO implementa. |
| **`ideas-agent`** | `subagent` | Explora alternativas de design e arquitetura. Gera 2-4 opções com trade-offs, prototipagem executável opcional e recomendação. |
| **`business-rules`** | `subagent` | Mapeia, documenta e valida regras de negócio do domínio. Rastreia regras no código, identifica lacunas e inconsistências. |
| **`doc`** | `subagent` | Atualiza documentação técnica: READMEs, API docs, documentação de banco, changelogs. Só edita arquivos `.md`. |
| **`db-agent`** | `all` | Especialista em bancos de dados — SQL, NoSQL, caches e GraphQL. Modela schemas, otimiza queries, projeta migrações. |

---

## Skills

| Skill | Carregada por | Contém |
|---|---|---|
| **`lead-dev-workflow`** | `lead-dev-agent` | Fluxo de 8 passos: Alinhamento → Análise → Decomposição (com tracker) → Validação de escopo → Plano → Execução orquestrada → Verificação cross-task → Relatório final com PR + Handoff |
| **`code-pipeline-9phases`** | `code-workflow` | Pipeline de 9 fases com TDD (RED→GREEN), paralelismo (LINT∥SCOPE, TEST_REVIEW∥DOCS) e integração com bug-hunter |
| **`scope-validation`** | `scope-guard-agent` | Classificação pré/pós-código com critérios, formato de saída e anti-padrões |
| **`code-review-checklist`** | `review-agent` | Ordem de análise, database review, categorias blocker/bug/alerta/sugestão, anti-padrões |
| **`design-exploration-methodology`** | `ideas-agent` | Metodologia de 5 passos: entendimento → geração (2-4 alternativas) → prototipagem (opcional) → análise → recomendação |
| **`business-rules-methodology`** | `business-rules` | Ordem de investigação, formato de saída, categorias de regras |
| **`documentation-conventions`** | `doc` | Diretrizes de estilo, estrutura de READMEs, documentação de API e banco |
| **`dev-implementation-standards`** | `dev-agent` | Convenções por linguagem (Go, TS, Python, GDScript, C#) com regras de scope creep e verificação local |
| **`database-expertise`** | `db-agent` | Modelagem, otimização, migração e revisão de bancos de dados |
| **`bug-diagnosis`** | `bug-hunter` | Loop estruturado de 6 fases: feedback → reproduzir/minimizar → hipóteses → instrumentar → corrigir + regressão → cleanup + post-mortem |

---

## Pipeline (8 passos)

```
lead-dev-agent (primary)
└── carrega skill("lead-dev-workflow")
    ├── Passo 0 — Alinhamento (entrevista o usuário)
    ├── Passo 1 — Análise (AGENTS.md + subagentes)
    ├── Passo 2 — Decomposição (tarefas + tdd_mode + tracker)
    ├── Passo 3 — Validação de escopo
    ├── Passo 4 — Apresentação do plano
    ├── Passo 5 — Execução orquestrada
    │   └── code-workflow (9 fases com TDD e paralelismo)
    ├── Passo 6 — Verificação cross-task
    └── Passo 7 — Relatório + PR Description + Handoff
```

### Fluxo simplificado

1. Selecione `@lead-dev-agent` como agente primário
2. Ele carrega a skill `lead-dev-workflow` automaticamente
3. Siga os 8 passos: **Alinhamento → Análise → Decomposição → Scope → Plano → Execução → Verificação → Relatório**

---

## Novidades (v2.0)

| Melhoria | Onda | Descrição |
|---|---|---|
| **Passo 0 — Alinhamento** | 1 | Entrevista o usuário sobre edge cases, restrições e critérios de sucesso antes de qualquer análise. Elimina a falha #1 do desenvolvimento com agentes. |
| **TDD (RED→GREEN)** | 1 | Fase 2 do pipeline agora suporta `strict` (obrigatório), `relaxed` (sugerido) ou `off`. RED: escrever teste falhando. GREEN: implementar o mínimo para passar. |
| **Bug diagnosis** | 2 | Nova skill + agente `bug-hunter` com loop de 6 fases para debugging estruturado. Invocado automaticamente pelo code-workflow em falhas não-triviais. |
| **Tracker integration** | 2 | Passo 2.1 publica tickets decompostos no issue tracker (GitHub Issues, etc.) com dependências explícitas. |
| **Paralelismo** | 3 | Fases independentes rodam em paralelo: LINT∥SCOPE, TEST_REVIEW∥DOCS. Diagrama de paralelismo documentado no pipeline. |
| **Prototipagem** | 3 | `ideas-agent` agora constrói protótipos executáveis descartáveis para responder perguntas de design (state model, UI, performance, integração). |
| **Handoff** | 3 | Passo 7 gera `.kilo/handoff/<feature>.md` para continuidade entre sessões em features grandes. |

---

## Instalação

```bash
git clone https://github.com/cauanboss/skills-dev-agent-ecosystem.git
cd skills-dev-agent-ecosystem
git config core.hooksPath .githooks   # auto-sync
```

---

## Licença

MIT
