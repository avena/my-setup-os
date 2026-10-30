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

### Scripts e Templates de Skills para Coding Agents
- **`instalar-skills-novo-projeto.sh`**: Script para configurar e registrar automaticamente o EGM (Google) e o Security Audit (Cloudflare) em novos repositórios.
- **`instalar-skills-mattpocock.sh`**: Script de sincronização que propaga as skills para os 9 CLIs de coding agents.
- **`inventario-instalado.md`**: Inventário consolidado do sistema, pacotes, plugins e skills instaladas.
- **`reconstruir-ambiente.md`**: Guia passo a passo para restaurar todo o ambiente a partir do zero.
- **`templates/novo-projeto/`**: Template contendo `skills-lock.json` e `opencode.jsonc` pré-configurados.

---

## Skills para Coding Agents (EGM & Security Audit)

### Como Acionar as Skills no seu Coding Agent

#### 1. Elephant-Goldfish Model (Google EGM)
No **Antigravity (agy CLI)** e **Claude Code**, utilize o prefixo `/egm:`. No **Codex** e **OpenCode**, utilize o seletor de skills ou invoque diretamente:

- **Ideação e Brainstorm:**
  ```text
  /egm:egm-brainstorm Adicionar autenticação OAuth2 neste projeto
  ```
  *(Explora requisitos e trade-offs, subagentes desafiam a proposta e salvam o direcionamento em `concepts_brief.md`)*

- **Redação da Especificação:**
  ```text
  /egm:egm-draft
  ```
  *(Transforma o brief em `design_draft.md`, pausando após cada seção para validação em chat)*

- **Revisão Adversarial com Subagentes (Goldfish):**
  ```text
  /egm:egm-review design_draft.md
  ```
  *(Subagentes 'goldfish' examinam o rascunho sem viés histórico e reportam lacunas e premissas implícitas)*

- **Resolução de apontamentos:**
  ```text
  /egm:egm-resolve
  ```
  *(Aplica conciliações e correções aprovadas no documento de design)*

- **Checagem de consistência docs vs código:**
  ```text
  /egm:egm-drift-report
  ```
  *(Verifica divergências entre documentos de arquitetura e o código-fonte)*

#### 2. Security Audit (Cloudflare)
- `security audit this codebase`
- `find security vulnerabilities in ./src`
- `do a security review, output to ~/audits/meu-projeto`

### Instalar Skills em Novos Projetos
```bash
skills-novo-projeto
# ou com o pacote completo de engenharia/produtividade:
skills-novo-projeto --all
```

---

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

