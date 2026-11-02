# Blender MCP — OpenCode (WSL) → Blender (Windows)

Integração validada em produção: OpenCode rodando no WSL Ubuntu controlando o Blender 5.2 no Windows via MCP, com os modelos servidos pelo 9Router Proxy local.

## Arquitetura

```text
        WSL (Ubuntu)                                    Windows host (172.22.112.1)
┌──────────────────────────────────────────────┐   ┌──────────────────────────────────┐
│ opencode (agente)                            │   │ Blender 5.2                      │
│   │                                          │   │  add-on MCP Blender v1.8         │
│   ├─> 9Router 127.0.0.1:20128/v1 ──> OpenRouter│  │  host=0.0.0.0  port=9876         │
│   │                                          │   │  (painel N > MCP Blender)        │
│   └─> ~/.local/bin/mcp-for-blender (stdio)   │   │                                  │
│            │                                 │   │                                  │
│            └── TCP 9876 ─────────────────────┼──>│  socket server                   │
└──────────────────────────────────────────────┘   └──────────────────────────────────┘
```

- O OpenCode fala MCP por **stdio** com `mcp-for-blender`; esse processo é quem abre a conexão TCP/JSON-RPC com o add-on dentro do Blender.
- Do WSL, o Windows é o gateway padrão: `ip route show default | awk '{print $3}'` → `172.22.112.1` (muda se o Windows reiniciar).
- O add-on **precisa** escutar em `0.0.0.0`: com `localhost` o Windows descarta o pacote que chega pela interface virtual do WSL.

## 1. Windows (Blender 5.2)

### Add-on

- Usar o **MCP for Blender v1.8** (Siddharth Ahuja):
  `%APPDATA%\Blender Foundation\Blender\5.2\scripts\addons\blender_mcp.py`
  (do WSL: `/mnt/c/Users/<user>/AppData/Roaming/Blender Foundation/Blender/5.2/scripts/addons/blender_mcp.py`)
- **Desabilitar a extensão oficial da Blender Lab** (`MCP` 1.0.3): ela disputa a porta 9876 e não implementa o handshake `get_addon_info`.

### Patch de rede (bind)

O script define `host='localhost'` na classe `BlenderMCPServer` (~linha 1222). Trocar para:

```python
host = '0.0.0.0'
```

Sem esse patch o `nc` do WSL retorna `Connection timed out`.

### Preferências e firewall

1. `Edit > Preferences > System > Network` → marcar **Allow Online Access** (trava de segurança do Blender; sem isso o add-on não abre socket).
2. Firewall (PowerShell como Administrador):

```powershell
New-NetFirewallRule -DisplayName "Blender MCP Server (WSL)" -Direction Inbound -LocalPort 9876 -Protocol TCP -Action Allow
```

3. Iniciar o servidor: viewport 3D → `N` → aba **MCP Blender** → `Start MCP Server` (deve exibir `Connected on port 9876`).

## 2. WSL (OpenCode)

### Servidor MCP

**Não use `uvx blender-mcp` / PyPI**: o pacote publicado está defasado (`EXPECTED_ADDON_PROTOCOL_VERSION = 7`) e o add-on atual fala 15 — o handshake morre com `Incomplete JSON response received`.

```bash
uv tool install --force "git+https://github.com/ahujasid/mcp-for-blender"
# binário: ~/.local/bin/mcp-for-blender
```

### `opencode.jsonc` **do projeto** (o Blender não vai no global)

O Blender fica **fora** de `~/.config/opencode/opencode.json`: é servidor de projeto, ativado só
onde faz 3D. Sem o add-on rodando, o handshake segura o boot com timeout.

```bash
./scripts/add-cad-gis-mcp.sh ~/projetos/meu-projeto    # injeta blender+freecad+qgis, enabled=false
```

Ou copie o bloco de [`shared/templates/mcp/mcp-cad-gis-3d.jsonc`](../shared/templates/mcp/mcp-cad-gis-3d.jsonc)
para o `opencode.jsonc` do projeto. O schema do OpenCode usa `"mcp"` com `command` em **array**
(não é o `"mcpServers"` do Claude Desktop):

```json
"blender": {
  "type": "local",
  "command": ["/home/livre/.local/bin/mcp-for-blender", "--host", "172.22.112.1", "--port", "9876"],
  "enabled": false,
  "timeout": 30000
}
```

> **Desativado por padrão** (`"enabled": false`): troque para `true` só no projeto que vai modelar,
> com o add-on já em `Start MCP Server`. O `opencode.jsonc` do projeto faz merge com o global, então
> não repita os MCPs gerais ali.

> **IP hardcoded:** o gateway do WSL muda quando o Windows reinicia. Se cair após reboot, rode
> `ip route show default | awk '{print $3}'` e atualize `--host` (o `add-cad-gis-mcp.sh` já faz isso).

## 3. Verificação

```bash
./scripts/check-blender-mcp.sh          # exit 0 = tudo ok
```

O script detecta o IP, faz o handshake real `get_addon_info`, compara o `protocol_version` do add-on com o `EXPECTED_ADDON_PROTOCOL_VERSION` do binário, e testa TCP + HTTP do 9Router (use `ROUTER_API_KEY=... ` para validar autenticação).

```text
Blender MCP (172.22.112.1:9876)... [OK] add-on respondeu (protocolo 15)
Protocolo servidor (/home/livre/.local/bin/mcp-for-blender): 15 == 15 (add-on)
9Router TCP (127.0.0.1:20128)... [OK]
9Router HTTP /v1/models... [OK]
=== Tudo OK ===
```

`nc -z` na 9876 **não** prova nada: a porta aceita conexão mesmo com o add-on travado. O teste válido é o comando JSON acima.

## 4. Troubleshooting (casos reais)

| Sintoma | Causa | Correção |
|---|---|---|
| `Request timed out` no OpenCode / `Incomplete JSON response received` | Mismatch de protocolo: add-on 15 vs `mcp-for-blender` do PyPI (7) | `uv tool install --force git+https://github.com/ahujasid/mcp-for-blender` |
| `Connection timed out` no `nc` | `host='localhost'` no `blender_mcp.py` ou regra de firewall ausente | Patch para `0.0.0.0` + `New-NetFirewallRule` |
| `Online access must be enabled` | Trava em `Preferences > System > Network` | Marcar **Allow Online Access** |
| Porta 9876 fechada | Extensão oficial da Blender Lab habilitada (ou add-on sem `Start MCP Server`) | Desabilitar a oficial, habilitar o add-on v1.8 e clicar em Start |
| `{"status":"error","message":"Client timed out"}` no socket | Add-on velho ou thread principal do Blender bloqueada (modal aberto) | Atualizar add-on; fechar modal, `ESC`, reiniciar o add-on |
| `get_addon_status` → `No module named 'blender_mcp.config'` | Add-on instalado como arquivo único (não como pacote) | Cosmético: as demais tools funcionam; ignore ou instale o add-on como pacote |

## 5. Exemplos de uso no chat

```text
Liste as malhas da cena atual.
```

```text
Crie uma Suzanne em (0,0,2), aplique material azul e renderize em 1280x720.
```

```text
Renomeie os data-blocks de luzes seguindo a convenção LGT-nome.
```

```text
Analise a cena e liste os objetos com mais polígonos que estejam fora do enquadramento da câmera.
```

Referências: [docs/mcp-catalog.md](mcp-catalog.md) · [windows/README.md](../windows/README.md)
