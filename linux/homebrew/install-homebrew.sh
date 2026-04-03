#!/bin/bash
# Instala o Homebrew no Linux/WSL

set -e

echo "Instalando Homebrew..."

# Verifica se o Homebrew já está instalado
if command -v brew &> /dev/null; then
    echo "Homebrew já está instalado."
    echo "Atualizando..."
    brew update
else
    # Instala o Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Adiciona ao PATH (para Linux/WSL)
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

echo "Homebrew instalado com sucesso!"
echo "Versão: $(brew --version)"
