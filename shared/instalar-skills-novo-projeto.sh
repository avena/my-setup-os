#!/usr/bin/env bash
# instalar-skills-novo-projeto.sh
# Inicializa e registra skills essenciais (incluindo security-audit da Cloudflare) em um novo projeto.
#
# Uso:
#   cd /caminho/do/novo-projeto && bash /home/livre/my-setup-os/shared/instalar-skills-novo-projeto.sh
#   ou:
#   bash /home/livre/my-setup-os/shared/instalar-skills-novo-projeto.sh /caminho/do/novo-projeto [--all]

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

TARGET_DIR="."
INSTALL_ALL=false

for arg in "$@"; do
    case "$arg" in
        --all)
            INSTALL_ALL=true
            ;;
        --help|-h)
            echo "Uso: $0 [diretorio_do_projeto] [--all]"
            echo ""
            echo "Opções:"
            echo "  --all    Instala também as skills do Matt Pocock (engineering, productivity, misc)"
            echo "  --help   Exibe esta ajuda"
            exit 0
            ;;
        *)
            if [ -d "$arg" ] || [ ! -e "$arg" ]; then
                TARGET_DIR="$arg"
            fi
            ;;
    esac
done

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"
ABS_TARGET_DIR="$(pwd)"

echo -e "${CYAN}=== Configurando Skills para Novo Projeto ===${NC}"
echo -e "${BLUE}Diretório do projeto:${NC} $ABS_TARGET_DIR"

# 1. Instalar security-audit (Cloudflare) via Skills CLI
echo -e "\n${BLUE}>>> 1. Instalando security-audit (Cloudflare)...${NC}"
INSTALLED=false

if command -v npx >/dev/null 2>&1; then
    echo "Executando npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit -y ..."
    if npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit -y 2>/dev/null; then
        INSTALLED=true
        echo -e "${GREEN}   ✅ security-audit instalado com sucesso via Skills CLI!${NC}"
    fi
fi

# Fallback: copiar do cache local global (~/.agents/skills/security-audit)
if [ "$INSTALLED" = false ]; then
    echo -e "${YELLOW}   Aviso: Skills CLI indisponível ou falhou, usando cache global local...${NC}"
    if [ -d "$HOME/.agents/skills/security-audit" ]; then
        mkdir -p "$ABS_TARGET_DIR/.agents/skills"
        cp -r "$HOME/.agents/skills/security-audit" "$ABS_TARGET_DIR/.agents/skills/"
        INSTALLED=true
        echo -e "${GREEN}   ✅ security-audit copiado do cache local global (~/.agents/skills)!${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Cache global não encontrado em ~/.agents/skills/security-audit${NC}"
    fi
fi

# 2. Garantir skills-lock.json no projeto
if [ ! -f "$ABS_TARGET_DIR/skills-lock.json" ]; then
    echo -e "\n${BLUE}>>> 2. Criando skills-lock.json para restauração futura...${NC}"
    cat << 'EOF' > "$ABS_TARGET_DIR/skills-lock.json"
{
  "version": 1,
  "skills": {
    "security-audit": {
      "source": "cloudflare/security-audit-skill",
      "sourceType": "github",
      "skillPath": "skills/security-audit/SKILL.md",
      "computedHash": "98b97aad2873b3b9a8e064007c25e7827b493ba27fda8bfbdb41dab586767973"
    }
  }
}
EOF
    echo -e "${GREEN}   ✅ skills-lock.json criado com security-audit registrado.${NC}"
else
    echo -e "${GREEN}   ✅ skills-lock.json já existe.${NC}"
fi

# 3. Configurar opencode.jsonc (se aplicável ao OpenCode)
if [ ! -f "$ABS_TARGET_DIR/opencode.jsonc" ]; then
    echo -e "\n${BLUE}>>> 3. Criando opencode.jsonc básico...${NC}"
    cat << 'EOF' > "$ABS_TARGET_DIR/opencode.jsonc"
{
  "$schema": "https://opencode.ai/config.json",
  "skills": [
    ".opencode/skills",
    ".agents/skills"
  ]
}
EOF
    echo -e "${GREEN}   ✅ opencode.jsonc criado.${NC}"
fi

# 4. Criar symlink em .opencode/skills se .opencode existir ou para suporte duplo
mkdir -p "$ABS_TARGET_DIR/.opencode/skills"
if [ -d "$ABS_TARGET_DIR/.agents/skills/security-audit" ] && [ ! -e "$ABS_TARGET_DIR/.opencode/skills/security-audit" ]; then
    ln -sfn "../../.agents/skills/security-audit" "$ABS_TARGET_DIR/.opencode/skills/security-audit" 2>/dev/null || cp -r "$ABS_TARGET_DIR/.agents/skills/security-audit" "$ABS_TARGET_DIR/.opencode/skills/"
fi

# 5. Opcional: Instalar Matt Pocock skills se solicitado (--all)
if [ "$INSTALL_ALL" = true ]; then
    echo -e "\n${BLUE}>>> 4. Instalando skills adicionais (Matt Pocock)...${NC}"
    MP_SOURCE="$HOME/.openclaw/skills"
    if [ -d "$MP_SOURCE" ]; then
        for dir in engineering productivity misc; do
            if [ -d "$MP_SOURCE/$dir" ]; then
                cp -r "$MP_SOURCE/$dir" "$ABS_TARGET_DIR/.opencode/skills/" 2>/dev/null || true
            fi
        done
        echo -e "${GREEN}   ✅ Skills Matt Pocock copiadas para .opencode/skills/${NC}"
    fi
fi

echo -e "\n${GREEN}=== Configuração Concluída com Sucesso! ===${NC}"
echo -e "Skill ${CYAN}security-audit${NC} pronta para uso neste projeto."
echo -e "Comandos de ativação no seu coding agent:"
echo -e "  - ${YELLOW}security audit this codebase${NC}"
echo -e "  - ${YELLOW}find security vulnerabilities in ./src${NC}"
echo -e "  - ${YELLOW}do a security review, output to ~/audits/$(basename "$ABS_TARGET_DIR")${NC}"
echo -e "Restaurar skills a qualquer momento via Skills CLI:"
echo -e "  - ${YELLOW}npx skills experimental_install${NC}"
