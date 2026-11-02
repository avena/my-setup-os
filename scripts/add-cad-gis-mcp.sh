#!/usr/bin/env bash
# add-cad-gis-mcp.sh — ativa Blender/FreeCAD/QGIS (MCP) em UM projeto.
#
# Os tres saem da config global e viram por-projeto. Este script injeta o bloco
# de shared/templates/mcp/mcp-cad-gis-3d.jsonc no opencode.jsonc do projeto,
# trocando o IP do Windows pelo gateway atual do WSL e o caminho do cliente QGIS
# pelo caminho real deste repo.
#
# Uso:
#   ./scripts/add-cad-gis-mcp.sh [caminho/do/projeto]      (padrao: .)
#   ./scripts/add-cad-gis-mcp.sh --list                    lista projetos ja ativados
#
# O que ele NAO faz: ligar os servidores. Todos entram com "enabled": false;
# abra o app, suba o add-on e troque para true o que o projeto usa.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEMPLATE="$REPO_ROOT/shared/templates/mcp/mcp-cad-gis-3d.jsonc"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

[ -f "$TEMPLATE" ] || { echo "${RED}Template nao encontrado: $TEMPLATE${NC}" >&2; exit 1; }

if [ "${1:-}" = "--list" ]; then
  echo -e "${BLUE}Projetos com MCP de CAD/GIS/3D ativado:${NC}"
  found=0
  while IFS= read -r f; do
    grep -q '"blender"\|"freecad"\|"qgis"' "$f" 2>/dev/null || continue
    echo "  $f"
    found=1
  done < <(find "$HOME" -maxdepth 4 \( -name opencode.jsonc -o -name opencode.json \) \
             -not -path '*/.config/opencode/*' -not -path '*/node_modules/*' 2>/dev/null)
  [ "$found" = 0 ] && echo "  (nenhum)"
  exit 0
fi

PROJECT=${1:-.}
[ -d "$PROJECT" ] || { echo "${RED}Diretorio nao existe: $PROJECT${NC}" >&2; exit 1; }
PROJECT=$(cd "$PROJECT" && pwd)
TARGET="$PROJECT/opencode.jsonc"

# gateway do WSL == IP do Windows host; muda quando o Windows reinicia
WINDOWS_HOST=${WINDOWS_HOST:-$(ip route show default 2>/dev/null | awk '{print $3; exit}')}
if [ -z "$WINDOWS_HOST" ]; then
  echo -e "${YELLOW}Aviso: nao achei o gateway do WSL. Use WINDOWS_HOST=172.x.x.x $0 $PROJECT${NC}" >&2
  WINDOWS_HOST=172.22.112.1
fi

if [ ! -f "$TARGET" ]; then
  sed "s|172\.22\.112\.1|${WINDOWS_HOST}|g; s|/home/livre/my-setup-os|${REPO_ROOT}|g" \
      "$TEMPLATE" > "$TARGET"
  echo -e "${GREEN}[criado]${NC} $TARGET"
  echo "  IP do Windows: ${WINDOWS_HOST}  ·  repo: ${REPO_ROOT}"
else
  BACKUP="${TARGET}.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$TARGET" "$BACKUP"
  python3 - "$TEMPLATE" "$TARGET" "$WINDOWS_HOST" "$REPO_ROOT" <<'PY'
import json, re, sys

template, target, host, repo = sys.argv[1:5]

def parse_jsonc(text):
    # remove // e /* */ sem tocar em strings
    out, i, n = [], 0, len(text)
    in_str = esc = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == '"': in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True; out.append(c); i += 1; continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n": i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"): i += 1
            i += 2
            continue
        out.append(c); i += 1
    return json.loads("".join(out))

new_mcp = parse_jsonc(open(template, encoding="utf-8").read())["mcp"]
for entry in new_mcp.values():
    entry["command"] = [c.replace("172.22.112.1", host).replace("/home/livre/my-setup-os", repo)
                        for c in entry["command"]]

cfg = parse_jsonc(open(target, encoding="utf-8").read())
mcp = cfg.setdefault("mcp", {})
added = [k for k in new_mcp if k not in mcp]
skipped = [k for k in new_mcp if k in mcp]
for k in added:
    mcp[k] = new_mcp[k]

with open(target, "w", encoding="utf-8") as fh:
    json.dump(cfg, fh, indent=2, ensure_ascii=False)
    fh.write("\n")

print(f"[merge] adicionados: {', '.join(added) or '(nenhum)'}")
if skipped:
    print(f"[merge] mantidos como estavam: {', '.join(skipped)}")
PY
  echo -e "${GREEN}[atualizado]${NC} $TARGET  (backup: $(basename "$BACKUP"))"
fi

echo
echo -e "${BLUE}Proximos passos${NC}"
echo "  1. Abra o app no Windows e suba o add-on (0.0.0.0):"
echo "       Blender  -> painel N > MCP Blender > Start MCP Server   (porta 9876)"
echo "       FreeCAD  -> workbench MCP > Start RPC server            (porta 9875)"
echo "       QGIS     -> Plugins > Python Console > exec(open(...qgis_mcp_bridge.py).read())  (9874)"
echo "  2. Edite $TARGET e troque \"enabled\": false -> true so no que for usar."
echo "  3. Confira:  ./scripts/check-cad-gis-mcp.sh \"$TARGET\""
