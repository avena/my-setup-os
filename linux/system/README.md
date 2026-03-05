# Linux System Configuration

## Overview
Esta pasta contém configurações de sistema para Linux, aplicáveis tanto a **WSL** (Windows Subsystem for Linux) quanto a **Linux Nativo**.

## Arquivos na Pasta

### 1. .bashrc
Arquivo de configuração do shell Bash. Contém:
- Aliases úteis
- Configurações de prompt
- Variáveis de ambiente
- Funcionalidades personalizadas

### 2. .tmux.conf
Arquivo de configuração do Tmux (terminal multiplexer). Contém:
- Atalhos de teclado personalizados
- Configurações de aparência
- Plugins e extensões
- Gerenciamento de janelas e painéis

## Configuração

### Links Simbólicos
Para usar as configurações, crie links simbólicos no seu home directory:

```bash
# Para o .bashrc
ln -sf /caminho/para/repo/linux/system/.bashrc ~/.bashrc

# Para o .tmux.conf
ln -sf /caminho/para/repo/linux/system/.tmux.conf ~/.tmux.conf
```

## Detectando WSL

Para scripts que precisam saber se estão executando no WSL:

```bash
if uname -r | grep -q microsoft; then
    echo "Running on WSL"
    # Configurações específicas do WSL
else
    echo "Running on Linux Native"
    # Configurações específicas do Linux Nativo
fi
```

## .bashrc Personalizações

### Aliases Úteis
```bash
alias ll='ls -laF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
```

### Prompt Customizado
Mostra o usuário, hostname, diretório atual e status do git.

### Funcionalidades
- Autocompletar
- Histórico de comandos
- Correção automática de comandos
- Destaque de sintaxe

## .tmux.conf Personalizações

### Atalhos
```tmux
# Atalho para prefixo (C-b -> C-a)
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Split vertical/horizontal
bind | split-window -h
bind - split-window -v
```

### Aparência
- Status bar personalizada
- Cores para janelas e painéis
- Indicador de atividade

### Plugins
Plugins instalados via Tmux Plugin Manager (TPM):
- `tmux-plugins/tpm` - Gerenciador de plugins
- `tmux-plugins/tmux-sensible` - Configurações sensatas padrão
- `tmux-plugins/tmux-resurrect` - Salva e restaura sessões

## Requisitos

### Tmux
Instale o Tmux:
```bash
# Ubuntu/Debian
sudo apt install tmux

# Fedora
sudo dnf install tmux
```

### Tmux Plugin Manager (TPM)
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

## Uso Básico do Tmux

### Iniciar Tmux
```bash
tmux
```

### Lista de Atalhos Básicos
- `Prefix + I`: Instala plugins
- `Prefix + U`: Atualiza plugins
- `Prefix + R`: Recarrega configuração
- `Prefix + ?`: Lista de atalhos disponíveis

## Troubleshooting

### Tmux Plugins Não Carregam
Verifique se o TPM está instalado e execute:
```tmux
Prefix + I
```

### Prompt Não Atualiza
Recarregue o .bashrc:
```bash
source ~/.bashrc
```

