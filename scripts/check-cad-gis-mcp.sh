#!/usr/bin/env bash
# Health-check: WSL -> FreeCAD MCP (9875) e QGIS MCP bridge (9874) no Windows
# Uso: ./scripts/check-cad-gis-mcp.sh [caminho/opencode.jsonc do projeto]
#   Sem argumento: confere que o global NAO tem blender/freecad/qgis (por projeto).
#   Com argumento: confere tambem se aquele projeto declara e habilita os MCPs.
#   Tokens opcionais: FREECAD_MCP_TOKEN / QGIS_MCP_TOKEN
set -e

RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m' BLUE=$'\033[0;34m' NC=$'\033[0m'

FREECAD_PORT=${FREECAD_PORT:-9875}
QGIS_PORT=${QGIS_PORT:-9874}
OPENCODE_CFG=${OPENCODE_CFG:-$HOME/.config/opencode/opencode.json}
FAIL=0

echo -e "${BLUE}=== Health-check: WSL <-> CAD/GIS MCP (FreeCAD, QGIS) ===${NC}"
echo

WINDOWS_HOST=$(ip route show default 2>/dev/null | awk '{print $3}')
[ -z "$WINDOWS_HOST" ] && WINDOWS_HOST=$(awk '/nameserver/{print $2; exit}' /etc/resolv.conf)
echo "IP do Windows (gateway): ${YELLOW}${WINDOWS_HOST:-nao detectado}${NC}"

# ---------------------------------------------------------------
# FreeCAD: RPC e XML-RPC; get_rpc_status nao espera a thread da GUI,
# entao responde mesmo com o FreeCAD ocupado.
# ---------------------------------------------------------------
echo -n "FreeCAD MCP (${WINDOWS_HOST}:${FREECAD_PORT})... "
REPLY=$(python3 - "$WINDOWS_HOST" "$FREECAD_PORT" "${FREECAD_MCP_TOKEN:-}" <<'PY' 2>&1 || true
import sys, urllib.parse, xmlrpc.client

host, port, token = sys.argv[1], sys.argv[2], sys.argv[3]
auth = f":{urllib.parse.quote(token, safe='')}@" if token else ""

class TimeoutTransport(xmlrpc.client.Transport):
    # firewall do Windows derruba pacote em silencio: sem timeout o check trava ~2 min
    def make_connection(self, host):
        conn = super().make_connection(host)
        conn.timeout = 5
        return conn

try:
    proxy = xmlrpc.client.ServerProxy(f"http://{auth}{host}:{port}/RPC2",
                                      transport=TimeoutTransport(), allow_none=True)
    status = proxy.get_rpc_status()
    print(f"addon {status.get('addon_version')} / protocolo {status.get('protocol_version')}")
except xmlrpc.client.Fault as e:
    print(f"FAULT {e.faultString}")
except xmlrpc.client.ProtocolError as e:
    print(f"HTTP {e.errcode} {e.errmsg}")
except Exception as e:
    print(f"ERRO {type(e).__name__}: {e}")
PY
)

if [[ "$REPLY" == addon* ]]; then
  echo -e "${GREEN}[OK] ${REPLY}${NC}"
elif [[ "$REPLY" == HTTP\ 401* ]]; then
  echo -e "${YELLOW}[add-on vivo, mas exige token] ${REPLY}${NC}"
  echo "  - exporte FREECAD_MCP_TOKEN=<o token do menu Set Auth Token>"
elif [[ "$REPLY" == FAULT* ]]; then
  echo -e "${YELLOW}[add-on vivo, mas recusou a chamada] ${REPLY}${NC}"
else
  FAIL=1
  echo -e "${RED}[FALHA]${NC} ${REPLY}"
  cat <<'EOF'
  - FreeCAD aberto, workbench "MCP Addon", botao Start RPC Server clicado?
  - Remote Connections marcado E o IP do WSL na lista Configure Allowed IPs?
  - Firewall (PowerShell admin):
    New-NetFirewallRule -DisplayName "FreeCAD MCP (WSL)" -Direction Inbound -LocalPort 9875 -Protocol TCP -Action Allow
EOF
fi

# ---------------------------------------------------------------
# QGIS: porta aberta nao prova nada; o bridge tem que responder o ping.
# ---------------------------------------------------------------
echo -n "QGIS MCP bridge (${WINDOWS_HOST}:${QGIS_PORT})... "
REPLY=$(python3 - "$WINDOWS_HOST" "$QGIS_PORT" "${QGIS_MCP_TOKEN:-}" <<'PY' 2>&1 || true
import json, socket, sys
host, port, token = sys.argv[1], int(sys.argv[2]), sys.argv[3]
try:
    s = socket.create_connection((host, port), 5); s.settimeout(10)
    s.sendall(json.dumps({"op": "ping", "token": token}).encode() + b"\n")
    print(s.recv(65536).decode(errors="replace").strip())
except Exception as e:
    print(f"ERRO {type(e).__name__}: {e}")
PY
)

if [[ "$REPLY" == *'"ok": true'* || "$REPLY" == *'"ok":true'* ]]; then
  echo -e "${GREEN}[OK] ${REPLY}${NC}"
else
  FAIL=1
  echo -e "${RED}[FALHA]${NC} ${REPLY}"
  cat <<'EOF'
  - QGIS aberto e o bridge iniciado na Python Console (windows/cad-gis/qgis_mcp_bridge.py)?
  - O bridge tem que escutar em 0.0.0.0 (QGIS_MCP_HOST), nao em localhost.
  - Firewall (PowerShell admin):
    New-NetFirewallRule -DisplayName "QGIS MCP (WSL)" -Direction Inbound -LocalPort 9874 -Protocol TCP -Action Allow
EOF
fi

# ---------------------------------------------------------------
# Config do OpenCode
#   Blender/FreeCAD/QGIS NAO ficam no global: sao ativados por projeto.
#   - global: a ausencia dos tres e o estado correto
#   - projeto (opcional): passe o caminho do opencode.jsonc como $1
# ---------------------------------------------------------------
echo -n "uv/uvx (clientes MCP)... "
if command -v uvx >/dev/null && command -v uv >/dev/null; then echo "${GREEN}[OK]${NC}"; else FAIL=1; echo "${RED}[FALHA] - instale: curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"; fi

LEAKED=$(python3 - "$OPENCODE_CFG" <<'PY' 2>/dev/null || echo "erro-ao-ler"
import json, sys
cfg = json.load(open(sys.argv[1]))
present = [k for k in ("blender", "freecad", "qgis") if k in cfg.get("mcp", {})]
print(",".join(present))
PY
)
if [ "$LEAKED" = "erro-ao-ler" ]; then
  echo -n "config global legivel... "; FAIL=1; echo "${RED}[FALHA] ${OPENCODE_CFG}${NC}"
elif [ -z "$LEAKED" ]; then
  echo -n "config global limpa (blender/freecad/qgis fora do global)... "; echo "${GREEN}[OK]${NC}"
else
  echo -n "config global sem CAD/GIS/3D... "; FAIL=1
  echo -e "${RED}[VIOLADO] ainda tem: ${LEAKED}${NC}"
  echo "  - esses servidores sao por projeto: remova do global e use mcp-cad-gis-3d.jsonc"
fi

PROJECT_CFG=${1:-}
if [ -n "$PROJECT_CFG" ]; then
  echo -n "projeto ${PROJECT_CFG} declara os MCPs... "
  PROJECT_STATE=$(python3 - "$PROJECT_CFG" <<'PY' 2>&1 || true
import json, re, sys, pathlib
path = pathlib.Path(sys.argv[1]).expanduser()
text = path.read_text(encoding="utf-8")
text = re.sub(r"(^|[^:])\/\/.*$", r"\1", text, flags=re.M)  # JSONC -> JSON
mcp = json.loads(text).get("mcp", {})
found = {k: mcp[k].get("enabled", True) for k in ("blender", "freecad", "qgis") if k in mcp}
if not found:
    print("NENHUM")
else:
    print(", ".join(f"{k}={'on' if v else 'off'}" for k, v in found.items()))
PY
)
  case "$PROJECT_STATE" in
    NENHUM*) echo "${RED}[FALHA] - copie shared/templates/mcp/mcp-cad-gis-3d.jsonc${NC}"; FAIL=1 ;;
    *ERRO*) echo "${RED}[FALHA] ${PROJECT_STATE}${NC}"; FAIL=1 ;;
    *) echo "${GREEN}[OK] ${PROJECT_STATE}${NC}" ;;
  esac
else
  echo "  (dica: passe o opencode.jsonc de um projeto para conferir a ativacao local)"
fi

echo
if [ "$FAIL" = 0 ]; then
  echo -e "${BLUE}=== Tudo OK ===${NC}"
else
  echo -e "${BLUE}=== Verificacao concluida com falhas ===${NC}"
fi
exit "$FAIL"
