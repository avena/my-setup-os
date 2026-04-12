# Top CLIs Installer — Documentação

## Visão Geral

O `top-clis.sh` é um script bash interativo que funciona como catálogo instalável e verificável de **26 CLIs de IA e coding** para Linux/WSL. Ele gerencia dependências, instala individualmente ou em lote, e verifica o status de instalação de cada ferramenta.

## Arquitetura

### Arquivo

| Arquivo | Localização | Função |
|---|---|---|
| `top-clis.sh` | `linux/cli/` | Catálogo interativo de 26 CLIs |

### Como Usar

```bash
bash linux/cli/top-clis.sh
```

## Catálogo TOP 26 CLIs IA/CODING 2026

### CLIs Oficiais (1-23)

| # | Nome | Binário | Dependência | Instalação |
|---|---|---|---|---|
| 1 | Claude Code | `claude-code` | npm | `npm i -g claude-code` |
| 2 | Kilo Code | `kilo` | curl | Download do GitHub → `~/.kilo/bin/` |
| 3 | Aider | `aider` | pip3 | `pip3 install --user aider-chat` |
| 4 | Gemini CLI | `gemini` | npm | `npm i -g @google/gemini-cli` |
| 5 | Codex CLI | `codex` | npm | `npm i -g @openai/codex` |
| 6 | OpenCode | `opencode` | curl | Download do GitHub → `~/.opencode/bin/` |
| 7 | Qwen Code | `qwen` | npm | `npm i -g @qwen-code/qwen-code` |
| 8 | Crush CLI | `crush` | apt | Repositório Charm.sh via apt |
| 9 | Plandex | `plandex` | curl | Script oficial `plandex.ai/install.sh` |
| 10 | Goose | `goose` | curl | Script oficial do GitHub |
| 11 | Amazon Q CLI | `amazon-q-cli` | pip3 | `pip3 install --user amazon-q-cli` |
| 12 | Vibe CLI | `vibe-cli` | npm | `npm i -g vibe-cli` |
| 13 | Cline | `cline` | npm | `npm i -g cline@latest` |
| 14 | Bolt CLI | `bolt-new` | npm | `npm i -g bolt-new` |
| 15 | PyGPT | `pygpt` | pip3 | `pip3 install --user pygpt-net` |
| 16 | AIChat | `aichat` | npm | `npm i -g aichat` |
| 17 | Droid | `droid-cli` | cargo | `cargo install droid-cli` |
| 18 | Replit Agent | `replit` | npm | `npm i -g @replit/agent` |
| 19 | Tabby CLI | `tabby` | docker | Container Docker `tabbyml/tabby` |
| 20 | Kimi Code | `kimi` | curl | `curl -L code.kimi.com/install.sh | bash` |
| 21 | Roo Code | `roo-cline` | npm | `npm i -g roo-cline` |
| 22 | OpenClaw | `openclaw` | curl | Script oficial `openclaw.dev/install.sh` |
| 23 | nanocode | `nanocode` | pip3 | `pip3 install --user nanocode` |

### CLIs Comunitários (24-26)

| # | Nome | Binário | Dependência | Instalação | Notas |
|---|---|---|---|---|---|
| 24 | OpenClaude | `openclaude` | npm | `npm i -g @gitlawb/openclaude` | Provider OpenAI-compatible; `rg` recomendado |
| 25 | ZAI CLI | `zai` | npm | `npm i -g @guizmo-ai/zai-cli` | Requer API key em `~/.zai/user-settings.json` |
| 26 | Top100CLIs | `top100clis` | curl | Download do GitHub → `/usr/local/bin/` | Ferramenta comunitária de listagem |

## Modo de Uso

### Iniciar o Script

```bash
bash linux/cli/top-clis-installer.sh
# ou, se já instalado:
~/top-clis.sh
```

### Comandos Disponíveis

| Comando | Descrição |
|---|---|
| `scan` ou `s` | Lista todos os 26 CLIs e mostra quais estão instalados (com versão) |
| `todos` ou `t` | Instala automaticamente todos os CLIs que ainda não estão presentes |
| `3,4,20` | Números separados por vírgula para instalação individual |
| `sair`, `q` ou `exit` | Encerra o script |

### Exemplo de Sessão

```
TOP 26 CLIs IA/CODING 2026
[OK]  1. Claude Code      v1.2.3
[--]  2. Kilo Code
[OK]  3. Aider            v0.75.0
...
Instalados: 8 / 26

uso: numeros por virgula (ex: 3,4,20) | todos | scan | sair
comunitarios: #24 OpenClaude, #25 ZAI CLI, #26 Top100CLIs

escolha: 2
```

## Gerenciamento de Dependências

O script detecta e instala automaticamente as dependências necessárias:

| Dependência | Instalação | Requer sudo |
|---|---|---|
| **npm/Node.js** | nodesource setup + `apt install nodejs` | Sim |
| **pip3** | `apt install python3-pip` | Sim |
| **Cargo/Rust** | `rustup` (instalador oficial) | Não |
| **Docker** | `get.docker.com` | Sim |
| **curl** | `apt install curl` | Sim |
| **apt** | Nativo do sistema | — |

### Configuração npm User

Para instalações globais via npm sem sudo, o script configura:
```bash
npm config set prefix ~/.npm-global
export PATH="$HOME/.npm-global/bin:$PATH"
```

## Notas Pós-Instalação

### Kimi Code (#20)
- Após instalar, execute `kimi`
- Use `/login` para autenticar
- Use `/help` para ver comandos disponíveis

### OpenClaude (#24) — Comunitário
- Configure o provider com `/provider` (suporta OpenAI-compatible, OpenRouter)
- **Recomendado**: instale `ripgrep` (`rg`) para melhor experiência
  ```bash
  sudo apt install -y ripgrep
  ```

### ZAI CLI (#25) — Comunitário
- **Não oficial** — projeto da comunidade, não da Z.ai
- Requer configuração de API key
- Arquivo de configurações: `~/.zai/user-settings.json`

### Top100CLIs (#26) — Comunitário
- Ferramenta comunitária para listagem de CLIs
- Não é um agente de coding

## Solução de Problemas

### Binário não encontrado após instalação

```bash
source ~/.bashrc
# ou
hash -r
```

### npm não encontrado

O script tenta instalar Node.js automaticamente. Se falhar:
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
```

### Docker sem permissão

```bash
sudo usermod -aG docker $USER
# Relogue na sessão
```

### Rust/Cargo não no PATH

```bash
source ~/.cargo/env
```

## Estrutura Interna do Script

### Arrays Associativos

| Array | Função |
|---|---|
| `N` | Nomes legíveis dos CLIs |
| `B` | Nomes dos binários (comando) |
| `D` | Dependências de cada CLI |
| `C` | Comandos de instalação |
| `T` | Tipo (oficial/comunitário) |

### Funções Principais

| Função | Descrição |
|---|---|
| `check_status()` | Verifica e lista CLIs instalados com versão |
| `setup_cli()` | Configura dependências, instala um CLI e verifica pós-instalação |
| `check_dep()` | Valida/instala dependência (npm, pip3, cargo, docker, curl, apt) |
| `reload_path()` | Atualiza PATH com diretórios de instalação |
| `setup_npm_user()` | Configura prefixo global do npm para evitar sudo |

## Referências

- [Kimi Code Docs](https://www.kimi.com/code/docs/en/kimi-cli/guides/getting-started.html)
- [OpenClaude GitHub](https://github.com/Gitlawb/openclaude)
- [ZAI CLI npm](https://libraries.io/npm/@guizmo-ai%2Fzai-cli)
