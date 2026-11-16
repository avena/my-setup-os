#!/usr/bin/env bash
# ponytail: download direto com curl sem clone pesado; passe --clone se precisar do repo completo em /tmp
set -euo pipefail

DEST_DIR="${TMPDIR:-/tmp}/flashcard-refs"
mkdir -p "$DEST_DIR"

if [[ "${1:-}" == "--clone" ]]; then
  echo "Clonando referências rasas (--depth 1) em $DEST_DIR..."
  rm -rf "$DEST_DIR/flashcard-ai-generator" "$DEST_DIR/flashcards-jalliet"
  git clone --depth 1 https://github.com/DylanFriday/flashcard-ai-generator.git "$DEST_DIR/flashcard-ai-generator"
  git clone --depth 1 https://github.com/jalliet/flashcards.git "$DEST_DIR/flashcards-jalliet"
  echo "✓ Repositórios clonados em: $DEST_DIR"
  exit 0
fi

echo "Baixando arquivos-chave via curl em $DEST_DIR..."

# DylanFriday/flashcard-ai-generator
curl -fsSL https://raw.githubusercontent.com/DylanFriday/flashcard-ai-generator/main/package.json \
  -o "$DEST_DIR/dylanfriday-package.json" || true

# jalliet/flashcards README
curl -fsSL https://raw.githubusercontent.com/jalliet/flashcards/main/README.md \
  -o "$DEST_DIR/jalliet-readme.md" || true

echo "✓ Arquivos salvos em $DEST_DIR"
echo "Para inspecionar o código completo sem poluir o repo, execute: $0 --clone"
