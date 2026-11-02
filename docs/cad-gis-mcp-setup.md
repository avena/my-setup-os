# CAD & GIS MCP — OpenCode (WSL) → FreeCAD / QGIS (Windows)

Mesmo padrão do [Blender MCP](blender-mcp-setup.md): OpenCode roda no WSL, o app roda no Windows,
e a ponte é TCP pela interface virtual do WSL. A diferença é o tipo de trabalho:

| App | Kernel | Serve para |
|---|---|---|
| **Blender** | malha poligonal | animação, vista explodida, render PBR, catálogo visual |
| **FreeCAD** | B-Rep / Open CASCADE | peça real, tolerância, chapa dobrada, STEP/IGES, DXF, FEM |
| **QGIS** | vetor/raster geoespacial | talhão, APP, MDT, NDVI, layout de mapa, plugin PyQGIS |

## Arquitetura

```text
        WSL (Ubuntu)                                  Windows host (172.22.112.1)
┌────────────────────────────────────────┐   ┌────────────────────────────────────┐
│ opencode (agente)                      │   │ FreeCAD 1.x                        │
│   ├─> uvx freecad-mcp ──── XML-RPC ────┼──>│  addon FreeCADMCP  0.0.0.0:9875    │
│   │                                    │   │                                    │
│   └─> python3 qgis_mcp_server.py ──────┼──>│ QGIS 3.4x                          │
│              (stdio MCP)    TCP/JSON   │   │  qgis_mcp_bridge.py 0.0.0.0:9874   │
└────────────────────────────────────────┘   └────────────────────────────────────┘
```

- Os dois addons **precisam** escutar em `0.0.0.0`. Em `localhost` o Windows descarta o pacote
  que chega pela interface do WSL.
- O IP do Windows é o gateway do WSL e **muda a cada reboot**:
  `ip route show default | awk '{print $3}'`.
- Ambos executam código arbitrário no host (`execute_code` / `qgis_execute`). Sem token, qualquer
  processo na sub-rede do WSL pode controlar o app — use `Set Auth Token` (FreeCAD) e
  `QGIS_MCP_TOKEN` quando não estiver sozinho na máquina.

## 0. Estado desta máquina (01/11/2026)

| Item | Situação | Onde |
|---|---|---|
| Blender 5.2.3 | instalado, MCP validado | `C:\Program Files\Blender Foundation\Blender 5.2\` |
| FreeCAD | **não instalado** | instalar antes do passo 1 |
| QGIS | **instalação quebrada** | `C:\Program Files\QGIS 3.44.10\` tem só 3 arquivos-stub; 3.40.14 / 3.44.8 / 3.44.9 estão vazios |
| Perfil QGIS | existe (usado em jan/2026) | `C:\Users\randomacesso\AppData\Roaming\QGIS\QGIS3\` |
| `opencode.json` global | **limpo**: `blender`/`freecad`/`qgis` removidos de propósito (são por projeto) | `~/.config/opencode/opencode.json` |
| Perfil por projeto | `mcp-cad-gis-3d.jsonc` + `scripts/add-cad-gis-mcp.sh` | `shared/templates/mcp/` |
| Gateway WSL | `172.22.112.1` | muda no reboot |

O perfil do QGIS sobrevive à reinstalação, então nada de projeto/plugin se perde ao reinstalar.

## 1. FreeCAD (Windows)

### 1.1 Instalar

```powershell
scoop bucket add extras; scoop install freecad      # ou: winget install FreeCAD.FreeCAD
```

### 1.2 Add-on

```bash
git clone https://github.com/neka-nat/freecad-mcp.git /tmp/freecad-mcp
mkdir -p "/mnt/c/Users/randomacesso/AppData/Roaming/FreeCAD/v1-1/Mod"
cp -r /tmp/freecad-mcp/addon/FreeCADMCP "/mnt/c/Users/randomacesso/AppData/Roaming/FreeCAD/v1-1/Mod/"
```

O resultado tem que ser `...\Mod\FreeCADMCP\InitGui.py` — **sem** um segundo nível `FreeCADMCP`.
Se a workbench não aparecer, veja `View → Panels → Report view` (erro de import do addon).
Versões antigas (sem pasta versionada) usam `%APPDATA%\FreeCAD\Mod\`.

### 1.3 Servidor RPC

1. Abrir o FreeCAD → workbench **MCP Addon**.
2. Menu **FreeCAD MCP**: marcar **Remote Connections**.
3. **Configure Allowed IPs** → `172.22.0.0/16` (ou o IP do WSL).
4. **Set Auth Token** → `python3 -c "import secrets; print(secrets.token_urlsafe(32))"`.
5. **Start RPC Server** (porta 9875). Opcional: **Auto-Start Server**.

### 1.4 Firewall

```powershell
powershell -ExecutionPolicy Bypass -File windows\cad-gis\Allow-CadMcpFirewall.ps1
```

## 2. QGIS (Windows)

### 2.1 Instalar (a instalação atual está quebrada)

```powershell
winget install OSGeo.QGIS        # ou o instalador MSI de qgis.org
```

Alternativa sem GUI, direto no WSL (bom para processamento em lote, ruim para ver o mapa):

```bash
sudo apt-get install -y qgis python3-qgis
```

### 2.2 Bridge

O QGIS não tem MCP maduro. O bridge é um socket de ~150 linhas, sem dependências:
[`windows/cad-gis/qgis_mcp_bridge.py`](../windows/cad-gis/qgis_mcp_bridge.py).

**Por sessão** — QGIS → `Plugins → Python Console`, e:

```python
# direto do repo no WSL (a distro precisa estar rodando)
exec(open(r"\\wsl.localhost\Ubuntu-24.04DockerPHP\home\livre\my-setup-os\windows\cad-gis\qgis_mcp_bridge.py", encoding="utf-8").read())
```

Cópia local no Windows (mais estável, sobrevive a `wsl --shutdown`):

```bash
mkdir -p /mnt/c/Users/randomacesso/my-setup-os/cad-gis
cp /home/livre/my-setup-os/windows/cad-gis/qgis_mcp_bridge.py /mnt/c/Users/randomacesso/my-setup-os/cad-gis/
# no console do QGIS:
# exec(open(r"C:\Users\randomacesso\my-setup-os\cad-gis\qgis_mcp_bridge.py", encoding="utf-8").read())
```

**Permanente** — criar atalho para `qgis-bin.exe --code C:\...\qgis_mcp_bridge.py`.

Token (opcional, recomendado): definir `QGIS_MCP_TOKEN` como variável de ambiente do usuário
**antes** de abrir o QGIS (`setx QGIS_MCP_TOKEN "..."`).

### 2.3 Firewall

Já coberto pelo `Allow-CadMcpFirewall.ps1` (porta 9874).

## 3. OpenCode (WSL) — Blender, FreeCAD e QGIS são **por projeto**

Nada disso vai em `~/.config/opencode/opencode.json`. Cada MCP abre um processo local, disputa
uma porta fixa e, sem o app aberto, segura o boot com timeout de conexão — inútil em projeto de
site, API ou dados. O global fica limpo de propósito.

### Implementação neste repositório

| Arquivo | Papel |
|---|---|
| `shared/templates/mcp/mcp-cad-gis-3d.jsonc` | Perfil de projeto com os três MCPs (`enabled: false`, IP e caminhos documentados) |
| `scripts/add-cad-gis-mcp.sh` | Injeta o perfil no `opencode.jsonc` de um projeto, trocando o IP do WSL pelo gateway atual |
| `scripts/qgis_mcp_server.py` | Cliente MCP (stdio) do QGIS |
| `windows/cad-gis/qgis_mcp_bridge.py` | Servidor socket dentro do QGIS |
| `windows/cad-gis/Allow-CadMcpFirewall.ps1` | Libera 9874/9875/9876 no firewall |
| `scripts/check-cad-gis-mcp.sh` | Health-check: gateway, XML-RPC do FreeCAD, bridge do QGIS e a política global/projeto |
| `shared/setup-mcps.sh` | Perfis de MCP — `cad-gis-3d` é recusado na config global |

### Ativar em um projeto

```bash
./scripts/add-cad-gis-mcp.sh ~/projetos/plantadeira      # cria/merge do opencode.jsonc do projeto
$EDITOR ~/projetos/plantadeira/opencode.jsonc            # "enabled": false -> true só no que usar
```

Equivalente manual — copiar este bloco para o `opencode.jsonc` do projeto, dentro de `"mcp"`:

```json
"freecad": {
  "type": "local",
  "command": ["uvx", "freecad-mcp", "--host", "172.22.112.1"],
  "environment": { "FREECAD_MCP_TOKEN": "env:FREECAD_MCP_TOKEN" },
  "enabled": true,
  "timeout": 120000
},
"qgis": {
  "type": "local",
  "command": ["uv", "run", "--quiet", "--with", "mcp[cli]<2", "python3",
              "/home/livre/my-setup-os/scripts/qgis_mcp_server.py"],
  "environment": { "QGIS_MCP_TOKEN": "env:QGIS_MCP_TOKEN" },
  "enabled": true,
  "timeout": 120000
}
```

- `freecad-mcp` vem do PyPI (v0.1.28, requer Python ≥ 3.12 — o `uvx` resolve sozinho).
  **Não existe `--port`**: a porta do addon é fixa em 9875, só `--host` é configurável.
- O cliente do QGIS **descobre o gateway sozinho**; `--host` só se quiser fixar.
- `mcp[cli]<2` é obrigatório: o SDK 2.x renomeou `FastMCP` → `MCPServer` e quebra o import.
- `timeout` alto porque modelagem paramétrica e `processing.run` passam de 30 s fácil.
- `--only-text-feedback` no FreeCAD economiza tokens (desliga screenshots automáticos);
  use `get_view` quando quiser olhar a peça.
- O `opencode.jsonc` do projeto faz merge com o global: não repita Playwright, Qdrant etc.
- O perfil completo (com o Blender) está em `shared/templates/mcp/mcp-cad-gis-3d.jsonc`;
  também dá para aplicar por perfil: `./shared/setup-mcps.sh apply cad-gis-3d ./opencode.jsonc`.

## 4. Verificação

```bash
./scripts/check-cad-gis-mcp.sh                                     # só a política global + apps
./scripts/check-cad-gis-mcp.sh ~/projetos/x/opencode.jsonc          # + ativação naquele projeto
```

Checa: gateway, `get_rpc_status` do FreeCAD (XML-RPC real, não só porta aberta), `ping` do
bridge do QGIS, `uv`/`uvx`, que o **global está limpo** dos três, e (se passar um caminho) quais
estão ligados no projeto. Sem argumento, exit 1 = algum app morto ou o global violado.

```text
IP do Windows (gateway): 172.22.112.1
FreeCAD MCP (172.22.112.1:9875)... [OK] addon 0.1.28 / protocolo 3
QGIS MCP bridge (172.22.112.1:9874)... [OK] {"ok": true, "qgis": "3.44.10", "port": 9874}
uv/uvx (clientes MCP)... [OK]
config global limpa (blender/freecad/qgis fora do global)... [OK]
projeto /tmp/proj-test/opencode.jsonc declara os MCPs... [OK] blender=off, freecad=off, qgis=off
=== Tudo OK ===
```

`nc -z` na porta **não** prova nada: o socket aceita conexão mesmo com o app travado.

Listar todos os projetos que já têm o perfil ativado:

```bash
./scripts/add-cad-gis-mcp.sh --list
```

## 5. O que pedir ao agente

**Peça mecânica (FreeCAD, B-Rep):**

```text
Modele a chapa guia da plantadeira: Sketch no plano XZ com perfil U de 40 mm de largura,
abas de 12 mm, chapa 1.8 mm, Pad de 750 mm; no extremo inferior, bico em cunha afunilando
para 15 mm. Furo passante Ø8.5 a 240 mm da ponta. Tire get_view isométrico e exporte STEP.
```

**Casa / construção (FreeCAD + Blender):**

```text
Gere o volume construído em FreeCAD: paredes em PartDesign com 2.5 m de pé-direito a partir
do footprint do talhão, aberturas de porta/janela como Pocket. Depois importe o STEP no
Blender e faça a vista explodida animada para o cliente.
```

**Mapa e geoprocessamento (QGIS):**

```text
Liste as camadas do projeto. Calcule a área em hectares do talhão ativo e grave em
"area_ha". Gere buffer de 30 m na hidrografia (APP), aplique contorno vermelho
transparente, e renderize o mapa em PNG 2000 px para eu conferir.
```

**Plugin de geoprocessamento (QGIS + código):**

```text
Crie um plugin Processing "Fertilidade por Zona" em ~/projetos/qgis-fertilidade:
algoritmo que recebe raster de NDVI e vetor de talhões, faz zonal statistics, classifica
em 3 classes e devolve GeoPackage. Gere metadata.txt, __init__.py e o algoritmo, e rode
qgis_execute para validar via processing.run.
```

## 6. Troubleshooting

| Sintoma | Causa | Correção |
|---|---|---|
| `check` mostra `ERRO ConnectionRefusedError` no FreeCAD | RPC não iniciado | Start RPC Server no workbench MCP Addon |
| `check` mostra `Connection timed out` | addon em `localhost` ou firewall | marcar **Remote Connections** + `Allow-CadMcpFirewall.ps1` |
| `HTTP 401` | token ativo | exportar `FREECAD_MCP_TOKEN` |
| FreeCAD responde mas `create_object` trava | diálogo modal aberto no FreeCAD | fechar o modal; `execute_code_async` para jobs longos |
| QGIS: `ERRO ConnectionRefusedError` | bridge não iniciado nesta sessão | rodar o `exec(open(...))` na Python Console |
| QGIS: `TimeoutError: thread principal ocupada` | diálogo modal no QGIS | fechar o diálogo |
| `qgis_execute` não vê a variável `result` | `result` é por execução | usar `print(...)` ou atribuir `result = ...` |
| Tudo quebrou depois de reiniciar o Windows | gateway mudou | `./scripts/check-cad-gis-mcp.sh` mostra o IP novo; atualizar `--host` do freecad |
| Workbench MCP não aparece no FreeCAD | cópia aninhada `Mod/FreeCADMCP/FreeCADMCP` | garantir `Mod/FreeCADMCP/InitGui.py` |

Referências: [mcp-catalog.md](mcp-catalog.md) · [blender-mcp-setup.md](blender-mcp-setup.md) ·
[neka-nat/freecad-mcp](https://github.com/neka-nat/freecad-mcp)
