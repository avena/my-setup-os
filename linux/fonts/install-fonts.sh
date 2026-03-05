#!/usr/bin/env bash
# Script Avançado de Instalação de Fontes
# Seguro para uso local, Distrobox e DevPod.

set -e

# Cores
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
NC='\033[0m'

# ==========================================
# 1. DETECÇÃO DO USUÁRIO VERDADEIRO (Anti-Root Hijack)
# ==========================================
# Se o script for rodado com sudo, $SUDO_USER contém o nome do seu usuário original.
# Se rodado sem sudo, o $USER normal funciona.
REAL_USER=${SUDO_USER:-$USER}

# Obtemos o caminho exato da Home do usuário verdadeiro (/home/livre em vez de /root)
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "${CYAN}[INFO] Rodando como root, mas as configurações de usuário serão enviadas para: ${REAL_USER} (${REAL_HOME})${NC}"

# ==========================================
# 2. FUNÇÕES DE INSTALAÇÃO
# ==========================================

install_apt() {
  echo -e "${CYAN}[INFO] Atualizando e instalando pacotes base...${NC}"
  # Executado como root
  apt-get update
  apt-get install -y fonts-firacode unzip aria2 fontconfig
  
  install_nerd_fonts_direct
}

install_nerd_fonts_direct() {
  local NF_VERSION="v3.2.1"
  # Agora garantimos que as fontes vão para a pasta correta (ex: /home/livre/.local/share/fonts)
  local FONTS_DIR="${REAL_HOME}/.local/share/fonts"
  local FONTS=("FiraCode" "JetBrainsMono" "CascadiaCode")

  echo -e "${CYAN}[INFO] Preparando diretório de fontes: ${FONTS_DIR}${NC}"
  
  # Como estamos rodando com sudo, precisamos usar `sudo -u` para que a pasta
  # seja criada pelo usuário real, e não pelo root.
  sudo -u "$REAL_USER" mkdir -p "$FONTS_DIR"

  for font in "${FONTS[@]}"; do
    echo -e "${YELLOW}[INFO] Baixando ${font} Nerd Font...${NC}"
    # Download como root na pasta /tmp (seguro)
    aria2c -q -x 4 -s 4 -d /tmp -o "${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/${NF_VERSION}/${font}.zip"
    
    echo -e "${CYAN}[INFO] Extraindo e movendo ${font}...${NC}"
    # O comando abaixo extrai com a propriedade (owner) do usuário verdadeiro, não do root
    sudo -u "$REAL_USER" bash -c "unzip -q -o /tmp/${font}.zip -d ${FONTS_DIR}"
    rm -f "/tmp/${font}.zip"
  done

  echo -e "${CYAN}[INFO] Atualizando cache de fontes do sistema para o usuário ${REAL_USER}...${NC}"
  # O fc-cache deve ser rodado como o usuário, para ler a própria pasta
  sudo -u "$REAL_USER" fc-cache -fv "$FONTS_DIR"
}

# ==========================================
# 3. LÓGICA PRINCIPAL
# ==========================================

main() {
  # Proteção: Exige root para funcionar corretamente com as instalações
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Este script precisa ser rodado com sudo.${NC}"
    echo -e "${YELLOW}Por favor, rode: sudo bash install-fonts.sh${NC}"
    exit 1
  fi

  OS=$(uname -s)
  if [ "$OS" = "Linux" ]; then
    if command -v apt-get >/dev/null 2>&1; then
      install_apt
    else
      echo -e "${RED}[ERROR] Gerenciador APT não encontrado.${NC}"
      exit 1
    fi
  fi

  echo -e "\n${GREEN}[SUCCESS] Fontes instaladas em ${FONTS_DIR}!${NC}\n"
}

main "$@"
