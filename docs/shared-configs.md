# Shared Cross-Platform Configuration

## Visão Geral

A pasta `shared/` contém configurações que funcionam **identicamente** em Windows, WSL e Linux Nativo. Esta abordagem elimina retrabalho e garante consistência entre ambientes.

## Filosofia

> **"Write once, use everywhere"** — configurações versionadas que viajam com você entre sistemas operacionais.

## Arquitetura

```
shared/
├── README.md                 # Este arquivo
├── .gitconfig                # Configuração ativa do Git (com TODOs)
├── .gitconfig.template       # Template completo com todas as opções
└── .gitignore_global         # Padrões ignorados em todos os repos
```

## Aplicação via Symlinks

| Sistema | Comando |
|---|---|
| **Linux/WSL** | `ln -sf $(pwd)/shared/.gitconfig ~/.gitconfig` |
| **Linux/WSL** | `ln -sf $(pwd)/shared/.gitignore_global ~/.gitignore_global` |
| **Windows** | `New-Item -ItemType SymbolicLink -Path $HOME\.gitconfig -Value 'C:\path\to\repo\shared\.gitconfig'` |

> **Nota:** O script `linux/setup.sh` cria esses symlinks automaticamente (Etapa 2).

---

## `.gitconfig` — Configuração Ativa

A configuração ativa é mínima e focada em funcionalidade essencial:

### Estrutura Atual

```ini
[user]
    email = TODO
    name = TODO

[credential]
    helper = cache --timeout=300

[credential "https://github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential

[credential "https://gist.github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
```

### Configuração Inicial

Após o primeiro setup, edite `~/.gitconfig` e substitua os `TODO`s:

```ini
[user]
    email = seu.email@exemplo.com
    name = Seu Nome
```

Ou configure interativamente via `setup.sh` (Etapa 8).

---

## `.gitconfig.template` — Template Completo

O template inclui todas as configurações avançadas para quem deseja um setup mais completo.

### Como Usar

```bash
# Opção 1: Copiar e editar manualmente
cp shared/.gitconfig.template shared/.gitconfig
# Edite shared/.gitconfig com seus dados

# Opção 2: Usar variáveis de ambiente
sed "s/\${GIT_USER_NAME}/Seu Nome/;s/\${GIT_USER_EMAIL}/seu@email.com/" \
    shared/.gitconfig.template > shared/.gitconfig
```

### Seções do Template

#### Core Settings

| Config | Valor | Descrição |
|---|---|---|
| `autocrlf` | `input` | Normaliza line endings (LF no repo) |
| `excludesfile` | `~/.gitignore_global` | Arquivo global de ignorados |
| `editor` | `nvim` | Editor padrão para commits |
| `pager` | `diff-so-fancy` | Output formatado de diffs |

#### Aliases

| Alias | Comando Expandido |
|---|---|
| `st` | `status -sb` (status curto com branch) |
| `ci` | `commit` |
| `co` | `checkout` |
| `br` | `branch` |
| `df` | `diff` |
| `lg` | `log --oneline --graph --all --decorate` |
| `ll` | `log --stat` |
| `last` | `log -1 HEAD --stat` |
| `amend` | `commit --amend --no-edit` |
| `aliases` | `config --get-regexp ^alias\\.` |
| `ignored` | `ls-files -o -i --exclude-standard` |

#### Pull/Push

| Config | Valor |
|---|---|
| `push.default` | `simple` (push só a branch atual) |
| `autoSetupRemote` | `true` (cria tracking automaticamente) |
| `pull.rebase` | `true` (rebase ao invés de merge) |

#### Diff & Merge

| Config | Valor |
|---|---|
| `merge.conflictstyle` | `zdiff3` (diff com contexto do ancestral) |
| `merge.tool` | `vscode` |
| `diff.algorithm` | `histogram` |
| `diff.colorMoved` | `zebra` |

**Integração VS Code:**
```bash
# Como diff tool
git difftool --tool=code --dir-diff

# Como merge tool
git mergetool --tool=code
```

#### GPG/Signing

```ini
[gpg]
    format = ssh
```

Assinatura de commits via SSH keys (sem necessidade de GPG).

#### Conditional Includes (Opcional)

```ini
# [includeIf "gitdir:~/work/"]
#     path = ~/.gitconfig-work

# [includeIf "gitdir:~/personal/"]
#     path = ~/.gitconfig-personal
```

Permite configurações diferentes por diretório de trabalho.

---

## Credential Helper — GitHub CLI

O `.gitconfig` está configurado para usar **GitHub CLI** (`gh`) como credential helper:

```ini
[credential "https://github.com"]
    helper = !/usr/bin/gh auth git-credential
```

### Autenticação

```bash
# Login no GitHub
gh auth login

# Verificar status
gh auth status

# Logout
gh auth logout
```

### Cache Local

Para repositórios que não usam GitHub ou quando `gh` não está disponível:
```ini
[credential]
    helper = cache --timeout=300
```
Credenciais ficam em cache por 5 minutos na memória.

---

## `.gitignore_global`

Padrões ignorados automaticamente em **todos** os repositórios Git do sistema.

### Categorias

| Categoria | Padrões |
|---|---|
| **Temporários** | `*.tmp`, `*.temp`, `*.swp`, `*.log` |
| **OS** | `.DS_Store`, `Thumbs.db`, `desktop.ini` |
| **IDEs** | `.vscode/`, `.idea/`, `*.sublime-*`, `*.swo`, `*~` |
| **Python** | `__pycache__/`, `*.py[cod]`, `*.egg-info/`, `dist/`, `build/`, `venv/`, `.venv/` |
| **Node.js** | `node_modules/` |
| **Docker** | `*.pid` |
| **Secrets** | `.secrets` |
| **Git pessoal** | `.gitconfig-work`, `.gitconfig-personal` |

### Verificar Efetividade

```bash
# Testar se um arquivo seria ignorado
git check-ignore -v caminho/do/arquivo

# Listar todos os arquivos que seriam ignorados
git status --ignored
```

---

## Mantendo Configurações Sincronizadas

### Estratégia

1. **Edite apenas os arquivos no repositório** (`shared/.gitconfig`, etc.)
2. **Os symlinks apontam para o repo** — mudanças refletem automaticamente
3. **Commite as mudanças** — versão suas configs

### Workflow Típico

```bash
# 1. Editar configuração
vi shared/.gitconfig

# 2. Verificar mudanças
git diff shared/.gitconfig

# 3. Commitar
git add shared/.gitconfig
git commit -m "feat(gitconfig): add new alias"

# 4. Push
git push
```

### Clonar em Nova Máquina

```bash
git clone https://github.com/avena/my-setup-os.git
cd my-setup-os

# Linux/WSL: rodar setup completo
bash linux/setup.sh

# Ou apenas criar symlinks manualmente
ln -sf $(pwd)/shared/.gitconfig ~/.gitconfig
ln -sf $(pwd)/shared/.gitignore_global ~/.gitignore_global
```

---

## Troubleshooting

### Symlink Não Funciona

```bash
# Verificar se é symlink
ls -la ~/.gitconfig

# Recriar symlink
ln -sf $(pwd)/shared/.gitconfig ~/.gitconfig
```

### Configurações Não São Aplicadas

```bash
# Verificar config ativa
git config --list --show-origin

# Verificar conflitos locais
git config --local --list
```

### Windows: Symlinks Requerem Permissões

No Windows, symlinks podem requerer **Developer Mode** ativado ou executar como **Administrador**:

```powershell
# Ativar Developer Mode (Windows 10/11)
# Settings > Update & Security > For developers > Developer mode
```
