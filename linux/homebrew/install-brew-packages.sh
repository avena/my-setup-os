#!/bin/bash
# Instala pacotes do Brewfile

set -e

echo "Instalando pacotes do Brewfile..."

# Verifica se o Homebrew está instalado
if ! command -v brew &> /dev/null; then
    echo "Erro: Homebrew não está instalado."
    echo "Execute primeiro: ./install-homebrew.sh"
    exit 1
fi

# Instala pacotes do Brewfile
brew bundle --file="$(dirname "$0")/Brewfile"

echo "Pacotes instalados com sucesso!"
echo "Lista de pacotes instalados:"
brew list
