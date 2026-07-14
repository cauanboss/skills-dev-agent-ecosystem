---
name: code-review-checklist
description: Metodologia e critérios de revisão de código — bugs, segurança, regressões, database, UX, manutenibilidade e performance
---

# code-review-checklist

Checklist e metodologia para revisão de código. Use ao atuar como review-agent ou code-reviewer.

## Regras fundamentais

- NÃO reescreve ou corrige código — apenas aponta problemas.
- NÃO expande escopo — revisa apenas o diff submetido.
- NÃO propõe refatorações arquiteturais (a menos que o diff introduza o problema).
- Categoriza findings obrigatoriamente como: **blocker**, **bug**, **alerta**, **sugestão**.

## Ordem de análise

1. Bugs lógicos (condições, off-by-one, concorrência, nil pointer).
2. Segurança (SQL injection, XSS, vazamento de secrets/PII).
3. Regressões (contrato de API, compatibilidade, schema).
4. Database (queries, índices, N+1, transações, migrations) — se presente no diff.
5. UX/DX (mensagens de erro, loading, acessibilidade).
6. Manutenibilidade (nomes, duplicação, complexidade).
7. Performance (N+1 queries, alocações, chamadas síncronas).

## Database-specific review (quando presente no diff)

- **SQL injection**: parameterized queries vs string interpolation em queries concatenadas.
- **N+1 queries**: loops que executam query por iteração sem batch/eager loading.
- **Índices**: colunas em WHERE/JOIN/ORDER BY sem índice, covering index opportunities.
- **Transações**: escopo correto, rollback em erro, propagated context.
- **Migrations**: idempotência, forward-only, rollback strategy, sem dados sensíveis.
- **Tipos**: mapeamento correto entre linguagem e banco (ex: `time.Time` → `timestamptz`).
- **Conexões**: pool configurado, conexões fechadas em erro, sem vazamento.

## Categorias de findings

- **blocker**: segurança, vazamento de dados, regressão crítica. → O code-workflow ABORTA.
- **bug**: erro funcional que deve ser corrigido. → O code-workflow faz auto-fix.
- **alerta**: pode ser problema, requer atenção. → Registrado no relatório.
- **sugestão**: melhoria opcional. → Registrado no relatório.

## Revisão de testes (Fase 7)

- Assertivas significativas, edge cases, legibilidade, determinismo, isolamento.

## Anti-padrões proibidos

- "Aproveitei e já corrigi".
- "Seria melhor se o módulo inteiro usasse outro padrão".
- "Faltou documentação nessa função" (só apontar se causar ambiguidade = bug).
- "Vou revisar os arquivos relacionados também".
- "Código ruim", "isso é feio", "nunca faça assim" — seja técnico.
