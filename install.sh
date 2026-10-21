#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────
# install.sh — Instala skills deste acervo público no seu projeto
#
# Uso:
#   ./install.sh /caminho/para/seu/projeto
#   (Se omitir o caminho, instala no diretório atual)
# ─────────────────────────────────────────────────────────────────

TARGET_DIR="$(cd "${1:-.}" && pwd)"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 Instalando skills públicas em: $TARGET_DIR"

mkdir -p "$TARGET_DIR/.agents/skills" "$TARGET_DIR/.claude/skills"

# Code Review
echo "  -> Instalando code-review..."
rm -rf "$TARGET_DIR/.agents/skills/bugpool" "$TARGET_DIR/.claude/skills/bugpool"
rm -rf "$TARGET_DIR/.agents/skills/code-review"
cp -r "$SOURCE_DIR/code-review" "$TARGET_DIR/.agents/skills/"
CLAUDE_LINK="$TARGET_DIR/.claude/skills/code-review"
if [ -d "$CLAUDE_LINK" ] && [ ! -L "$CLAUDE_LINK" ]; then
  rm -rf "$CLAUDE_LINK"
fi
ln -sfn "../../.agents/skills/code-review" "$CLAUDE_LINK"

echo "✅ Instalação concluída com sucesso!"
echo "   Disponível via slash command: /code-review"
