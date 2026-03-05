# my-setup-os

## Overview
Este repositório contém a configuração personalizada para meu ambiente de trabalho **cross-platform**, suportando:
- **Windows** (Host)
- **WSL 2** (Windows Subsystem for Linux)
- **Linux Nativo** (Ubuntu, Fedora, etc.)

A estrutura é organizada de forma a separar configurações específicas de cada sistema operacional, enquanto mantém compartilhadas configurações que funcionam em todos os ambientes.

## Arquitetura Cross-Platform

A organização segue o conceito de **"terreno e veículos"**:
- **Sistema Operacional**: O "terreno" onde as configurações rodam
- **Configurações**: Os "veículos" que adaptam-se ao terreno
- **Shared**: A "carteira de motorista" que funciona em todos os sistemas

## Estrutura do Repositório

```text
my-setup-os/
├── README.md                          # Este arquivo - Introdução ao projeto
├── docs/                              # Documentation and references
│   ├── fonts.md                       # Instalação de fontes para editores e terminais
│   └── references/                    # Curated references for dotfiles management
│       └── README.md                  # Guide to dotfiles resources and best practices
├── shared/                            # Configurações cross-platform
│   ├── .gitconfig                     # Configuração do Git (valida para todos)
│   └── README.md                      # Explicação das configurações compartilhadas
│
├── windows/                           # Configurações específicas do Windows Host
│   ├── fonts/                         # Instalação de fontes para Windows
│   │   ├── install-fonts.ps1          # Instalação via Scoop
│   │   └── README.md                  # Explicação da instalação de fontes
│   ├── networking/                    # Scripts PowerShell para NAT e DHCP
│   │   ├── *.ps1                      # Scripts de configuração de rede
│   │   ├── simple-dhcp-server-qt.yml  # Configuração do DHCP Server
│   │   └── README.md                  # Explicação dos scripts de rede
│   ├── scoop/                         # Gerenciador de pacotes Scoop
│   │   ├── scoop-programs.json        # Lista de programas instalados
│   │   └── README.md                  # Instruções do Scoop e UnigetiUI
│   ├── Set-PowerShell7AsDefault.ps1   # Configura PowerShell 7 como padrão
│   └── README.md                      # Overview das configurações Windows
│
└── linux/                            # Configurações para Linux (WSL ou Nativo)
    ├── fonts/                         # Instalação de fontes para Linux/macOS
    │   ├── install-fonts.sh           # Instalação via apt/dnf/pacman/Homebrew
    │   └── README.md                  # Explicação da instalação de fontes
    ├── system/                        # Configurações de sistema
    │   ├── .bashrc                   # Configuração do shell Bash
    │   ├── .tmux.conf                # Configuração do Tmux
    │   └── README.md                 # Explicação das configurações de sistema
    ├── containers/                   # Docker e containerização
    │   ├── install-docker-wsl*.sh    # Scripts de instalação do Docker
    │   └── README.md                 # Instruções do Docker
    └── packages/                     # Gerenciamento de pacotes
        └── README.md                 # Instruções de instalação de pacotes
```

## Características Principais

### 1. Compatibilidade Multiplataforma
- Configurações compartilhadas (`.gitconfig`) funcionam em todos os sistemas
- Scripts detectam automaticamente se estão rodando no WSL
- Arquitetura modular para fácil extensão

### 2. Eficiência
- Links simbólicos mantêm a configuração sincronizada
- Scripts de instalação automatizadas
- Gestão de pacotes centralizada

### 3. Manutenibilidade
- Estrutura clara e intuitiva
- Documentação detalhada em cada pasta
- Configurações versionadas com Git

### 4. Segurança
- Permissões mantidas no sistema Linux
- Scripts verificados e testados
- Arquivos de configuração seguros

## Guia Rápido

### Pré-requisitos
- Git instalado em todos os sistemas
- PowerShell 7+ (Windows) - recomendado (use `Set-PowerShell7AsDefault.ps1` para configurar)
- WSL 2 (se usar Windows)
- Bash/Zsh (Linux/WSL)

### Passo a Passo

1. **Clonar o Repositório**
   ```bash
   git clone https://github.com/avena/my-setup-os.git
   cd my-setup-os
   ```

2. **Configurar Links Simbólicos**
   ```bash
   # Linux/WSL
   ln -sf $(pwd)/shared/.gitconfig ~/.gitconfig
   ln -sf $(pwd)/linux/system/.bashrc ~/.bashrc
   ln -sf $(pwd)/linux/system/.tmux.conf ~/.tmux.conf
   ```

3. **Instalar Dependências**
   - **Windows**: Execute scripts PowerShell na pasta `windows/networking/`
   - **Linux/WSL**: Execute scripts na pasta `linux/containers/` e `linux/packages/`

4. **Verificar Configuração**
   ```bash
   # Verificar Git
   git config --list

   # Verificar Docker
   docker --version

   # Verificar Tmux
   tmux -V
   ```

## Instruções por Plataforma

### Windows Host
- **Scoop**: Gerenciador de pacotes (instalação via `windows/scoop/README.md`)
- **Rede**: Scripts PowerShell para NAT e DHCP (via `windows/networking/README.md`)
- **WSL**: Configuração do WSL 2 (via `linux/system/README.md`)
- **Fontes**: Instalação de fontes via `windows/fonts/install-fonts.ps1`
- **PowerShell 7**: Configuração como padrão via `windows/Set-PowerShell7AsDefault.ps1`

### WSL 2
- **Docker**: Instalação via `linux/containers/install-docker-wsl.sh`
- **Shell**: Configuração Bash/Tmux via `linux/system/README.md`
- **Pacotes**: Instalação via `linux/packages/README.md`

### Linux Nativo
- **Docker**: Instalação via `linux/containers/install-docker-wsl.sh` (adaptado)
- **Shell**: Configuração Bash/Tmux via `linux/system/README.md`
- **Pacotes**: Instalação via `linux/packages/README.md`

## Solução de Problemas

### 1. Links Simbólicos Não Funcionam
- **Windows**: Verifique permissões de administrador
- **Linux/WSL**: Verifique a existência do arquivo de origem

### 2. Scripts Não Executam
- **Windows**: Verifique a política de execução de scripts PowerShell
- **Linux/WSL**: Verifique permissões de execução (`chmod +x script.sh`)

### 3. WSL Não Detecta Configurações
Verifique se os links simbólicos estão corretos e o arquivo `.wslconfig` existe no Windows.

## Contribuição

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/sua-feature`)
3. Commit suas mudanças (`git commit -m 'Add some feature'`)
4. Push para a branch (`git push origin feature/sua-feature`)
5. Abra um Pull Request

## Licença

MIT License - Veja `LICENSE` para mais detalhes.

## Recursos e Referências

O diretório docs/references/ contém uma coleção curada de referências e inspiração para gerenciamento de dotfiles, incluindo:

- Repositórios famosos de dotfiles (mathiasbynens, holman, paulirish, jessfraz)
- Ferramentas de gerenciamento (chezmoi, nixos-config)
- Configurações para terminal e shell (gpakosz/.tmux)
- Melhores práticas e exemplos

## Agradecimentos

- **Scoop**: Gerenciador de pacotes para Windows
- **Docker**: Plataforma de contêineres
- **Tmux**: Terminal multiplexer
- **WSL**: Windows Subsystem for Linux
