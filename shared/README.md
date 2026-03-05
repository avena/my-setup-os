# Shared Configuration (Cross-Platform)

## Overview
Esta pasta contém configurações que funcionam em **todos os sistemas operacionais** (Windows, Linux, WSL). As configurações compartilhadas evitam retrabalho e garantem consistência entre ambientes.

## Arquivos na Pasta

### .gitconfig
Arquivo de configuração do Git, válido para todos os ambientes. Contém:
- Configurações de usuário (nome e email)
- Aliases úteis para o Git
- Configurações de core (encoding, autocrlf)
- Configurações de diff e merge
- Inclusão de configurações específicas do sistema

## Configuração

### Links Simbólicos

#### Linux/WSL
```bash
ln -sf /caminho/para/repo/shared/.gitconfig ~/.gitconfig
```

#### Windows
```powershell
New-Item -ItemType SymbolicLink -Path $HOME\.gitconfig -Value 'C:\caminho\para\repo\shared\.gitconfig' -Force
```

## Estrutura do .gitconfig

### Configurações Básicas
```ini
[user]
    name = Seu Nome
    email = seu.email@exemplo.com

[core]
    autocrlf = input
    excludesfile = ~/.gitignore_global
```

### Aliases Úteis
```ini
[alias]
    st = status
    ci = commit
    br = branch
    co = checkout
    df = diff
    lg = log --oneline --graph --all
    ll = log --stat
```

### Configurações de Merge/Diff
```ini
[merge]
    tool = vscode
[difftool "vscode"]
    cmd = code --wait --diff $LOCAL $REMOTE
```

### Inclusão de Configurações Específicas
```ini
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```

## Gitignore Global

Crie um arquivo `~/.gitignore_global` para ignorar arquivos em todos os repositórios:
```gitignore
# Arquivos temporários
*.tmp
*.temp
*.swp

# Logs
*.log

# Editor
.vscode/
.idea/
*.sublime-project
*.sublime-workspace

# Sistemas operacionais
.DS_Store
Thumbs.db
```

## Configuração Específica do Sistema

Se precisar de configurações específicas por sistema operacional, crie arquivos separados:

### Linux/WSL (`.gitconfig-linux`)
```ini
[core]
    editor = nano
[alias]
    lg = log --oneline --graph --all --stat
```

### Windows (`.gitconfig-windows`)
```ini
[core]
    editor = \"C:/Program Files (x86)/Notepad++/notepad++.exe\" -multiInst -notabbar -nosession -noPlugin
[alias]
    lg = log --oneline --graph --all
```

## Dicas de Uso

### Verificar Configuração Ativa
```bash
git config --list
```

### Verificar Configuração do Repositório
```bash
git config --local --list
```

### Editar Configuração Diretamente
```bash
git config --global --edit
```

## Troubleshooting

### Arquivo .gitconfig Não É Lido
1. Verifique se o link simbólico está correto
2. Verifique as permissões do arquivo
3. Reinicie o terminal

### Configurações Não São Aplicadas
1. Verifique a ordem das configurações (local > global > system)
2. Verifique se há configurações em conflito no repositório
3. Limpar o cache:
   ```bash
   git config --global --unset-all nome.da.configuracao
   ```

