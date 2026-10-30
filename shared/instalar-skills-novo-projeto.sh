#!/usr/bin/env bash
# instalar-skills-novo-projeto.sh
# Inicializa e registra skills essenciais em um novo projeto:
#   1. security-audit (Cloudflare) - Auditoria de vulnerabilidades e segurança
#   2. elephant-goldfish-model / EGM (Google) - Brainstorm, draft e review adversarial com agentes isolados
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

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}  Configurando Skills para Novo Projeto             ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "${BLUE}Diretório do projeto:${NC} $ABS_TARGET_DIR"

# 1. Instalar security-audit (Cloudflare) via Skills CLI
echo -e "\n${BLUE}>>> 1. Instalando security-audit (Cloudflare)...${NC}"
SEC_INSTALLED=false

if command -v npx >/dev/null 2>&1; then
    echo "Executando npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit -y ..."
    if npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit -y 2>/dev/null; then
        SEC_INSTALLED=true
        echo -e "${GREEN}   ✅ security-audit instalado via Skills CLI!${NC}"
    fi
fi

if [ "$SEC_INSTALLED" = false ]; then
    echo -e "${YELLOW}   Aviso: usando fallback local para security-audit...${NC}"
    if [ -d "$HOME/.agents/skills/security-audit" ]; then
        mkdir -p "$ABS_TARGET_DIR/.agents/skills"
        cp -r "$HOME/.agents/skills/security-audit" "$ABS_TARGET_DIR/.agents/skills/"
        echo -e "${GREEN}   ✅ security-audit copiado do cache local global!${NC}"
    fi
fi

# 2. Instalar Elephant-Goldfish Model / EGM (Google) via Skills CLI
echo -e "\n${BLUE}>>> 2. Instalando Elephant-Goldfish Model / EGM (Google)...${NC}"
EGM_INSTALLED=false

if command -v npx >/dev/null 2>&1; then
    echo "Executando npx skills add https://github.com/google/elephant-goldfish-model --skill '*' -y ..."
    if npx skills add https://github.com/google/elephant-goldfish-model --skill '*' -y 2>/dev/null; then
        EGM_INSTALLED=true
        echo -e "${GREEN}   ✅ EGM (7 skills) instalado via Skills CLI!${NC}"
    fi
fi

if [ "$EGM_INSTALLED" = false ]; then
    echo -e "${YELLOW}   Aviso: usando fallback local para skills EGM...${NC}"
    mkdir -p "$ABS_TARGET_DIR/.agents/skills"
    for egm_skill in egm-bootstrap egm-brainstorm egm-draft egm-drift-report egm-resolve egm-review egm-review-loop; do
        if [ -d "$HOME/.agents/skills/$egm_skill" ]; then
            cp -r "$HOME/.agents/skills/$egm_skill" "$ABS_TARGET_DIR/.agents/skills/"
        fi
    done
    echo -e "${GREEN}   ✅ Skills EGM copiadas do cache local global!${NC}"
fi

# 3. Garantir skills-lock.json completo no projeto
TEMPLATE_LOCK="/home/livre/my-setup-os/shared/templates/novo-projeto/skills-lock.json"
if [ ! -f "$ABS_TARGET_DIR/skills-lock.json" ] && [ -f "$TEMPLATE_LOCK" ]; then
    echo -e "\n${BLUE}>>> 3. Copiando skills-lock.json do template...${NC}"
    cp "$TEMPLATE_LOCK" "$ABS_TARGET_DIR/skills-lock.json"
    echo -e "${GREEN}   ✅ skills-lock.json configurado com security-audit e EGM.${NC}"
fi

# 4. Configurar opencode.jsonc (se aplicável)
if [ ! -f "$ABS_TARGET_DIR/opencode.jsonc" ]; then
    echo -e "\n${BLUE}>>> 4. Criando opencode.jsonc...${NC}"
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

# 5. Sincronizar em .opencode/skills para compatibilidade total
mkdir -p "$ABS_TARGET_DIR/.opencode/skills"
for skill_path in "$ABS_TARGET_DIR/.agents/skills"/*; do
    if [ -d "$skill_path" ]; then
        skill_name=$(basename "$skill_path")
        if [ ! -e "$ABS_TARGET_DIR/.opencode/skills/$skill_name" ]; then
            ln -sfn "../../.agents/skills/$skill_name" "$ABS_TARGET_DIR/.opencode/skills/$skill_name" 2>/dev/null || cp -r "$skill_path" "$ABS_TARGET_DIR/.opencode/skills/"
        fi
    fi
done

# 6. Opcional: Instalar Matt Pocock skills se solicitado (--all)
if [ "$INSTALL_ALL" = true ]; then
    echo -e "\n${BLUE}>>> 6. Instalando skills adicionais (Matt Pocock)...${NC}"
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

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}  Configuração Concluída com Sucesso!               ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Skills prontas para uso no seu projeto:"
echo -e "\n${CYAN}1. Security Audit (Cloudflare):${NC}"
echo -e "   - ${YELLOW}security audit this codebase${NC}"
echo -e "   - ${YELLOW}find security vulnerabilities in ./src${NC}"
echo -e "   - ${YELLOW}do a security review, output to ~/audits/$(basename "$ABS_TARGET_DIR")${NC}"
echo -e "\n${CYAN}2. Elephant-Goldfish Model (Google EGM):${NC}"
echo -e "   - ${YELLOW}/egm:egm-brainstorm${NC} ou ${YELLOW}egm-brainstorm <ideia>${NC}"
echo -e "   - ${YELLOW}/egm:egm-draft${NC} (gera o design_draft.md a partir do brief)"
echo -e "   - ${YELLOW}/egm:egm-review design_draft.md${NC} (revisão adversarial com goldfish)"
echo -e "   - ${YELLOW}/egm:egm-resolve${NC} (aplica resoluções e checkpoints)"
echo -e "   - ${YELLOW}/egm:egm-drift-report${NC} (verifica divergência entre docs e código)"
echo -e "\nRestaurar todas as skills em qualquer máquina:"
echo -e "   - ${YELLOW}npx skills experimental_install${NC}"
