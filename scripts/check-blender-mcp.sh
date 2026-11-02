#!/usr/bin/env bash
# Health-check: WSL <-> 9Router <-> Blender MCP (Windows)
# Uso: ./scripts/check-blender-mcp.sh   (ROUTER_API_KEY opcional no ambiente)
set -e

RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m' BLUE=$'\033[0;34m' NC=$'\033[0m'

BLENDER_PORT=9876
ROUTER_HOST=127.0.0.1
ROUTER_PORT=20128
MCP_BIN=${MCP_BIN:-$HOME/.local/bin/mcp-for-blender}
FAIL=0

echo "${BLUE}=== Health-check: WSL <-> 9Router <-> Blender MCP ===${NC}"
echo

WINDOWS_HOST=$(ip route show default 2>/dev/null | awk '{print $3}')
[ -z "$WINDOWS_HOST" ] && WINDOWS_HOST=$(awk '/nameserver/{print $2; exit}' /etc/resolv.conf)
echo "IP do Windows (gateway): ${YELLOW}${WINDOWS_HOST:-nao detectado}${NC}"

# ---------------------------------------------------------------
# Blender MCP: nao basta a porta abrir - o add-on tem que responder
# e o protocolo tem que bater com o do servidor MCP.
# ---------------------------------------------------------------
echo -n "Blender MCP (${WINDOWS_HOST}:${BLENDER_PORT})... "
REPLY=$(python3 - "$WINDOWS_HOST" "$BLENDER_PORT" <<'PY' 2>/dev/null || true
import json, socket, sys
host, port = sys.argv[1], int(sys.argv[2])
try:
    s = socket.create_connection((host, port), 3); s.settimeout(25)
    s.sendall(json.dumps({"type": "get_addon_info", "params": {}}).encode() + b"\n")
    print(s.recv(65536).rstrip(b"\x00").decode(errors="replace"))
except Exception as e:
    print(f"ERRO {type(e).__name__}")
PY
)

if [[ "$REPLY" == *'"protocol_version"'* ]]; then
  ADDON_PROTO=$(sed -n 's/.*"protocol_version": *\([0-9]*\).*/\1/p' <<<"$REPLY" | head -1)
  echo "${GREEN}[OK] add-on respondeu (protocolo ${ADDON_PROTO})${NC}"
else
  FAIL=1
  echo "${RED}[FALHA]${NC} resposta: ${REPLY:-sem resposta}"
  cat <<'EOF'
  - Blender aberto com o add-on MCP habilitado (botao Start MCP Server)?
  - Edit > Preferences > System > Network > "Allow Online Access" marcado?
  - Add-on MCP: Host 0.0.0.0, Porta 9876, Auto Start?
  - "Client timed out" no lugar do protocolo = add-on velho ou thread principal travada (modal aberto)
  - Firewall (PowerShell admin):
    New-NetFirewallRule -DisplayName "Blender MCP Server (WSL)" -Direction Inbound -LocalPort 9876 -Protocol TCP -Action Allow
EOF
fi

SERVER_PROTO=$(grep -rh -m1 -oP 'EXPECTED_ADDON_PROTOCOL_VERSION = \K\d+' \
  "$(dirname "$(readlink -f "$MCP_BIN" 2>/dev/null || echo /dev/null)")"/../lib/python*/site-packages/blender_mcp/addon_manager.py 2>/dev/null | head -1)
if [ -n "$SERVER_PROTO" ] && [ -n "${ADDON_PROTO:-}" ]; then
  if [ "$SERVER_PROTO" = "$ADDON_PROTO" ]; then
    echo "Protocolo servidor ($MCP_BIN): ${GREEN}${SERVER_PROTO} == ${ADDON_PROTO} (add-on)${NC}"
  else
    FAIL=1
    echo "Protocolo servidor (${MCP_BIN}): ${RED}${SERVER_PROTO} != ${ADDON_PROTO} (add-on)${NC}"
    echo "  Atualize o servidor: uv tool install --force git+https://github.com/ahujasid/mcp-for-blender"
  fi
elif [ -z "$SERVER_PROTO" ]; then
  echo "Protocolo servidor: ${YELLOW}nao detectado em ${MCP_BIN}${NC}"
fi

# ---------------------------------------------------------------
# 9Router
# ---------------------------------------------------------------
echo -n "9Router TCP (${ROUTER_HOST}:${ROUTER_PORT})... "
if nc -z -w 2 "$ROUTER_HOST" "$ROUTER_PORT" 2>/dev/null; then
  echo "${GREEN}[OK]${NC}"
else
  FAIL=1
  echo "${RED}[FALHA] - 9Router Proxy nao esta rodando no WSL${NC}"
fi

echo -n "9Router HTTP /v1/models... "
AUTH=()
[ -n "$ROUTER_API_KEY" ] && AUTH=(-H "Authorization: Bearer $ROUTER_API_KEY")
STATUS=$(curl -s -o /dev/null -w '%{http_code}' "${AUTH[@]}" "http://${ROUTER_HOST}:${ROUTER_PORT}/v1/models" || true)
case "$STATUS" in
  200) echo "${GREEN}[OK]${NC}" ;;
  401|403) echo "${YELLOW}[porta viva, mas sem autenticacao - exporte ROUTER_API_KEY]${NC}" ;;
  *) FAIL=1; echo "${RED}[HTTP ${STATUS}]${NC}" ;;
esac

echo
if [ "$FAIL" = 0 ]; then
  echo "${BLUE}=== Tudo OK ===${NC}"
else
  echo "${BLUE}=== Verificacao concluida com falhas ===${NC}"
fi
exit "$FAIL"
