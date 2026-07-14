---
name: dev-workflow-procedure
description: Fluxo de desenvolvimento simplificado — implementação seguindo convenções, lint, testes e revisão automática via code-reviewer
---

# dev-workflow-procedure

Fluxo de desenvolvimento full-cycle com revisão automática. Use ao atuar como dev-workflow.

## Regras fundamentais

- Prefira `rtk <cmd>` para comandos shell (economia de tokens).
- Leia `AGENTS.md` e os arquivos `.agents/services/*.md` e `.agents/domains/*.md` dos serviços/domínios afetados antes de implementar.
- **Multimódulo Go**: rode `go test ./...` no módulo específico, NÃO na raiz do repositório.

## 🚫 Regra de ouro: faça apenas o que foi pedido

Antes de começar qualquer tarefa, reformule mentalmente o que o usuário pediu. Sua saída final deve corresponder **exatamente** a esse pedido — nem mais, nem menos.

### Comportamentos PROIBIDOS

1. **"Já que mexi nesse arquivo, aproveitei e..."** — NUNCA faça melhorias ou refatorações não solicitadas. Cada mudança extra é uma regressão em potencial e dilui o propósito do PR.
2. **"Ficou melhor se eu também migrar esse outro módulo"** — não expanda o escopo. Se você identificar algo que deveria ser feito, informe o usuário como sugestão pós-tarefa, mas NÃO execute.
3. **"Adicionei uns comentários/DOCs que estavam faltando"** — documentação não solicitada é scope creep. Se o pedido foi "corrigir o bug X", entregue a correção do bug X.
4. **"Mudei o nome de umas variáveis pra ficar mais claro"** — renomeações que não fazem parte da tarefa são proibidas. Atrapalham o diff e o blame.

### Se identificar algo fora do escopo

- Se for **crítico** (bug de segurança, vazamento de secret): alerte o usuário após concluir a tarefa.
- Se for **melhoria**: anote e sugira após concluir, mas NÃO execute.
- Se for **dívida técnica**: registre como comentário, não como código.

### Antes de cada ação, pergunte-se

1. Isso está diretamente relacionado ao que o usuário pediu?
2. Se eu fizer isso, o diff fica maior do que o necessário?
3. Eu consigo justificar essa mudança em uma frase?

Se qualquer resposta for "não", não faça.

## Fluxo obrigatório

### 1. Desenvolvimento
- Execute a tarefa de codificação normalmente: analise, edite arquivos, rode testes, garanta que compila.
- Leia `AGENTS.md`, `.agents/services/` e `.agents/domains/` dos serviços/domínios afetados antes de codificar.
- Siga as convenções do projeto (AGENTS.md), incluindo:
  - **Naming**: kebab-case para arquivos Go, sem sufixos de papel (`.repository.go`, `.handler.go`) em código novo.
  - **Pacotes**: use `pkg/errors`, `pkg/validation`, `pkg/config`. Sem `os.Getenv` direto.
  - **Produção**: read-only. Sem secrets/PII/connection strings hardcoded.
  - **Legado**: não force migração de padrão antigo sem escopo explícito.
- **Execute o lint** nos módulos alterados via `rtk <lint_command>`. Use a ferramenta configurada no projeto (verifique `Makefile` ou scripts).
  - Se encontrar avisos, corrija-os e repita o ciclo de testes + lint até ambos passarem limpos.

### 2. Revisão automática
- Após finalizar todas as edições e confirmar que testes passam, você DEVE invocar o agente `code-reviewer` via Task tool.
- Passe para ele:
  - Os arquivos alterados (com caminho completo)
  - O diff das mudanças (`git diff`)
  - Qualquer contexto relevante sobre a tarefa
- Use o formato:
  ```
  Task(
      description: "Revisar <descrição da tarefa>",
      prompt: "Revise as seguintes mudanças:\n\nArquivos: <lista>\n\ndiff:\n<output do git diff>\n\nContexto: <explicação>",
      subagent_type: "code-reviewer",
  )
  ```

### 3. Correção de problemas
- Se o `code-reviewer` apontar problemas, corrija cada um e repita o passo 2.
- Se o revisor disser que está correto, prossiga.

### 4. Finalização
- Só então marque a tarefa como concluída e informe o usuário do resultado.

## Exceções
- Tarefas puramente exploratórias ou de leitura (sem edição de código): dispensa revisão.
- Tarefas de configuração/README/docs: dispensa revisão.
- Em caso de dúvida, sempre prefira revisar.
