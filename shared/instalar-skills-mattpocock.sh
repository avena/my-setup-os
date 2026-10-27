#!/bin/bash
# Instala skills Matt Pocock para todos os CLIs disponíveis
# Execute: bash /home/livre/my-setup-os/shared/instalar-skills-mattpocock.sh

set -e

SKILLS_SOURCE="$HOME/.openclaw/skills"
SKILLS_TARGETS=(
    "$HOME/.config/opencode/skills"
    "$HOME/.kilo/skills"
    "$HOME/.antigravity/skills"
    "$HOME/.copilot/skills"
    "$HOME/.claude/skills"
    "$HOME/.codex/skills"
    "$HOME/.gemini/skills"
    "$HOME/.qwen/skills"
    "$HOME/.openclaw/skills"
)

echo "=== Instalando Skills Matt Pocock para todos os CLIs ==="
echo "Source: $SKILLS_SOURCE"
echo ""

# Verificar se skills existem
if [ ! -d "$SKILLS_SOURCE" ]; then
    echo "ERRO: Skills não encontradas em $SKILLS_SOURCE"
    echo "Clone primeiro: git clone https://github.com/mattpocock/skills.git"
    exit 1
fi

# Instalar para cada CLI
for target in "${SKILLS_TARGETS[@]}"; do
    cli_name=$(basename "$(dirname "$target")")
    echo ">>> Instalando para $cli_name ($target)"
    
    mkdir -p "$target"
    
    # Copiar cada pasta de skills
    for skill_dir in engineering productivity misc; do
        if [ -d "$SKILLS_SOURCE/$skill_dir" ]; then
            cp -r "$SKILLS_SOURCE/$skill_dir" "$target/" 2>/dev/null || true
        fi
    done
    
    # Manter find-skills existente
    if [ ! -e "$target/find-skills" ] && [ -d "$SKILLS_SOURCE/find-skills" ]; then
        cp -r "$SKILLS_SOURCE/find-skills" "$target/"
    fi

    # Manter security-audit existente (Cloudflare)
    if [ ! -e "$target/security-audit" ] && [ -d "$HOME/.agents/skills/security-audit" ]; then
        ln -sf "$HOME/.agents/skills/security-audit" "$target/security-audit" 2>/dev/null || cp -r "$HOME/.agents/skills/security-audit" "$target/"
    fi
    
    echo "   ✅ $cli_name: $(ls "$target" | wc -l) pastas de skills"
done

echo ""
echo "=== Verificação ==="
for target in "${SKILLS_TARGETS[@]}"; do
    cli_name=$(basename "$(dirname "$target")")
    count=$(ls "$target" 2>/dev/null | wc -l)
    echo "   $cli_name: $count skills"
done

echo ""
echo "✅ Instalação concluída!"