#!/usr/bin/env bash
set -e

echo "==============================================="
echo "  NVIDIA + Docker Setup for WSL2"
echo "==============================================="

echo "==> Verificando se nvidia-smi funciona..."
if ! command -v nvidia-smi &> /dev/null; then
    echo "ERRO: nvidia-smi não encontrado."
    echo "Instale o driver NVIDIA no Windows com suporte WSL."
    exit 1
fi

nvidia-smi || {
    echo "ERRO: GPU não detectada no WSL."
    exit 1
}

echo "==> Atualizando sistema"
sudo apt update

echo "==> Instalando dependências"
sudo apt install -y curl gnupg ca-certificates lsb-release

echo "==> Adicionando repositório NVIDIA Container Toolkit"

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit.gpg

distribution=$(. /etc/os-release; echo $ID$VERSION_ID)

curl -s -L https://nvidia.github.io/libnvidia-container/stable/$distribution/libnvidia-container.list | \
sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit.gpg] https://#g' | \
sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

echo "==> Instalando NVIDIA Container Toolkit"
sudo apt update
sudo apt install -y nvidia-container-toolkit

echo "==> Configurando runtime NVIDIA no Docker"
sudo nvidia-ctk runtime configure --runtime=docker

echo "==> Reiniciando Docker"
sudo systemctl restart docker

echo "==> Testando container com GPU"

docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi

echo "==============================================="
echo "  INSTALAÇÃO CONCLUÍDA COM SUCESSO 🚀"
echo "==============================================="


