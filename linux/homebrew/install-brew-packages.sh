#!/usr/bin/env bash
# Instala pacotes do Brewfile via Homebrew Bundle
# Uso: ./install-brew-packages.sh

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Instalador de Pacotes Homebrew        ${NC}"
echo -e "${GREEN}========================================${NC}"

# Verificar se Homebrew está disponível
if ! command -v brew &> /dev/null; then
    echo -e "${RED}[ERROR] Homebrew não encontrado. Execute install-homebrew.sh primeiro.${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}[INFO] Atualizando Homebrew...${NC}"
brew update

echo -e "${GREEN}[INFO] Executando Brew Bundle...${NC}"
brew bundle --file="$SCRIPT_DIR/Brewfile"

echo -e "\n${GREEN}[SUCCESS] Todos os pacotes foram instalados!${NC}"

