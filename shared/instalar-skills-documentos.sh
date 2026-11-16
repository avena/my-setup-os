#!/bin/bash
# Instala as skills de documento (docx, md-to-docx, word-documents)
# e propaga para todos os CLIs de coding agent.
#
# Uso: bash ~/my-setup-os/shared/instalar-skills-documentos.sh
# Idempotente: pode rodar quantas vezes quiser.

set -euo pipefail

SKILLS_ROOT="$HOME/.agents/skills"
SKILLS=(docx md-to-docx word-documents)

# ---------------------------------------------------------------- 1. evercli
echo "=== 1/4 · evercli (SkillHub / EverMe) ==="
if ! command -v evercli >/dev/null 2>&1; then
    echo ">>> instalando @everme/cli"
    npm install -g @everme/cli
fi
evercli --version | head -1

echo ">>> md-to-docx"
evercli skill install openclaw/skills/md-to-docx --yes --format json | tail -5

echo ">>> word-documents"
evercli skill install agent0ai/agent-zero/word-documents --yes --format json | tail -5

# ------------------------------------------------------------------- 2. docx
echo
echo "=== 2/4 · docx (Anthropic, via OpxSkills) ==="
if [ -f "$SKILLS_ROOT/docx/SKILL.md" ]; then
    echo ">>> docx já presente em $SKILLS_ROOT/docx (pulando clone)"
else
    TMP=$(mktemp -d)
    git clone --depth 1 --filter=blob:none --sparse \
        https://github.com/anthropics/skills.git "$TMP/skills"
    ( cd "$TMP/skills" && git sparse-checkout set skills/docx )
    mkdir -p "$SKILLS_ROOT"
    cp -r "$TMP/skills/skills/docx" "$SKILLS_ROOT/docx"
    rm -rf "$TMP"
    echo ">>> docx instalada"
fi

# ------------------------------------------------------------- 3. propagação
echo
echo "=== 3/4 · propagando para os CLIs ==="
CLI_SKILL_DIRS=(
    "$HOME/.config/opencode/skills"
    "$HOME/.codebuddy/skills"
    "$HOME/.kilo/skills"
    "$HOME/.antigravity/skills"
    "$HOME/.copilot/skills"
    "$HOME/.claude/skills"
    "$HOME/.codex/skills"
    "$HOME/.gemini/skills"
    "$HOME/.qwen/skills"
    "$HOME/.openclaw/skills"
    "$HOME/.cline/skills"
    "$HOME/.cursor/skills"
    "$HOME/.continue/skills"
)

for dir in "${CLI_SKILL_DIRS[@]}"; do
    # só mexe em CLIs que já existem na máquina
    [ -d "$(dirname "$dir")" ] || continue
    mkdir -p "$dir"
    for skill in "${SKILLS[@]}"; do
        ln -sfn "$SKILLS_ROOT/$skill" "$dir/$skill"
    done
    n=0
    for skill in "${SKILLS[@]}"; do
        [ -r "$dir/$skill/SKILL.md" ] && n=$((n + 1))
    done
    printf "  %-30s %d/%d\n" "$(echo "$dir" | sed "s|$HOME|~|")" "$n" "${#SKILLS[@]}"
done

# ------------------------------------------------------------ 4. dependências
echo
echo "=== 4/4 · dependências ==="
check() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "  OK       $1"
    else
        echo "  FALTANDO $1  → $2"
    fi
}
python3 -c "import docx" 2>/dev/null \
    && echo "  OK       python-docx" \
    || echo "  FALTANDO python-docx  → pip3 install --user --break-system-packages python-docx"
NODE_PATH="$(npm root -g)" node -e "require('docx')" 2>/dev/null \
    && echo "  OK       npm docx" \
    || echo "  FALTANDO npm docx  → npm install -g docx"
check pandoc    "apt install pandoc"
check soffice   "apt install libreoffice-writer (necessário p/ validação visual e templates .doc)"
check pdftoppm  "apt install poppler-utils"
command -v mmdc >/dev/null 2>&1 \
    && echo "  OK       mmdc (mermaid)" \
    || echo "  opcional mmdc  → npm install -g @mermaid-js/mermaid-cli"

echo
echo "=== pronto ==="
echo "Skills em: $SKILLS_ROOT/{docx,md-to-docx,word-documents}"
echo "Reinicie os agentes para carregar."
