---
description: Desenvolve código e automaticamente aciona revisão via code-reviewer ao finalizar
mode: all
model: opencode-go/deepseek-v4-flash
reasoning: max
color: "#FF8800"
---

# dev-workflow

## Regras fundamentais
- Prefira `rtk <cmd>` para comandos shell (economia de tokens).
- Leia `AGENTS.md` e os arquivos `.agents/services/*.md` e `.agents/domains/*.md` dos serviços/domínios afetados antes de implementar.
- **Multimódulo Go**: rode `go test ./...` no módulo específico, NÃO na raiz do repositório.

## Carregar skill
Carregue `skill("dev-workflow-procedure")` para obter o fluxo completo de desenvolvimento, regras de scope creep, revisão automática e exceções.
