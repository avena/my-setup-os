# Top CLIs Installer

Script para instalar e gerenciar **26 CLIs de IA/Coding** no Linux/WSL.

## Arquivo

| Arquivo | Descrição |
|---|---|
| `top-clis.sh` | Catálogo interativo — escaneia, instala e gerencia 26 CLIs |
| `install-entire.sh` | Instala o Entire CLI + plugin brain (checkpoints de sessões de agentes) |
| `install-qdrant-mcp.sh` | Registra o MCP `qdrant` (busca semântica via 9Router) no OpenCode |

## Uso

```bash
bash linux/cli/top-clis.sh
```

## Funcionalidades

- **scan** — lista os 26 CLIs e mostra quais estão instalados com versão
- **instalação individual** — escolha por número (ex: `3,4,20`)
- **todos** — instala todos os CLIs faltantes em lote
- **sair** — encerra o script

## CLIs Incluídos (TOP 26)

| # | CLI | Binário | Dep | Tipo |
|---|---|---|---|---|
| 1 | Claude Code | claude-code | npm | oficial |
| 2 | Kilo Code | kilo | curl | oficial |
| 3 | Aider | aider | pip3 | oficial |
| 4 | Gemini CLI | gemini | npm | oficial |
| 5 | Codex CLI | codex | npm | oficial |
| 6 | OpenCode | opencode | curl | oficial |
| 7 | Qwen Code | qwen | npm | oficial |
| 8 | Crush CLI | crush | apt | oficial |
| 9 | Plandex | plandex | curl | oficial |
| 10 | Goose | goose | curl | oficial |
| 11 | Amazon Q CLI | amazon-q-cli | pip3 | oficial |
| 12 | Vibe CLI | vibe-cli | npm | oficial |
| 13 | Cline | cline | npm | oficial |
| 14 | Bolt CLI | bolt-new | npm | oficial |
| 15 | PyGPT | pygpt | pip3 | oficial |
| 16 | AIChat | aichat | npm | oficial |
| 17 | Droid | droid-cli | cargo | oficial |
| 18 | Replit Agent | replit | npm | oficial |
| 19 | Tabby CLI | tabby | docker | oficial |
| 20 | Kimi Code | kimi | curl | oficial |
| 21 | Roo Code | roo-cline | npm | oficial |
| 22 | OpenClaw | openclaw | curl | oficial |
| 23 | nanocode | nanocode | pip3 | oficial |
| 24 | OpenClaude | openclaude | npm | **comunitário** |
| 25 | ZAI CLI | zai | npm | **comunitário** |
| 26 | Top100CLIs | top100clis | curl | **comunitário** |

## Notas Pós-Instalação

- **Kimi Code (#20)**: Execute `kimi` e depois `/login` para autenticar
- **OpenClaude (#24)**: Comunitário — configure provider com `/provider`. Ripgrep (`rg`) recomendado
- **ZAI CLI (#25)**: Comunitário — requer API key em `~/.zai/user-settings.json`
- **Top100CLIs (#26)**: Comunitário — ferramenta de listagem

## Dependências

O script instala automaticamente:
- **Node.js/npm** (via nodesource)
- **Python3/pip3** (via apt)
- **Rust/Cargo** (via rustup)
- **Docker** (via get.docker.com)
- **curl** (via apt)

## Entire CLI (`install-entire.sh`)

Instala o [Entire](https://entire.com) — checkpoints das sessões dos coding agents + brain por
repositório. Instala a CLI oficial e o plugin `brain`; login, `enable` e `brain setup/connect`
continuam interativos.

```bash
bash linux/cli/install-entire.sh            # CLI + plugin brain
bash linux/cli/install-entire.sh --skip-brain
bash linux/cli/install-entire.sh --enable   # roda 'entire enable -y' no diretório atual
```

Guia completo: [docs/entire.md](../../docs/entire.md).

## Documentação Completa

Veja [docs/top-clis.md](../../docs/top-clis.md) para documentação detalhada.
