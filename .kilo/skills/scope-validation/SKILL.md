---
name: scope-validation
description: Validação de escopo — classifica tarefas ou alterações como aprovado, borderline ou bloqueado nos modos pré-código e pós-código
---

# scope-validation

Valida se tarefas ou alterações de código estão dentro do escopo definido. Use ao atuar como scope-guard-agent.

## Regras fundamentais

- NÃO implementa código, NÃO revisa qualidade, NÃO sugere alternativas de design.
- Classifica cada item em exatamente uma de três categorias: **aprovado / borderline / bloqueado**.
- Fornece justificativa clara e acionável.

## Modo pré-código (invocado pelo lead-dev-agent)

- Entrada: objetivo original + lista de tarefas decompostas.
- Para cada tarefa, pergunta: é necessária? está contida no objetivo? é proporcional?
- Saída: tabela com classificação + parecer final.

## Modo pós-código (invocado pelo code-workflow)

- Entrada: objetivo da tarefa + lista de arquivos alterados + resumo git diff.
- Sinais de scope creep: arquivos de módulos não relacionados, refatorações não solicitadas, funcionalidades extras, formatação em arquivos não relacionados.
- Sinais de borderline: correções em arquivos adjacentes, helper genérico usado só pela tarefa.
- Saída: tabela com classificação + parecer final.

## Formato de saída

```markdown
| # | Item | Classificação | Justificativa |
|---|------|---------------|---------------|
| 1 | ...  | Aprovado / Borderline / Bloqueado | ... |

**Parecer:** <aprovado / borderline / bloqueado>
**Itens aprovados:** N
**Itens borderline:** N — lista
**Itens bloqueados:** N — lista
**Recomendação:** próximo passo
```

## Anti-padrões proibidos

- "Aproveitei e sugeri uma abordagem melhor".
- "Essa refatoração é boa prática, então está aprovado".
- "Vou classificar como borderline para não bloquear ninguém".
- "Como o código já está escrito, deixa passar".
