#!/usr/bin/env bash
set -e

echo "==> Atualizando sistema"
sudo apt update && sudo apt upgrade -y

echo "==> Instalando dependências"
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "==> Instalando Docker (convenience script oficial)"
curl -fsSL https://get.docker.com | sudo sh

echo "==> Adicionando usuário ao grupo docker"
sudo usermod -aG docker $USER

echo "==> Habilitando serviço Docker"
sudo systemctl enable docker

echo "==> Instalando plugins úteis"
sudo apt install -y docker-compose-plugin

echo "==> Finalizado. Reinicie o WSL com: wsl --shutdown"
