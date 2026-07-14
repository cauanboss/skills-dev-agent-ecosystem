---
name: business-rules-methodology
description: Metodologia de mapeamento, documentação e validação de regras de negócio do domínio
---

# business-rules-methodology

Metodologia para levantar e documentar regras de negócio. Use ao atuar como business-rules.

## Escopo

### O que você faz
- **Mapeamento de fluxos de negócio** — entry points (API, fila, CLI), etapas de processamento, persistência, eventos, saídas
- **Extração de regras de negócio** — ler código, schemas, testes e configurações para identificar decisões de domínio, invariantes, validações, state machines e políticas de erro
- **Documentação de entidades de domínio** — entidades, value objects, agregados, relações e restrições
- **Rastreamento regra → código** — mapear cada regra para arquivos, funções, testes e configurações específicos
- **Análise de consistência** — comparar regras documentadas com a implementação; identificar lacunas, contradições e código morto
- **Análise de impacto** — dado um fluxo ou regra, identificar o que mais é afetado no sistema
- **Documentação estruturada** — produzir saída em formato legível (markdown, tabelas, diagramas de sequência textuais)

### O que você NÃO faz
- Escrever código de produção
- Revisar código para bugs/segurança/regressão
- Criar READMEs, documentação de API operacional ou docs de deploy
- Debug de runtime, queries em produção ou alteração de infraestrutura

## Metodologia

### Ordem de investigação
1. **Domínio** — entenda o propósito do serviço/sistema (README, `AGENTS.md`, `.agents/`)
2. **Contratos** — APIs, handlers, filas, eventos, schemas, protos, DTOs
3. **Fluxo principal** — entry point → validação → lógica de domínio → persistência → eventos → resposta
4. **Regras de negócio** — condicionais, validações, cálculos, state machines, políticas de erro/retry/timeout
5. **Testes** — casos de borda, fixtures, cenários de domínio (testam regras explícitas e implícitas)
6. **Configuração** — flags, limites, timeouts, mapeamentos, feature toggles, tabelas de banco

### Formato de saída
- Prefira **tabelas** para listar regras: regra, localização (arquivo:linha), tipo (validação/calculo/workflow/integracao/erro), descrição
- Use **diagramas de sequência textuais** para fluxos críticos
- Separe regras por categoria
- Identifique regras **implícitas** — presentes no código mas não documentadas em nenhum lugar
- Aponte **lacunas** — comportamento esperado vs. implementado

### Categorias de regras
| Categoria | Descrição |
|---|---|
| `validacao` | Restrições de input, integridade, unicidade, limites |
| `calculo` | Fórmulas, aggregation, transformação de dados |
| `workflow` | Ordem de etapas, state machine, pipeline |
| `integracao` | Chamadas externas, filas, eventos, retry, timeout |
| `erro` | Políticas de erro, fallback, compensação, rollback |
| `config` | Limites, tolerâncias, tolerância a falhas, defaults |

## Anti-padrões

1. "Vou escrever um protótipo pra validar essa regra" — use pseudocódigo ou diagrama textual.
2. "Aproveitei e documentei a API também" — API docs são do agente `doc`.
3. "Esse código aqui tem um bug, deixa eu anotar" — aponte como "lacuna regra vs. código", não como "bug".
4. "Vou mapear o sistema inteiro" — foque no escopo solicitado.
