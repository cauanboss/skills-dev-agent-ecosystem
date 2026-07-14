# Dev Agent Ecosystem

Ecossistema auto-gerido de agentes de desenvolvimento para o [Kilo CLI](https://kilo.ai). Orquestra todo o ciclo de vida de uma feature: análise, decomposição, implementação, revisão e documentação — sem duplicação, sem dispersão.

```
skills-dev-agent-ecosystem/
├── .kilo/
│   ├── agent/       ← 9 agentes (cada um carrega uma skill)
│   ├── skills/      ← 8 skills (workflows detalhados)
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
| **`lead-dev-agent`** | `primary` | Orquestrador central. Decompõe features, valida escopo, explora arquitetura, delega execução e consolida resultados. NUNCA edita código fonte. |
| **`code-workflow`** | `all` | Pipeline de 9 fases. Detecta stack, implementa via dev-agent, valida escopo, revisa código e testes, roda lint, atualiza docs e reporta. |
| **`agent-governance`** | `all` | Cria, valida e reconstrói agentes e skills do ecossistema a partir do documento-fonte autoritativo. |

### Subagentes (invocados via Task)

| Agente | Modo | Função |
|---|---|---|
| **`dev-agent`** | `subagent` | Escreve código seguindo convenções do projeto. Implementa features, corrige bugs, escreve testes, roda lint. NÃO delega. |
| **`review-agent`** | `subagent` | Revisa código (qualquer linguagem). Foco em bugs, segurança, regressões, SQL, UX, manutenibilidade e performance. NÃO edita código. |
| **`scope-guard-agent`** | `subagent` | Valida escopo pré e pós-código. Classifica cada item como aprovado, borderline ou bloqueado. NÃO implementa. |
| **`ideas-agent`** | `subagent` | Explora alternativas de design e arquitetura. Gera 2-4 opções com trade-offs e recomenda a mais adequada. |
| **`business-rules`** | `subagent` | Mapeia, documenta e valida regras de negócio do domínio. Rastreia regras no código, identifica lacunas e inconsistências. |
| **`doc`** | `subagent` | Atualiza documentação técnica: READMEs, API docs, documentação de banco, changelogs. Só edita arquivos `.md`. |

---

## Skills

Cada skill é um `SKILL.md` dentro de `.kilo/skills/<nome>/`, carregado automaticamente pelo agente correspondente.

| Skill | Carregada por | Contém |
|---|---|---|
| **`lead-dev-workflow`** | `lead-dev-agent` | Fluxo de 7 passos: análise → decomposição → validação de escopo → plano → execução orquestrada → verificação cross-task → relatório final com PR |
| **`code-pipeline-9phases`** | `code-workflow` | Pipeline de 9 fases: DETECT → CODE → LINT → SCOPE → REVIEW → TEST → TEST_REVIEW → DOCS → REPORT |
| **`scope-validation`** | `scope-guard-agent` | Classificação pré/pós-código com critérios, formato de saída e anti-padrões |
| **`code-review-checklist`** | `review-agent` | Ordem de análise, database review, categorias blocker/bug/alerta/sugestão, anti-padrões |
| **`design-exploration-methodology`** | `ideas-agent` | Metodologia de 4 passos: entendimento → geração (2-4 alternativas) → análise → recomendação |
| **`business-rules-methodology`** | `business-rules` | Ordem de investigação, formato de saída, categorias de regras (validação, cálculo, workflow, integração, erro, config) |
| **`documentation-conventions`** | `doc` | Diretrizes de estilo, estrutura de READMEs, documentação de API e banco |
| **`dev-implementation-standards`** | `dev-agent` | Convenções por linguagem (Go, TypeScript, Python, GDScript, C#) com regras de scope creep e verificação local |

---

## Pipeline

```
lead-dev-agent (primary)
└── carrega skill("lead-dev-workflow")
    ├── invoca business-rules      (regras de negócio do domínio)
    ├── invoca ideas-agent         (design/arquitetura, se ambíguo)
    ├── invoca scope-guard-agent   (validação pré-código)
    └── invoca code-workflow (all)
        └── carrega skill("code-pipeline-9phases")
            ├── invoca dev-agent           (implementação)
            ├── invoca scope-guard-agent   (validação pós-código)
            ├── invoca review-agent        (revisão de código)
            └── invoca doc                 (documentação)
```

### Fluxo simplificado

1. Selecione `@lead-dev-agent` como agente primário
2. Ele carrega a skill `lead-dev-workflow` automaticamente
3. Siga os 7 passos: **Análise** → **Decomposição** → **Scope** → **Plano** → **Execução** → **Verificação** → **Relatório + PR**

---

## Instalação

### 1. Clonar o repositório

```bash
git clone https://github.com/cauanboss/skills-dev-agent-ecosystem.git
cd skills-dev-agent-ecosystem
```

### 2. Ativar hooks de auto-sync (recomendado)

```bash
git config core.hooksPath .githooks
```

A partir de agora, todo commit que alterar agentes ou skills sincroniza automaticamente para `~/.config/kilo/`.

### 3. Verificar instalação

```bash
ls ~/.config/kilo/agent/    # deve mostrar 9 agentes
ls ~/.config/kilo/skills/   # deve mostrar 8 skills
```

---

## Como usar

### Em qualquer projeto Kilo

O ecossistema é carregado automaticamente pelo Kilo via `~/.config/kilo/`. Basta selecionar um agente:

```
@lead-dev-agent          → orquestrador completo (7 passos)
@code-workflow           → pipeline 9 fases direto
@agent-governance        → gerenciar agentes/skills
```

### Fluxo completo (recomendado)

```
@lead-dev-agent
"Implementar feature de notificações push"
```

O `lead-dev-agent` vai:
1. Analisar o contexto do projeto (`AGENTS.md`, serviços, domínios)
2. Invocar `business-rules` se precisar mapear regras de negócio
3. Invocar `ideas-agent` se houver ambiguidade arquitetural
4. Invocar `scope-guard-agent` para validar o plano
5. Apresentar o plano e aguardar confirmação
6. Delegar tarefas ao `code-workflow` (paralelizando quando possível)
7. Verificar consistência cross-task
8. Gerar `pr-description.md` com relatório final

### Tarefa direta

```
@code-workflow
"Criar endpoint GET /api/users/:id no serviço users"
```

O `code-workflow` executa as 9 fases e invoca os subagentes necessários.

---

## Manter sincronizado

### Auto-sync (git hooks)

Quando ativados, os hooks em `.githooks/` disparam sync automático para `~/.config/kilo/`:

| Hook | Quando |
|---|---|
| `post-commit` | Após commit com mudanças em `.kilo/agent/` ou `.kilo/skills/` |
| `post-merge` | Após `git pull` ou `git merge` que altere o ecossistema |
| `post-checkout` | Após `git checkout` com mudanças no ecossistema |

### Sync manual

```bash
# Do próprio ecossistema
./scripts/sync-ecosystem.sh              # global apenas
./scripts/sync-ecosystem.sh --all        # global + rondas-microservices
./scripts/sync-ecosystem.sh --check      # dry-run (só diferenças)

# Ou via comando Kilo (invoca o script)
/sync-ecosystem
/sync-ecosystem --all
/sync-ecosystem --check
```

### De dentro de um projeto

Projetos com cópias locais dos agentes (ex: `rondas-microservices`):

```
/pull-ecosystem
```

### Cadeia completa

```
skills-dev-agent-ecosystem/.kilo/    ← fonte canônica (edite aqui)
       │
       ├── git hooks (auto) ────────→ ~/.config/kilo/   ← global
       │
       ├── /sync-ecosystem ─────────→ global + rondas
       │
       └── scripts/sync-ecosystem.sh ──→ global + rondas
```

---

## Integração com projetos

| Projeto | Agentes locais | Skills locais | `kilo.json` | `AGENTS.md` próprio |
|---|---|---|---|---|
| `rondas-microservices` | Sim (sincronizado) | Sim (sincronizado) | Sim | Sim (convenções Go) |
| `patrol` | Não (usa global) | Não (usa global) | Sim | Sim (stack Node/Zflow) |
| `linux` | Não (ecossistema Cursor) | Não (ecossistema Cursor) | Não | Sim (adaptação Cursor) |

---

## Arquitetura

### Separação de responsabilidades

```
lead-dev-agent        → orquestra, NUNCA edita código
code-workflow         → pipeline, gerencia subagentes
dev-agent             → edita código, NÃO delega
review-agent          → revisa, NÃO edita
scope-guard-agent     → valida escopo, NÃO age
ideas-agent           → explora design, NÃO implementa
business-rules        → mapeia domínio, NÃO produz código
doc                   → documenta, NÃO edita código fonte
agent-governance      → gerencia o ecossistema
```

Cada agente tem permissões restritas no `kilo.json` e no frontmatter do próprio agente, garantindo que cada um faça apenas o que deve.

### Modos de agente

| Modo | Pode ser selecionado como primário? | Pode ser invocado via Task? |
|---|---|---|
| `primary` | Sim | Não |
| `subagent` | Não | Sim |
| `all` | Sim | Sim |

---

## Contribuir

1. Edite os arquivos em `.kilo/agent/` ou `.kilo/skills/`
2. Commit — os hooks disparam sync automático para global
3. Se precisar atualizar também projetos com cópias locais:

```bash
./scripts/sync-ecosystem.sh --all
```

### Boas práticas

- Cada agente deve ter uma responsabilidade única e bem definida
- Skills são workflows detalhados — o agente define **quem** faz, a skill define **como**
- Não duplicar funcionalidade entre agentes — preferir composição
- Manter permissões restritas ao mínimo necessário
- `AGENTS.md` é a fonte canônica do pipeline — editar lá, não em `agent-governance.md`

---

## Licença

MIT
