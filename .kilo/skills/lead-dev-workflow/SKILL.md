---
name: lead-dev-workflow
description: Fluxo completo do lead-dev-agent — análise, decomposição, validação de escopo, plano, execução orquestrada, verificação cross-task e relatório final com PR
---

# lead-dev-workflow

Workflow de 7 passos para orquestração de desenvolvimento. Use como referência obrigatória ao atuar como lead-dev-agent.

## Passo 1 — Análise

Lê `AGENTS.md`, `.agents/`, código existente. Invoca conforme detecção:

- **Sempre**: lê `AGENTS.md` (fonte canônica) e identifica serviços/domínios afetados.
- **`business-rules`** — se houver regras de negócio desconhecidas ou ambiguidade no domínio.
- **`ideas-agent`** — se houver ambiguidade arquitetural, múltiplas abordagens possíveis, ou stack não definida (ver Critérios de invocação do ideas-agent abaixo).
- **`doc`** — se houver documentação existente que precise ser consultada.

### Critérios de invocação do ideas-agent

Invocar o `ideas-agent` durante a Análise quando **qualquer** critério abaixo for verdadeiro:

| Critério | Descrição |
|---|---|
| **Ambiguidade arquitetural** | Múltiplas abordagens viáveis e não óbvias (ex: novo serviço vs endpoint em serviço existente, SQL vs evento, síncrono vs async). |
| **Stack não definida** | A demanda não tem stack consolidada no projeto (ex: primeira tela web, primeiro consumer de fila). |
| **Tech debt significativo** | A feature requer modificar uma área com dívida técnica conhecida — decidir se refatora antes ou contorna. |
| **Impacto cross-module** | A feature afeta 3+ serviços não relacionados, exigindo decisão de acoplamento ou interface. |
| **Remoção de legado** | A feature convive com padrão legado (`domain/errors`, `os.Getenv` direto) e requer decisão de migrar ou não. |

Se **nenhum** critério for atendido, pular `ideas-agent` e prosseguir direto para a Decomposição.

## Passo 2 — Decomposição

Transforma objetivo em tarefas com a seguinte estrutura:

```yaml
- id: "T1"
  type: code | test | config | doc | explore
  description: "..."
  subagent_type: "code-workflow"  # para code/test/config
  depends_on: ["T0"]              # IDs das tarefas que devem concluir primeiro
```

- **Dependências**: identificar tarefas que compartilham schema, migrações, contracts de API, ou módulos sobrepostos. Tarefas com `depends_on` são executadas após as dependências concluírem. Tarefas sem dependências mútuas podem ser paralelizadas.
- **Multimódulo Go**: cada módulo (`services/*/`) é independente. Tarefas em módulos diferentes são candidatas a paralelização. Tarefas no mesmo módulo devem ser sequenciais se houver overlap de arquivos.
- **Contexto adicional**: para cada tarefa, inclua no prompt do subagente:
  - Os arquivos `.agents/services/<serviço>.md` relevantes
  - Os arquivos `.agents/domains/<tema>.md` relevantes (naming, testing, config, errors, etc.)
  - As convenções do projeto do `AGENTS.md`

## Passo 3 — Validação de escopo pré-código

Invoca `scope-guard-agent` com o plano completo (tarefas + dependências). Tarefas bloqueadas → remove. Borderline → esclarece. Ajusta dependências se tarefas forem removidas.

## Passo 4 — Apresentação do plano

Apresenta a lista de tarefas com dependências e ordem de execução. Aguarda confirmação do usuário. **Timeout**: se o usuário não responder em 2 minutos, prossegue automaticamente com o plano apresentado.

## Passo 5 — Execução orquestrada

Delega cada tarefa ao `code-workflow` via Task. Ordem:

- **Lote 1**: tarefas sem `depends_on` (paralelo, máx 3 simultâneos).
- **Lote N**: tarefas cujas dependências foram concluídas (máx 3 simultâneos).
- **Barreira**: se uma tarefa falha após 2 retentativas, as tarefas que dependem dela são reavaliadas (podem ser ajustadas ou removidas do escopo).
- **Conflito de merge**: se duas tarefas paralelas alteram o mesmo arquivo, pausa e reporta ao usuário com o diff dos dois lados.
- **Contexto por tarefa**: o prompt enviado ao `code-workflow` deve incluir:
  - O objetivo específico da tarefa
  - Os arquivos de contexto relevantes (`.agents/services/*.md`, `.agents/domains/*.md`)
  - As convenções do projeto (AGENTS.md: naming, pacotes compartilhados, legado, testes multimódulo)

## Passo 6 — Verificação cross-task

Após todas as tarefas concluírem:

- **Diff consolidado**: inspeciona `git diff` completo (não por tarefa).
- **Conflitos silenciosos**: detecta arquivos alterados por mais de uma tarefa (overwrites, inconsistências).
- **Naming e padrões**: consistência entre tarefas (kebab-case, sem sufixos de papel, sem `os.Getenv` fora de `pkg/config`).
- **Segurança**: escaneia diff por secrets, PII, hardcoded credentials.
- **Segurança produção**: verifica se o diff respeita as políticas de produção (sem alterações em Docker/banco/fila/env sem permissão).
- **Review consolidado** (opcional): se o diff for grande ou houver riscos, invoca `review-agent` com o diff completo para uma revisão unificada.

### Critérios de aceitação por tarefa

1. Subagente reportou sucesso.
2. Relatório Fase 9 do code-workflow mostra Lint e Test (ou justificado).
3. `git diff --stat` mostra apenas arquivos esperados.
4. Nenhum secret/PII no diff.
5. Nenhuma violação das políticas de produção do `AGENTS.md`.

## Passo 7 — Relatório final + PR Description

Consolida resultados e gera arquivo `pr-description.md` na raiz do projeto com o template abaixo preenchido:

```markdown
## O que foi feito?

{resumo das alterações realizadas}

## Como testar?

1. {comando ou passo concreto 1}
2. {comando ou passo concreto 2}
3. {comando ou passo concreto 3 (opcional)}

## Alterações incluídas

- [ ] Código fonte (features/correções)
- [ ] Testes (unitários/integração)
- [ ] Configuração (env, CI/CD, infra)
- [ ] Documentação
- [ ] Banco de dados (schema, migração, seed)
- [ ] Dependências (pacotes, bibliotecas)

## Checklist pré-review

- [ ] Código foi testado localmente (lint + testes passando)?
- [ ] Segue os padrões de arquitetura e estilo do projeto?
- [ ] Altera variáveis de ambiente, banco de dados ou infraestrutura? (Se sim, especificar)
- [ ] Nenhum segredo/credencial foi exposto no diff?
- [ ] Breaking changes foram identificados e documentados?
- [ ] Performance e segurança considerados (N+1, SQL injection, rate limiting)?
```

Regras:
- Os placeholders `{...}` devem ser substituídos por conteúdo real do que foi feito.
- O arquivo gerado fica na raiz do projeto para que o usuário possa copiar direto para a PR no GitHub.
- Se o projeto tiver um arquivo `.kilo/pr-template.md`, usar esse template customizado em vez do padrão.

## Tratamento de falhas

| Cenário | Ação |
|---|---|
| **Scope borderline (pré-código)** | Avalia justificativa do `scope-guard-agent`. Decide: aprovar, consultar o usuário, ou bloquear. |
| **Scope bloqueado (pré-código)** | Remove a tarefa do plano. Ajusta dependências de tarefas que dependiam dela. Se inviabilizar o objetivo, reporta ao usuário. |
| **Timeout do usuário (passo 4)** | Prossegue automaticamente com o plano apresentado após 2 minutos sem resposta. |
| **Falha de implementação (tarefa)** | Máx 2 retentativas por tarefa via `code-workflow`. Na 3ª falha, reporta ao usuário com diagnóstico. Tarefas dependentes são reavaliadas. |
| **Conflito de merge entre tarefas** | Pausa a execução, apresenta os dois lados do diff para o usuário, aguarda decisão. |
| **Tarefa dependente sem conclusão da base** | Reavalia a tarefa bloqueada: pode ser ajustada (escopo reduzido) ou removida. Reporta ao usuário se o objetivo for inviabilizado. |
| **Ambiente/infraestrutura** | Reporta e pausa. Não faz retentativa automática. |
| **Secrets/PII no diff** | Bloqueia a tarefa. Reporta ao usuário com a localização exata. Não prossegue até resolução. |
| **Violação de produção** | Bloqueia imediatamente. Reporta qual política foi violada (Docker/banco/fila/env/secret). |
| **Retentativas exauridas** | Após 2 retentativas sem sucesso, reporta ao usuário com resumo das tentativas e diagnóstico. Não faz 3ª tentativa automática. |
