#!/usr/bin/env bash
# Setup unificado para Linux/WSL
# Instala e configura todo o ambiente automaticamente
# Uso: ./setup.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}  Setup Unificado - Linux/WSL                       ${NC}"
echo -e "${CYAN}  Instalando e configurando ambiente                ${NC}"
echo -e "${CYAN}====================================================${NC}"

# ============================================================
# 1. Detectar Ambiente
# ============================================================
IS_WSL=false
IS_LINUX=false
if uname -r | grep -qi microsoft; then
    IS_WSL=true
    echo -e "${BLUE}[INFO] WSL detectado.${NC}"
else
    IS_LINUX=true
    echo -e "${BLUE}[INFO] Linux nativo detectado.${NC}"
fi

# ============================================================
# 2. Criar Links Simbólicos
# ============================================================
echo -e "\n${CYAN}--- 2. Links Simbólicos ---${NC}"

declare -A LINKS=(
    ["shared/.gitconfig"]="$HOME/.gitconfig"
    ["linux/system/.bashrc"]="$HOME/.bashrc"
    ["linux/system/.tmux.conf"]="$HOME/.tmux.conf"
    ["shared/.gitignore_global"]="$HOME/.gitignore_global"
)

for src in "${!LINKS[@]}"; do
    dest="${LINKS[$src]}"
    src_path="$REPO_DIR/$src"

    if [[ ! -f "$src_path" ]]; then
        echo -e "${YELLOW}[WARN] Arquivo não encontrado: $src${NC}"
        continue
    fi

    if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$src_path" ]]; then
        echo -e "${GREEN}[OK] Symlink já existe: $dest -> $src${NC}"
    else
        if [[ -e "$dest" ]]; then
            echo -e "${YELLOW}[INFO] Fazendo backup de $(basename "$dest") -> $(basename "$dest").backup${NC}"
            mv "$dest" "${dest}.backup"
        fi
        ln -sf "$src_path" "$dest"
        echo -e "${GREEN}[OK] Symlink criado: $dest -> $src${NC}"
    fi
done

# ============================================================
# 3. Instalar Pacotes APT (se root ou via sudo)
# ============================================================
echo -e "\n${CYAN}--- 3. Pacotes APT ---${NC}"
if [[ -f "$REPO_DIR/linux/packages/install-apt-packages.sh" ]]; then
    bash "$REPO_DIR/linux/packages/install-apt-packages.sh"
else
    echo -e "${YELLOW}[WARN] Script APT não encontrado. Pulando.${NC}"
fi

# ============================================================
# 4. Instalar Homebrew
# ============================================================
echo -e "\n${CYAN}--- 4. Homebrew ---${NC}"
if [[ -f "$REPO_DIR/linux/homebrew/install-homebrew.sh" ]]; then
    bash "$REPO_DIR/linux/homebrew/install-homebrew.sh"
else
    echo -e "${YELLOW}[WARN] Script Homebrew não encontrado. Pulando.${NC}"
fi

# ============================================================
# 5. Instalar Pacotes do Brewfile
# ============================================================
echo -e "\n${CYAN}--- 5. Pacotes Brewfile ---${NC}"
if [[ -f "$REPO_DIR/linux/homebrew/install-brew-packages.sh" ]]; then
    bash "$REPO_DIR/linux/homebrew/install-brew-packages.sh" || \
        echo -e "${YELLOW}[WARN] Falha ao instalar pacotes Brewfile. Execute manualmente depois.${NC}"
else
    echo -e "${YELLOW}[WARN] Script Brewfile não encontrado. Pulando.${NC}"
fi

# ============================================================
# 6. Instalar Fontes
# ============================================================
echo -e "\n${CYAN}--- 6. Fontes ---${NC}"
if [[ -f "$REPO_DIR/linux/fonts/install-fonts.sh" ]]; then
    if [[ "$IS_WSL" == true ]]; then
        echo -e "${YELLOW}[INFO] No WSL, fontes são gerenciadas pelo Windows.${NC}"
    else
        bash "$REPO_DIR/linux/fonts/install-fonts.sh"
    fi
else
    echo -e "${YELLOW}[WARN] Script de fontes não encontrado. Pulando.${NC}"
fi

# ============================================================
# 7. Verificar Docker
# ============================================================
echo -e "\n${CYAN}--- 7. Verificar Docker ---${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}[OK] Docker já instalado: $(docker --version)${NC}"
else
    echo -e "${YELLOW}[INFO] Docker não instalado.${NC}"
    if [[ -f "$REPO_DIR/linux/containers/install-docker-wsl.sh" ]]; then
        read -p "Deseja instalar Docker? (s/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            bash "$REPO_DIR/linux/containers/install-docker-wsl.sh"
        else
            echo -e "${YELLOW}[SKIP] Docker não instalado.${NC}"
        fi
    fi
fi

# ============================================================
# 8. Configurar Git (se necessário)
# ============================================================
echo -e "\n${CYAN}--- 8. Configuração do Git ---${NC}"
if grep -q "SEU_EMAIL_AQUI\|SEU_NOME_AQUI" "$HOME/.gitconfig" 2>/dev/null; then
    echo -e "${YELLOW}[WARN] Configure seu nome e e-mail em ~/.gitconfig${NC}"
    read -p "Nome (ex: Seu Nome): " git_name
    read -p "Email (ex: nome@email.com): " git_email
    if [[ -n "$git_name" ]] && [[ -n "$git_email" ]]; then
        sed -i "s/SEU_NOME_AQUI/$git_name/" "$HOME/.gitconfig"
        sed -i "s/SEU_EMAIL_AQUI/$git_email/" "$HOME/.gitconfig"
        echo -e "${GREEN}[OK] Git configurado!${NC}"
    else
        echo -e "${YELLOW}[INFO] Pule a configuração do git por enquanto.${NC}"
    fi
else
    echo -e "${GREEN}[OK] Git já configurado.${NC}"
fi

# ============================================================
# 9. Instalar Tmux Plugins (TPM)
# ============================================================
echo -e "\n${CYAN}--- 9. Tmux Plugin Manager (TPM) ---${NC}"
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo -e "${GREEN}[INFO] Instalando TPM...${NC}"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" 2>/dev/null || \
        echo -e "${YELLOW}[WARN] Falha ao clonar TPM.${NC}"
else
    echo -e "${GREEN}[OK] TPM já instalado.${NC}"
fi

# ============================================================
# Finalização
# ============================================================
echo -e "\n${CYAN}====================================================${NC}"
echo -e "${GREEN}[SUCCESS] Setup concluído!                        ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo -e "  1. Recarregue o shell:  ${GREEN}source ~/.bashrc${NC}"
echo -e "  2. Instale plugins tmux:${GREEN}tmux${NC} → ${GREEN}prefix + I${NC}"
echo -e "  3. Verifique docker:    ${GREEN}docker --version${NC}"
echo -e "  4. Verifique git:       ${GREEN}git config --list${NC}"
echo -e ""
