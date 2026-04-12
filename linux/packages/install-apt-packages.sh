#!/usr/bin/env bash
# Script de instalação de pacotes via APT (Infraestrutura, CLI e Redes para WSL/Distrobox)
# SEM instalações globais de linguagens de programação (Node, Python, .NET, GCC)

set -e

# Cores
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
NC='\033[0m'

echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}  Instalador de Infraestrutura Base (APT)  ${NC}"
echo -e "${CYAN}===========================================${NC}"

# Proteção para garantir que rode como root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Este script precisa ser rodado com sudo.${NC}"
  exit 1
fi

echo -e "${CYAN}[INFO] 1. Atualizando repositórios...${NC}"
apt-get update

echo -e "${CYAN}[INFO] 2. Instalando Core e Produtividade de Terminal...${NC}"
# Ferramentas básicas, manipulação de arquivos, json e terminais multiplexadores
apt-get install -y \
    coreutils unzip zip 7zip aria2 curl wget \
    htop tmux vim nano tree jq less

echo -e "${CYAN}[INFO] 3. Instalando ferramentas de Rede e Segurança...${NC}"
# Ferramentas para troubleshooting de rede
apt-get install -y \
    ssh nmap tcpdump netcat-traditional \
    iputils-ping dnsutils iproute2

echo -e "${CYAN}[INFO] 4. Instalando utilitários de Versionamento e Mídia...${NC}"
# Git (essencial mesmo sem compiladores) e utilitários de mídia via CLI
apt-get install -y \
    git git-flow \
    ffmpeg yt-dlp

echo -e "${CYAN}[INFO] 5. Limpando cache do APT...${NC}"
apt-get autoremove -y
apt-get clean

echo -e "\n${GREEN}[SUCCESS] Infraestrutura base e ferramentas CLI instaladas com sucesso!${NC}\n"
