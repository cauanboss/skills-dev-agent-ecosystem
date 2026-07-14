#!/usr/bin/env bash
# sync-ecosystem.sh — Sincroniza agentes e skills do ecossistema canônico
#
# Uso:
#   ./scripts/sync-ecosystem.sh                    # sync para global apenas
#   ./scripts/sync-ecosystem.sh --all               # sync para global + todos os projetos
#   ./scripts/sync-ecosystem.sh --project rondas    # sync para global + rondas-microservices
#   ./scripts/sync-ecosystem.sh --check             # apenas verifica se há diferenças
#
# Comportamento padrão (sem flags): sync para ~/.config/kilo/ apenas.

set -euo pipefail

ECOSYSTEM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GLOBAL_AGENT_DIR="$HOME/.config/kilo/agent"
GLOBAL_SKILL_DIR="$HOME/.config/kilo/skills"
ECOSYSTEM_AGENT_DIR="$ECOSYSTEM_DIR/.kilo/agent"
ECOSYSTEM_SKILL_DIR="$ECOSYSTEM_DIR/.kilo/skills"

# Projetos que mantêm cópias locais (pares "nome:dir_relativo")
PROJECTS=(
  "rondas-microservices:../rondas-microservices"
)

log()  { echo "  → $*"; }
error() { echo "  ✖ $*" >&2; }
ok()   { echo "  ✔ $*"; }

# Detecta dry-run / check mode
CHECK_ONLY=false
SYNC_ALL=false
for arg in "$@"; do
  case "$arg" in
    --check|--dry-run) CHECK_ONLY=true ;;
    --all) SYNC_ALL=true ;;
    --project=*) 
      TARGET="${arg#--project=}"
      for p in "${PROJECTS[@]}"; do
        name="${p%%:*}"
        [ "$name" = "$TARGET" ] && SYNC_ALL=true && break
      done
      if [ "$SYNC_ALL" = false ]; then
        error "Projeto desconhecido: $TARGET"
        echo "  Projetos disponíveis:"
        for p in "${PROJECTS[@]}"; do
          echo "    - ${p%%:*}"
        done
        exit 1
      fi
      ;;
  esac
done

echo "=== Sincronizando Ecossistema de Agentes ==="
echo "  Origem:  $ECOSYSTEM_DIR"
echo ""

# --- Funções de sync ---

sync_agents() {
  local src="$1/agent"
  local dst="$2"
  local label="$3"

  if [ ! -d "$src" ]; then
    error "Diretório de origem não encontrado: $src"
    return 1
  fi

  mkdir -p "$dst"

  local changes=0
  for agent_file in "$src"/*.md; do
    local name
    name="$(basename "$agent_file")"
    if [ "$CHECK_ONLY" = true ]; then
      if [ -f "$dst/$name" ]; then
        if ! diff -q "$agent_file" "$dst/$name" >/dev/null 2>&1; then
          log "[$label] agente $name — DESATUALIZADO"
          changes=$((changes + 1))
        fi
      else
        log "[$label] agente $name — NOVO"
        changes=$((changes + 1))
      fi
    else
      cp "$agent_file" "$dst/$name"
      ok "[$label] agente $name"
      changes=$((changes + 1))
    fi
  done

  # Detecta arquivos removidos na origem
  for dst_file in "$dst"/*.md; do
    local name
    name="$(basename "$dst_file")"
    if [ ! -f "$src/$name" ]; then
      if [ "$CHECK_ONLY" = true ]; then
        log "[$label] agente $name — REMOVIDO da origem"
        changes=$((changes + 1))
      else
        rm "$dst/$name"
        log "[$label] agente $name — REMOVIDO (não existe mais na origem)"
        changes=$((changes + 1))
      fi
    fi
  done

  [ "$changes" -eq 0 ] && ok "[$label] agentes — OK (sem alterações)"
  return 0
}

sync_skills() {
  local src="$1/skills"
  local dst="$2"
  local label="$3"

  if [ ! -d "$src" ]; then
    error "Diretório de origem não encontrado: $src"
    return 1
  fi

  mkdir -p "$dst"

  local changes=0
  for skill_dir in "$src"/*/; do
    local name
    name="$(basename "$skill_dir")"
    local skill_file="$skill_dir/SKILL.md"
    local dst_skill="$dst/$name/SKILL.md"

    if [ ! -f "$skill_file" ]; then
      error "[$label] skill $name — SKILL.md não encontrado na origem"
      continue
    fi

    if [ "$CHECK_ONLY" = true ]; then
      if [ -f "$dst_skill" ]; then
        if ! diff -q "$skill_file" "$dst_skill" >/dev/null 2>&1; then
          log "[$label] skill $name — DESATUALIZADA"
          changes=$((changes + 1))
        fi
      else
        log "[$label] skill $name — NOVA"
        changes=$((changes + 1))
      fi
    else
      mkdir -p "$dst/$name"
      cp "$skill_file" "$dst_skill"
      ok "[$label] skill $name"
      changes=$((changes + 1))
    fi
  done

  # Detecta skills removidas na origem
  for dst_skill_dir in "$dst"/*/; do
    local name
    name="$(basename "$dst_skill_dir")"
    if [ ! -d "$src/$name" ]; then
      if [ "$CHECK_ONLY" = true ]; then
        log "[$label] skill $name — REMOVIDA da origem"
        changes=$((changes + 1))
      else
        rm -rf "$dst_skill_dir"
        log "[$label] skill $name — REMOVIDA (não existe mais na origem)"
        changes=$((changes + 1))
      fi
    fi
  done

  [ "$changes" -eq 0 ] && ok "[$label] skills — OK (sem alterações)"
  return 0
}

# --- Execução ---

TOTAL_CHANGES=0

# 1. Global
echo ""
echo "--- Global (~/.config/kilo/) ---"
sync_agents "$ECOSYSTEM_DIR/.kilo" "$GLOBAL_AGENT_DIR" "global"
sync_skills "$ECOSYSTEM_DIR/.kilo" "$GLOBAL_SKILL_DIR" "global"

# 2. Projetos
if [ "$SYNC_ALL" = true ]; then
  for entry in "${PROJECTS[@]}"; do
    name="${entry%%:*}"
    dir="${entry#*:}"
    project_path="$(cd "$ECOSYSTEM_DIR/$dir" 2>/dev/null && pwd)" || true

    if [ -z "$project_path" ] || [ ! -d "$project_path/.kilo" ]; then
      log "Projeto $name — .kilo/ não encontrado em $dir, pulando"
      continue
    fi

    echo ""
    echo "--- Projeto: $name ---"
    sync_agents "$ECOSYSTEM_DIR/.kilo" "$project_path/.kilo/agent" "$name"
    sync_skills "$ECOSYSTEM_DIR/.kilo" "$project_path/.kilo/skills" "$name"
  done
fi

echo ""
if [ "$CHECK_ONLY" = true ]; then
  echo "✔ Verificação concluída. Execute sem --check para sincronizar."
else
  echo "✔ Sincronização concluída."
fi
