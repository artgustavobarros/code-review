#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────
# backend/install.sh — Instala o kit de skills de backend num projeto
#
# Uso:
#   ./backend/install.sh /caminho/para/seu/projeto
#   (Se omitir o caminho, instala no diretório atual)
# ─────────────────────────────────────────────────────────────────

SKILLS=(
  node
  nodejs-backend-patterns
  api-design-principles
  supabase-postgres-best-practices
  vitest
  test-driven-development
)

TARGET_DIR="$(cd "${1:-.}" && pwd)"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 Instalando skills de backend em: $TARGET_DIR"

mkdir -p "$TARGET_DIR/.agents/skills" "$TARGET_DIR/.claude/skills"

for skill in "${SKILLS[@]}"; do
  echo "  -> Instalando $skill..."
  rm -rf "$TARGET_DIR/.agents/skills/$skill"
  cp -r "$SOURCE_DIR/$skill" "$TARGET_DIR/.agents/skills/"
  CLAUDE_LINK="$TARGET_DIR/.claude/skills/$skill"
  if [ -d "$CLAUDE_LINK" ] && [ ! -L "$CLAUDE_LINK" ]; then
    rm -rf "$CLAUDE_LINK"
  fi
  ln -sfn "../../.agents/skills/$skill" "$CLAUDE_LINK"
done

echo "✅ Instalação concluída com sucesso!"
