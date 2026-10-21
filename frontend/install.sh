#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────
# frontend/install.sh — Instala o kit de skills de frontend num projeto
#
# Uso:
#   ./frontend/install.sh /caminho/para/seu/projeto
#   (Se omitir o caminho, instala no diretório atual)
#
# Variáveis:
#   SKIP_IMPECCABLE=1        Não instala o impeccable
#   IMPECCABLE_ARGS="..."    Args extras pro instalador do impeccable
#                            (ex.: "--providers=claude,codex --no-hooks")
# ─────────────────────────────────────────────────────────────────

IMPECCABLE_VERSION="4.7.0"
SKILLS=(
  design-taste-frontend
  vercel-composition-patterns
  vercel-react-best-practices
  web-design-guidelines
  webapp-testing
)

TARGET_DIR="$(cd "${1:-.}" && pwd)"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 Instalando skills de frontend em: $TARGET_DIR"

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

# O impeccable gera uma variante por harness (Claude, Codex, Gemini...),
# hooks e um binário por plataforma, então vem do instalador oficial,
# com a versão travada.
if [ "${SKIP_IMPECCABLE:-0}" != "1" ]; then
  echo "  -> Instalando impeccable@$IMPECCABLE_VERSION..."
  # shellcheck disable=SC2086
  (cd "$TARGET_DIR" && npx -y "impeccable@$IMPECCABLE_VERSION" install -y --project ${IMPECCABLE_ARGS:-})
fi

echo "✅ Instalação concluída com sucesso!"
