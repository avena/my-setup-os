# Linux Package Management

## Overview
Esta pasta contém scripts e listas de pacotes para gerenciamento de dependências no Linux/WSL.

## Package Managers Suportados

### Homebrew (Opcional)
O Homebrew está disponível como mais uma opção de gerenciador de pacotes para Linux/WSL.

**Vantagens:**
- Cross-platform: Mesma ferramenta no macOS e Linux
- Declarativo: Brewfile permite versionamento e reprodução exata
- Isolamento: Pacotes instalados em `/home/linuxbrew` não conflitam com o sistema
- Atualizações fáceis: `brew upgrade` atualiza tudo de uma vez

**Instalação:**
```bash
cd ../homebrew/
./install-homebrew.sh
./install-brew-packages.sh
```

**Brewfile:**
O arquivo `Brewfile` contém a lista declarativa de pacotes para instalação via Homebrew.

### Debian/Ubuntu (apt)
- Arquivo `packages.apt` com lista de pacotes
- Script `install-apt-packages.sh` para instalação

### Fedora (dnf)
- Arquivo `packages.dnf` com lista de pacotes
- Script `install-dnf-packages.sh` para instalação

### Snap
- Arquivo `packages.snap` com lista de pacotes snap
- Script `install-snap-packages.sh` para instalação

## Estrutura de Arquivos de Pacotes

### Exemplo (packages.apt)
```text
# Ferramentas de terminal
curl
wget
htop
tmux
vim
nano

# Ferramentas de desenvolvimento
git
git-flow
tree
jq
```

## Instalação

### Pré-requisitos
- Acesso a repositórios (apt/dnf)
- Permissões de sudo

### Homebrew
```bash
cd ../homebrew/
./install-homebrew.sh
./install-brew-packages.sh
```

### Debian/Ubuntu
```bash
chmod +x install-apt-packages.sh
./install-apt-packages.sh
```

### Fedora
```bash
chmod +x install-dnf-packages.sh
./install-dnf-packages.sh
```

### Snap
```bash
chmod +x install-snap-packages.sh
./install-snap-packages.sh
```

## Pacotes Comuns

### Ferramentas Básicas
- curl, wget - Download de arquivos
- htop, top - Monitoramento do sistema
- tree - Visualização da estrutura de pastas
- jq - Processamento de JSON
- tmux - Terminal multiplexer

### Ferramentas de Desenvolvimento
- git - Controle de versão
- git-flow - Workflow Git
- gcc, g++ - Compiladores C/C++
- python3, python3-pip - Python
- nodejs, npm - Node.js
- openjdk-11-jdk - Java

### Ferramentas de Rede
- ssh - Acesso remoto
- nmap - Scanner de redes
- tcpdump - Captura de pacotes
- netcat - Ferramenta de rede genérica

### Ferramentas de Contêiner
- docker.io - Docker Engine
- docker-compose - Docker Compose
- podman - Ferramenta de contêineres rootless

## Gerenciamento de Pacotes

### Atualizar Lista de Pacotes
```bash
# Homebrew
brew update

# Debian/Ubuntu
sudo apt update

# Fedora
sudo dnf update
```

### Instalar Pacote Individual
```bash
# Homebrew
brew install nome-do-pacote

# Debian/Ubuntu
sudo apt install nome-do-pacote

# Fedora
sudo dnf install nome-do-pacote
```

### Remover Pacote
```bash
# Homebrew
brew uninstall nome-do-pacote

# Debian/Ubuntu
sudo apt remove nome-do-pacote
sudo apt autoremove

# Fedora
sudo dnf remove nome-do-pacote
sudo dnf autoremove
```

### Atualizar Todos os Pacotes
```bash
# Homebrew
brew upgrade

# Debian/Ubuntu
sudo apt upgrade

# Fedora
sudo dnf upgrade
```

## Configuração de Repositórios

### Adicionar Repositório PPA (Debian/Ubuntu)
```bash
sudo add-apt-repository ppa:user/repository
sudo apt update
```

### Habilitar Repositórios (Fedora)
```bash
sudo dnf config-manager --set-enabled repository-name
```

## Scripts de Instalação

### install-apt-packages.sh
Script para instalar pacotes apt automaticamente:
```bash
#!/bin/bash
while IFS= read -r package; do
    if [ -z "$package" ] || [ "${package:0:1}" = "#" ]; then
        continue
    fi
    sudo apt install -y "$package"
done < "packages.apt"
```

### install-dnf-packages.sh
Script para instalar pacotes dnf automaticamente:
```bash
#!/bin/bash
while IFS= read -r package; do
    if [ -z "$package" ] || [ "${package:0:1}" = "#" ]; then
        continue
    fi
    sudo dnf install -y "$package"
done < "packages.dnf"
```

## Troubleshooting

### Erro de Permissão
Verifique se você está usando sudo.

### Pacote Não Encontrado
1. Verifique a ortografia do pacote
2. Verifique se o repositório está habilitado
3. Atualize a lista de pacotes:
   ```bash
   brew update              # Homebrew
   sudo apt update          # Debian/Ubuntu
   sudo dnf update          # Fedora
   ```

### Conexão Falha
Verifique a conectividade com a internet e os repositórios.

### Homebrew Não Encontrado
Execute para carregar o PATH:
```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```
