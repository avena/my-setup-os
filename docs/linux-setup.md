# Linux/WSL Setup Guide

## Visão Geral

Este guia documenta todo o ambiente Linux/WSL configurado neste repositório. A pasta `linux/` contém scripts e configurações para bootstrap automático de um ambiente de desenvolvimento completo.

## Arquitetura

```
linux/
├── setup.sh                       # Script principal de bootstrap
├── cli/                           # Top 26 CLIs de IA/Coding
│   ├── top-clis.sh                # Catálogo interativo
│   ├── install-entire.sh          # Instala Entire CLI + plugin brain (checkpoints)
│   └── README.md
├── containers/                    # Docker Engine + NVIDIA GPU
│   ├── install-docker-wsl.sh
│   ├── install-docker-wsl-nvidia.sh
│   └── README.md
├── fonts/                         # Instalação de fontes
│   ├── install-fonts.sh
│   └── README.md
├── homebrew/                      # Homebrew no Linux
│   ├── install-homebrew.sh
│   ├── install-brew-packages.sh
│   ├── Brewfile
│   └── README.md
├── packages/                      # Gerenciamento de pacotes
│   ├── install-apt-packages.sh
│   └── README.md
└── system/                        # Configurações de sistema
    ├── .bashrc                    # Shell Bash + aliases
    ├── .tmux.conf                 # Tmux multiplexer
    └── README.md
```

## Setup Unificado (`setup.sh`)

O script `linux/setup.sh` é o ponto de entrada principal. Ele detecta automaticamente se está rodando no **WSL** ou **Linux Nativo** e executa 11 etapas sequenciais:

### Etapas do Setup

| # | Etapa | Descrição |
|---|---|---|
| 1 | **Detecção de Ambiente** | Identifica WSL vs Linux nativo via `uname -r` |
| 2 | **Links Simbólicos** | Cria symlinks para `.gitconfig`, `.bashrc`, `.tmux.conf`, `.gitignore_global` |
| 3 | **Pacotes APT** | Instala pacotes do sistema via `install-apt-packages.sh` |
| 4 | **Homebrew** | Instala Homebrew via `install-homebrew.sh` |
| 5 | **Brewfile** | Instala pacotes declarativos via `install-brew-packages.sh` |
| 6 | **Fontes** | Instala Fira Code, JetBrains Mono, Cascadia Code (+ Nerd Fonts) |
| 7 | **Docker** | Verifica ou instala Docker Engine (interativo) |
| 8 | **Git Config** | Solicita nome/email se ainda com `TODO` no `.gitconfig` |
| 9 | **TPM** | Instala Tmux Plugin Manager |
| 10 | **Top 26 CLIs** | Instala CLIs de IA/Coding via `top-clis.sh` (interativo) |
| 11 | **Entire CLI** | Instala o Entire CLI + plugin brain via `install-entire.sh` (checkpoints de sessões) |

### Execução

```bash
cd linux/
bash setup.sh
```

### Links Simbólicos Criados

| Origem | Destino |
|---|---|
| `shared/.gitconfig` | `~/.gitconfig` |
| `linux/system/.bashrc` | `~/.bashrc` |
| `linux/system/.tmux.conf` | `~/.tmux.conf` |
| `shared/.gitignore_global` | `~/.gitignore_global` |

> **Nota:** Backups automáticos dos arquivos existentes são criados como `~/.bashrc.backup`, etc.

---

## Sistema (`.bashrc` e `.tmux.conf`)

### `.bashrc` — Shell Bash

#### Configurações Base
- Histórico com `HISTSIZE=1000`, `HISTFILESIZE=2000`
- `HISTCONTROL=ignoreboth` (sem duplicatas, sem espaços)
- Cores automáticas para `ls`, `grep`
- Autocompletar bash completion
- Suporte a aliases externos via `~/.bash_aliases`

#### PATH Personalizado
```bash
# OpenCode
export PATH="$HOME/.opencode/bin:$PATH"

# Kilo Code
export PATH="$HOME/.kilo/bin:$PATH"
```

#### NVM (Node Version Manager)
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

#### Homebrew Linux
```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
```

#### Aliases OpenClaude

| Alias | Modelo |
|---|---|
| `oc-nemo` | `nvidia/nemotron-3-super-120b-a12b:free` |
| `oc-trinity` | `arcee-ai/trinity-large-preview:free` |
| `oc-minimax` | `minimax/minimax-m2.5:free` |
| `oc-gptoss` | `openai/gpt-oss-120b:free` |
| `oc-glm` | `z-ai/glm-4.5-air:free` |

**Uso:**
```bash
oc-nemo    # Abre OpenClaude com Nemotron 3 Super
oc-glm     # Abre OpenClaude com GLM 4.5 Air
```

### `.tmux.conf` — Terminal Multiplexer

#### Configurações Principais
- **Prefixo:** `Ctrl+a` (ao invés de `Ctrl+b`)
- **Mouse:** Habilitado (rolar, redimensionar panes)
- **Status bar:** Inferior, atualiza a cada 5s
- **Navegação vim:** `h/j/k/l` entre panes

#### Atalhos Principais

| Atalho | Ação |
|---|---|
| `Ctrl+a + %` | Split vertical |
| `Ctrl+a + "` | Split horizontal |
| `Ctrl+a + h/j/k/l` | Navegar entre panes |
| `Ctrl+a + r` | Recarregar config |
| `Ctrl+a + I` | Instalar plugins |
| `Ctrl+a + ?` | Lista de atalhos |

#### Auto-Setup de Sessão
Ao criar uma sessão, automaticamente abre 4 janelas:
1. `1-shell` — terminal principal
2. `2-logs` — para logs
3. `3-editor` — para edição
4. `4-monitor` — com split vertical para monitoramento

---

## Homebrew Linux

### Pacotes do Brewfile

| Categoria | Pacotes |
|---|---|
| **Core utilities** | curl, wget, htop, tree, jq |
| **Development** | git, node, python@3.14, gcc, ripgrep |
| **Terminal** | tmux, vim, nano |
| **Custom tools** | kilo, gemini-cli, opencode, micasa |
| **Libraries** | openssl, readline, sqlite, xz, zstd, bzip2, lz4, pcre2, gmp, mpfr, icu4c, ca-certificates |
| **Network** | libnghttp2, libnghttp3, c-ares, ada-url, simdjson, hdrhistogram_c |

### Comandos Úteis

```bash
# Atualizar pacotes
brew update && brew upgrade

# Listar instalados
brew list

# Exportar Brewfile atual
brew bundle dump --file=Brewfile --force

# Verificar problemas
brew doctor
```

---

## Docker

### Scripts Disponíveis

| Script | Uso |
|---|---|
| `install-docker-wsl.sh` | Docker Engine básico |
| `install-docker-wsl-nvidia.sh` | Docker + NVIDIA GPU passthrough |

### Verificação

```bash
docker --version
docker run hello-world

# Testar GPU (se nvidia)
docker run --gpus all nvidia/cuda:11.0-base nvidia-smi
```

### Permissões (sem sudo)

```bash
sudo usermod -aG docker $USER
newgrp docker
```

---

## Top 26 CLIs

Script interativo que gerencia 26 CLIs de IA/Coding. Documentação completa em [top-clis.md](top-clis.md).

```bash
bash linux/cli/top-clis.sh
```

### Comandos

| Comando | Ação |
|---|---|
| `scan` ou `s` | Lista CLIs instalados |
| `todos` ou `t` | Instala todos os faltantes |
| `1,2,3` | Instala CLIs individuais |
| `sair` ou `q` | Encerra |

---

## Entire CLI — Checkpoints de Sessões + Brain

O [Entire](https://entire.com) é o git forge para colaboração agente-humano: publica as sessões dos
coding agents junto aos commits (checkpoints) e constrói um *brain* consultável por repositório.
Documentação completa: [entire.md](entire.md).

```bash
# Instalação (CLI + plugin brain)
bash linux/cli/install-entire.sh

# Login e habilitação de checkpoints
entire login              # use --device em SSH/container
entire enable             # dentro de qualquer repositório git

# Brain
entire brain setup        # índice local + backfill + watcher
entire brain connect      # sincroniza com o brain hospedado da equipe
```

| Etapa | Comando | O que faz |
|---|---|---|
| 1. Instalar | `bash linux/cli/install-entire.sh` | CLI + plugin `brain` |
| 2. Login | `entire login` | Vincula a conta da CLI |
| 3. Habilitar | `entire enable` | Todo push passa a publicar checkpoints |
| 4. Repo | `entire repo clone /et/<projeto>/<repo>` | Clone novo do forge Entire |
| 4b. Repo | `entire repo remote add origin --override /et/<projeto>/<repo>` | Aponta clone existente |
| 5. Brain | `entire plugin install brain` | Plugin de memória contínua |
| 6. Brain | `entire brain setup` | Índice local + backfill + daemon |
| 7. Brain | `entire brain connect` | Sincroniza com o brain hospedado |

Consulta: `entire brain query "..."`, `entire brain brief <tarefa>`, `entire brain overview`.
Segredos são detectados e redigidos antes de qualquer armazenamento; o brain é **local por padrão**.

---

## Fontes

### Instaladas via `install-fonts.sh`

| Fonte | Versão |
|---|---|
| Fira Code | Clean |
| Fira Code NF | Nerd Font |
| JetBrains Mono | Clean |
| JetBrains Mono NF | Nerd Font |
| Cascadia Code | Clean |
| Cascadia Code NF | Nerd Font |

### Detecção Automática

O script detecta o package manager (apt/dnf/pacman/Homebrew) e usa o método apropriado.

---

## Pós-Setup

Após rodar `setup.sh`:

```bash
# 1. Recarregar shell
source ~/.bashrc

# 2. Instalar plugins tmux
tmux → Ctrl+a + I

# 3. Verificar instalações
docker --version
git config --list
tmux -V

# 4. Verificar CLIs
bash linux/cli/top-clis.sh → scan

# 5. Entire CLI (checkpoints de sessões + brain)
bash linux/cli/install-entire.sh     # se ainda não rodou no setup
entire login                          # --device em SSH/container
entire enable                         # dentro de um repositório git
entire plugin install brain           # memória contínua
entire brain setup                    # índice local + backfill + watcher
entire brain connect                  # sincroniza com o brain hospedado
entire status                         # confere o estado no repositório
```

Guia completo: [entire.md](entire.md).
