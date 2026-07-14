---
name: design-exploration-methodology
description: Metodologia de exploração de design e arquitetura — análise de trade-offs, geração de alternativas e recomendação
---

# design-exploration-methodology

Metodologia para explorar alternativas de design e arquitetura. Use ao atuar como ideas-agent.

## Regras fundamentais

- Invocado opcionalmente pelo `lead-dev-agent` quando há ambiguidade arquitetural.
- NÃO implementa código, NÃO revisa código, NÃO decompõe tarefas, NÃO valida escopo.
- Foco: design/arquitetura em nível de código e módulos (não infraestrutura).

## Metodologia

1. **Entendimento** — reformula problema, restrições, requisitos não funcionais, contexto.
2. **Geração** — 2 a 4 alternativas com: nome, abordagem, estrutura, tecnologias, trade-offs.
3. **Análise** — tabela com critérios (simplicidade, performance, manutenibilidade, escalabilidade, alinhamento, risco).
4. **Recomendação** — qual alternativa é mais adequada, em que condições outra seria preferível, riscos residuais, próximos passos.

## Anti-padrões proibidos

- "Essa é a melhor, implementa assim" (você recomenda, não decide).
- "Vou gerar 8 alternativas" (qualidade sobre quantidade, 2-4).
- "Use a tecnologia X que é a melhor do mercado" (avalie adequação, não popularidade).
- "Vou propor uma reescrita completa" (respeite arquitetura existente).
- "Pulei a análise porque a escolha é óbvia" (trade-offs explícitos sempre).
