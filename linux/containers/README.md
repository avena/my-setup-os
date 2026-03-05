# Linux Containers (Docker)

## Overview
Esta pasta contém scripts de instalação e configuração para o Docker e containerização no Linux/WSL.

## Arquivos na Pasta

### 1. install-docker-wsl.sh
Script para instalar o Docker Engine no WSL. Contém:
- Instalação dos pré-requisitos
- Adição do repositório Docker
- Instalação do Docker Engine
- Configuração de permissões
- Instalação do Docker Compose

### 2. install-docker-wsl-nvidia.sh
Versão do script com suporte para **NVIDIA Docker** (GPU pass-through). Requer:
- WSL 2 com suporte a GPU
- Driver NVIDIA instalado no Windows
- Driver CUDA instalado no WSL

## Instalação

### Pré-requisitos
- WSL 2 (versão 2004 ou superior)
- Ubuntu 20.04+ ou distro compatível
- Espaço em disco disponível

### Instalação Básica (Docker Engine)
```bash
chmod +x install-docker-wsl.sh
./install-docker-wsl.sh
```

### Instalação com NVIDIA Docker
```bash
chmod +x install-docker-wsl-nvidia.sh
./install-docker-wsl-nvidia.sh
```

## Verificação da Instalação

### Verificar Docker Engine
```bash
docker --version
docker info
```

### Verificar Docker Compose
```bash
docker compose version
```

### Testar com um Container Básico
```bash
docker run hello-world
```

### Testar NVIDIA Docker (se instalado)
```bash
docker run --gpus all nvidia/cuda:11.0-base nvidia-smi
```

## Configuração Post-Instalação

### Iniciar Docker ao Boot
```bash
sudo systemctl enable docker
sudo systemctl start docker
```

### Permissões
Para rodar Docker sem sudo:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Configurar Daemon Docker
Edite `/etc/docker/daemon.json` para configurações avançadas:
```json
{
  "registry-mirrors": ["https://docker-mirror.example.com"],
  "default-runtime": "nvidia"
}
```

## Uso Básico do Docker

### Listar Containers
```bash
docker ps -a
```

### Listar Imagens
```bash
docker images
```

### Buildar uma Imagem
```bash
docker build -t nome-da-imagem .
```

### Rodar um Container
```bash
docker run -d -p 8080:80 --name meu-container nome-da-imagem
```

### Ver Logs
```bash
docker logs meu-container
```

## Docker Compose

### Arquivo docker-compose.yml (Exemplo)
```yaml
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
```

### Rodar com Docker Compose
```bash
docker compose up -d
```

### Parar Containers
```bash
docker compose down
```

## Troubleshooting

### Docker Não Inicia
```bash
sudo systemctl status docker
sudo journalctl -u docker
```

### Erro de Permissão
Verifique se você está no grupo docker:
```bash
groups
```

### Problemas com NVIDIA Docker
1. Verifique se o driver NVIDIA está instalado no Windows
2. Verifique se o driver CUDA está instalado no WSL
3. Reinicie o Docker:
   ```bash
   sudo systemctl restart docker
   ```

### Problemas de Rede
1. Verifique se o daemon Docker está rodando
2. Reinicie o serviço Docker:
   ```bash
   sudo systemctl restart docker
   ```

