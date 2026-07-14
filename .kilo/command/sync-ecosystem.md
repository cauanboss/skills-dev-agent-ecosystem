---
description: Sincroniza agentes e skills do ecossistema canônico para global (~/.config/kilo/) e projetos que mantêm cópias locais
agent: agent-governance
model: opencode-go/deepseek-v4-flash
---

Sincronize os agentes e skills deste ecossistema canônico para os destinos configurados.

## O que sincronizar

| Origem | Destino |
|---|---|
| `.kilo/agent/*.md` | `~/.config/kilo/agent/` |
| `.kilo/skills/*/` | `~/.config/kilo/skills/` |
| `.kilo/agent/*.md` | `../rondas-microservices/.kilo/agent/` (se `--all`) |
| `.kilo/skills/*/` | `../rondas-microservices/.kilo/skills/` (se `--all`) |

## Execução

1. Execute `scripts/sync-ecosystem.sh $ARGUMENTS`.
2. Se houver erros, reporte quais arquivos falharam.

## Flags aceitas

- `--all` — sincroniza global + todos os projetos com cópias locais
- `--check` — apenas verifica se há diferenças, não copia
- `--project=<nome>` — sincroniza global + projeto específico

## Projetos com cópias locais

- `rondas-microservices` (caminho: `../rondas-microservices`)

## Sincronização automática

O repositório já tem git hooks em `.githooks/` que disparam sync automático para `~/.config/kilo/`
ao commitar/merge/checkout com mudanças em `.kilo/agent/` ou `.kilo/skills/`.
Os hooks foram ativados via `git config core.hooksPath .githooks`.
