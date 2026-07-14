---
name: dev-implementation-standards
description: Padrões de implementação por linguagem — Go, TypeScript, Python, GDScript, C# Godot — com regras de scope creep e verificação local
---

# dev-implementation-standards

Padrões e convenções para implementação de código. Use ao atuar como dev-agent.

## Regras fundamentais

- **Regra de ouro:** implementar apenas o que foi pedido. Proibido scope creep.
- NÃO delega para outros agentes — implementa diretamente.
- NÃO revisa código (isso é do `review-agent`).
- NÃO valida escopo (isso é do `scope-guard-agent`).

## Fluxo de implementação

1. **Análise do contexto** — lê AGENTS.md, .agents/, inspeciona código similar.
   - O contexto pode incluir arquivos `.agents/services/*.md` e `.agents/domains/*.md` — usá-los como referência obrigatória.
   - Se houver um **Database Implementation Guide** no contexto, segui-lo obrigatoriamente para queries, índices, ORM patterns e transações.
2. **Implementação** — segue convenções (naming, estrutura, padrões de erro/logging).
   - Produção read-only. Nunca hardcoda secrets/PII/connection strings.
   - Usa pacotes padrão do projeto (`pkg/errors`, `pkg/validation`, `pkg/config`).
   - Queries SQL: **sempre usar parameterized queries/binding** — proibido string interpolation.
   - Transações: escopo mínimo, propagar contexto (`ctx`), rollback em erro.
   - Cria/atualiza testes unitários e de integração se houver banco.
3. **Verificação local** — roda linter e testes via `rtk`. Corrige até passarem limpos.
   - **Multimódulo Go**: roda `go test ./...` no módulo específico, NÃO na raiz.
   - Verifica `rtk git diff --stat` mostra apenas alterações esperadas.
4. **Reporte** — lista arquivos criados/alterados, testes, lint, notas.

## 🚫 Regra de ouro: faça apenas o que foi pedido

Antes de começar qualquer tarefa, reformule mentalmente o que o usuário pediu. Sua saída final deve corresponder **exatamente** a esse pedido — nem mais, nem menos.

### Comportamentos PROIBIDOS

1. **"Já que mexi nesse arquivo, aproveitei e..."** — NUNCA faça melhorias ou refatorações não solicitadas.
2. **"Ficou melhor se eu também migrar esse outro módulo"** — não expanda o escopo.
3. **"Adicionei uns comentários/DOCs que estavam faltando"** — documentação não solicitada é scope creep.
4. **"Mudei o nome de umas variáveis pra ficar mais claro"** — renomeações que não fazem parte da tarefa são proibidas.

### Se identificar algo fora do escopo
- Se for **crítico** (bug de segurança, vazamento de secret): alerte o usuário após concluir a tarefa.
- Se for **melhoria**: anote e sugira após concluir, mas NÃO execute.
- Se for **dívida técnica**: registre como comentário, não como código.

## Convenções por linguagem

### Go
- `pkg/errors`, `pkg/validation`, table-driven tests, interfaces pequenas.
- Naming: kebab-case para arquivos Go manuais, sem sufixos de papel (`.repository.go`, `.handler.go`) em código novo.
- Pacotes compartilhados: código novo de erro de negócio deve usar `pkg/errors` quando aplicável.
- Config nova deve passar por `pkg/config` ou wrapper existente.
- Sem `os.Getenv` direto fora de `pkg/config`.

### TypeScript
- Tipos explícitos, `const` sobre `let`, async/await.

### Python
- Type hints, PEP 8, pytest.

### GDScript 2.0 (Godot 4)
- Tipagem estática obrigatória: `var health: int`, `func take_damage(amount: int) -> void`.
- `@onready` sobre `get_node()` — nunca chamar `get_node()` em `_process()`.
- `@export` para variáveis expostas no editor.
- `match` sobre `if/elif` encadeado para pattern matching.
- Signals tipados: `signal health_changed(new_health: int)`.
- `_ready()`, `_process(delta)`, `_physics_process(delta)` nos nós corretos.
- `move_and_slide()` para CharacterBody2D/3D; velocity, snap, floor_stop_on_slope.
- Preferir composição de cenas sobre herança profunda.
- Evitar autoload poluído: usar service locator ou injeção.
- Usar grupos (`add_to_group`) para comunicação broadcast.

### C# Godot (Godot 4 + .NET)
- `partial class` extends `Node2D`, `CharacterBody2D`, etc.
- Signals com `[Signal]` attribute.
- `GodotObject`, `GodotSharp` APIs corretas para Godot 4.
- `dotnet format` para lint.
- Hot paths em C#, game logic em GDScript.
