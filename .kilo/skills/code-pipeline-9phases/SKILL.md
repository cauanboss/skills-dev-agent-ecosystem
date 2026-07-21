---
name: code-pipeline-9phases
description: Pipeline completo de implementação em 9 fases — detecta stack, implementa via dev-agent (com TDD), valida escopo, revisa código e testes, roda lint e tests, atualiza docs e reporta
---

# code-pipeline-9phases

Pipeline de 9 fases obrigatório para implementação de tarefas de código. Use como referência ao atuar como code-workflow.

## Regras fundamentais

- **Regra de ouro:** implementar apenas o que foi pedido. Proibido scope creep.
- Gerencia internamente: `dev-agent` (código), `scope-guard-agent` (escopo), `review-agent` (revisão), `doc` (documentação).
- Usa `todowrite` para acompanhar o progresso das 9 fases.
- **SEMPRE** use `rtk <cmd>` para comandos shell. **NUNCA** use comandos shell sem `rtk`. Economia de tokens é obrigatória, não opcional.
- O contexto recebido do `lead-dev-agent` pode incluir `.agents/services/*.md`, `.agents/domains/*.md`, `tdd_mode`, e trechos do `AGENTS.md`. Use esses arquivos como referência obrigatória.
- **TDD mode**: recebido via `tdd_mode` do contexto da tarefa. Comportamento:
  - `strict`: RED→GREEN obrigatório. Fase 2 segue o ciclo TDD completo.
  - `relaxed`: RED→GREEN sugerido. Fase 2 tenta TDD, mas prossegue se inviável.
  - `off`: Fase 2 tradicional (sem TDD). Para config/docs/explore.
  - Se não especificado, default é `relaxed`.

## Pipeline (obrigatório, em ordem)

### Fase 1 — DETECT
- Lê AGENTS.md, .agents/ (serviços e domínios afetados), go.mod, Makefile.
- Detecta: `lint_command`, `test_command`, `format_command`.
- Se o repositório é multimódulo Go, o test_command varia por módulo (`go test ./...` no módulo, não na raiz).
- Falha: pergunta ao usuário.

### Fase 2 — CODE (com TDD)

O comportamento desta fase depende do `tdd_mode` recebido do contexto.

#### Modo `strict` (TDD obrigatório)

**Fase 2a — RED (escrever teste que falha)**

1. **Identificar seams** — antes de qualquer código, identifique as seams públicas relevantes (interfaces, handlers, endpoints) e confirme com o contexto da tarefa.
2. **Invoca `dev-agent`** para escrever APENAS o teste que deve falhar:
   - O prompt deve especificar: "Escreva apenas o teste. Não implemente a feature ainda. O teste DEVE falhar."
   - Inclui contexto: `.agents/services/*.md`, `.agents/domains/*.md`, convenções do AGENTS.md.
3. **Verifica RED** — executa `test_command`:
   - Se **falhou** (RED): continua para Fase 2b.
   - Se **passou**: o teste não cobre o cenário. Retorna ao dev-agent para corrigir o teste (1 tentativa).
   - Se **erro de compilação**: esperado (a feature não existe ainda), continua para Fase 2b.

**Fase 2b — GREEN (implementar o mínimo)**

4. **Invoca `dev-agent`** para implementar APENAS o suficiente para o teste passar:
   - O prompt deve especificar: "Implemente o mínimo necessário para o teste passar. NÃO adicione features não testadas."
   - Inclui o arquivo de teste como referência.
5. **Verifica GREEN** — executa `test_command`:
   - Se **passou** (GREEN): continua para Fase 3.
   - Se **falhou**: invoca `dev-agent` para corrigir (1 tentativa). Se falhar de novo, aborta e reporta.

**Regra do ciclo**: se a tarefa tem múltiplas seams, repete RED→GREEN para cada seam (uma fatia vertical por vez), nunca todas de uma vez (anti-padrão: horizontal slicing).

#### Modo `relaxed` (TDD sugerido)

- Segue o mesmo fluxo do `strict`, mas se o dev-agent não conseguir escrever um teste significativo (ex: CRUD simples, script), pode pular RED e ir direto para GREEN.
- Registra no relatório quando TDD foi pulado e justificativa.

#### Modo `off` (sem TDD)

- Invoca `dev-agent` via Task (subagent_type: `"dev-agent"`) com o fluxo tradicional.
- Inclui no prompt do dev-agent:
  - Os arquivos `.agents/services/*.md` do serviço afetado
  - Os arquivos `.agents/domains/*.md` relevantes (naming, testing, config, errors)
  - As convenções do projeto do AGENTS.md
- Verifica se arquivos esperados foram criados (`rtk git diff --stat`).

**Falha em qualquer modo**: retry 1x, depois aborta e reporta ao lead-dev-agent.

### Fase 3 — LINT  ────┐
### Fase 4 — SCOPE VALIDATION ────┤ (paralelo: LINT e SCOPE são independentes)

Estas duas fases rodam em paralelo — LINT verifica estilo, SCOPE verifica escopo. Nenhuma depende da outra.

#### Fase 3 — LINT
- Executa `lint_command` via `rtk`.
- Se issues: executa `format_command`, re-lint (máx 2 ciclos).
- Se persiste: pergunta ao usuário.

#### Fase 4 — SCOPE VALIDATION
- Invoca `scope-guard-agent` via Task (subagent_type: `"scope-guard-agent"`).
- **Aprovado**: continua para Fase 5.
- **Borderline**: reporta ao lead-dev-agent com justificativa. NÃO pergunta ao usuário.
- **Bloqueado**: reverte alterações, reporta ao lead-dev-agent.

### Fase 5 — CODE REVIEW
- Invoca `review-agent` via Task (subagent_type: `"review-agent"`) com `git diff`.
- Se a task alterou arquivos de banco (`.sql`, `migrations/`, `repository/`, `model/`, `schema/`, `graphql/`), invoca também **`db-agent`** para revisão especializada de banco.
- Prompt pede categorização: blocker / bug / alerta / sugestão.
- **blocker**: ABORTA e reporta ao lead-dev-agent.
- **bug**: corrige + re-review (máx 2 ciclos).
- **alerta/sugestão**: registra e prossegue.
- Bugs residuais pós 2 ciclos: flag e prossegue.

### Fase 5.1 — DB REVIEW (se aplicável)
Se a task alterou arquivos de banco, após o CODE REVIEW padrão:
- Invoca `db-agent` via Task (subagent_type: `"db-agent"`) com o diff e contexto.
- Escopo da revisão: índices, queries, migrations, tipos, transações, N+1, cache.
- Findings do db-agent seguem a mesma categorização (blocker / bug / alerta / sugestão).
- **blocker**: ABORTA e reporta ao lead-dev-agent.
- **bug**: encaminha para dev-agent corrigir + re-review (máx 2 ciclos).
- **alerta/sugestão**: registra no relatório.

### Fase 6 — TEST
- Executa `test_command` via `rtk`.
- **Multimódulo Go**: roda `go test ./...` no módulo específico (`services/<serviço>/`), NÃO na raiz do repositório. Use `scripts/test-all-modules.sh` para mudanças transversais.
- Passou: continua para Fase 7.
- Sem testes: continua com nota.
- Falhou: invoca `dev-agent` para corrigir (1 tentativa). "passed after retry" ou flag.

### Fase 7 — TEST REVIEW  ────┐
### Fase 8 — DOCS         ────┤ (paralelo: TEST REVIEW e DOCS são independentes)

Estas duas fases rodam em paralelo — revisão de testes e documentação não competem por recursos.

#### Fase 7 — TEST REVIEW
- Invoca `review-agent` focado em qualidade de testes.
- Critérios: edge cases, assertivas, legibilidade, determinismo, isolamento.
- Issues: auto-fix, flag no relatório. NÃO bloqueia.

#### Fase 8 — DOCS
- Invoca `doc` via Task (subagent_type: `"doc"`).
- Passa lista de arquivos alterados e resumo das mudanças.
- Se `doc` retornar skip ou sem docs: nota no relatório. NÃO bloqueia.

### Fase 9 — REPORT
- Relatório consolidado com status de cada fase.
- Formato: tabela com 9 linhas (uma por fase).
- Arquivos alterados com +N/-N.
- Notas, riscos, status final.
- Inclui o `tdd_mode` usado e, se `relaxed`, quais tarefas pularam TDD e justificativa.
- Verificar: `rtk git diff --stat` mostra apenas arquivos esperados, sem secrets/PII.

## Diagrama de paralelismo

```
Fase 1: DETECT
    │
Fase 2: CODE (RED → GREEN se TDD)
    │
    ├── Fase 3: LINT          ──┐
    └── Fase 4: SCOPE         ──┤ paralelo
                                 │
Fase 5: CODE REVIEW             │
Fase 5.1: DB REVIEW (se app)    │
    │                            │
Fase 6: TEST                    │
    │                            │
    ├── Fase 7: TEST REVIEW   ──┤
    └── Fase 8: DOCS          ──┘ paralelo
                                 │
Fase 9: REPORT                  │
```

## Convenções de branching e commits

Convenções de branching e commits são específicas de cada projeto/organização.
Defina-as no `AGENTS.md` do projeto ou em `.kilo/command/*.md` — não neste skill universal.

### Exemplo (projetos Zflow)
```yaml
# AGENTS.md ou .kilo/command/git-conventions.md
branches:
  feature: feature/id-do-card a partir de development
  fix: fix/id-do-card a partir de development
  hotfix: hotfix/descricao-curta a partir de main
commits: Conventional Commits (feat, fix, docs, refactor, chore)
```
