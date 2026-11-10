#!/usr/bin/env bash
# install-qdrant-mcp.sh - registra o MCP "qdrant" no OpenCode
#
# O servidor (shared/mcp/qdrant/mcp-server.py) expõe 3 tools:
#   qdrant-store  - indexa trecho/memória (embedding via 9Router)
#   qdrant-find   - busca semântica
#   qdrant-info   - pontos/dimensão da collection
#
# As credenciais vêm de ~/.config/opencode/.env.mcp (veja
# shared/mcp/qdrant/.env.example). O script é idempotente: reescreve a
# entrada "qdrant" e faz backup do opencode.json antes.
#
# Uso:
#   bash linux/cli/install-qdrant-mcp.sh
#   OPENCODE_CONFIG=./opencode.json bash linux/cli/install-qdrant-mcp.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVER="$REPO_DIR/shared/mcp/qdrant/mcp-server.py"
CONFIG="${OPENCODE_CONFIG:-$HOME/.config/opencode/opencode.json}"
ENV_FILE="${OPENCODE_ENV_FILE:-$HOME/.config/opencode/.env.mcp}"

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'

die() { echo -e "${RED}[ERRO] $*${NC}" >&2; exit 1; }

command -v uv >/dev/null 2>&1 || die "uv não encontrado (instale: curl -LsSf https://astral.sh/uv/install.sh | sh)"
command -v python3 >/dev/null 2>&1 || die "python3 não encontrado"
[ -f "$SERVER" ] || die "servidor não encontrado: $SERVER"
[ -f "$CONFIG" ] || die "config do OpenCode não encontrada: $CONFIG"
[ -f "$ENV_FILE" ] || die "arquivo de env não encontrado: $ENV_FILE (veja shared/mcp/qdrant/.env.example)"

# Última ocorrência vence; ignora comentários.
getenv() { grep -E "^[[:space:]]*$1=" "$ENV_FILE" | tail -1 | cut -d= -f2- | sed 's/[[:space:]]*$//'; }

QDRANT_URL="$(getenv QDRANT_URL)"
[ -n "$QDRANT_URL" ] || die "QDRANT_URL ausente em $ENV_FILE"
QDRANT_API_KEY="$(getenv QDRANT_API_KEY)"
ROUTER_BASE_URL="$(getenv ROUTER_BASE_URL)"; ROUTER_BASE_URL="${ROUTER_BASE_URL:-http://127.0.0.1:20128/v1}"
ROUTER_API_KEY="$(getenv ROUTER_API_KEY)"
[ -n "$ROUTER_API_KEY" ] || die "ROUTER_API_KEY ausente em $ENV_FILE"
ROUTER_EMBEDDING_MODEL="$(getenv ROUTER_EMBEDDING_MODEL)"; ROUTER_EMBEDDING_MODEL="${ROUTER_EMBEDDING_MODEL:-gemini/gemini-embedding-001}"
EMBEDDING_DIMS="$(getenv EMBEDDING_DIMS)"; EMBEDDING_DIMS="${EMBEDDING_DIMS:-3072}"
QDRANT_COLLECTION="$(getenv QDRANT_COLLECTION)"; QDRANT_COLLECTION="${QDRANT_COLLECTION:-codebase}"

BACKUP="$CONFIG.bak.$(date +%Y%m%d%H%M%S)"
cp "$CONFIG" "$BACKUP"

QDRANT_URL="$QDRANT_URL" QDRANT_API_KEY="$QDRANT_API_KEY" \
ROUTER_BASE_URL="$ROUTER_BASE_URL" ROUTER_API_KEY="$ROUTER_API_KEY" \
ROUTER_EMBEDDING_MODEL="$ROUTER_EMBEDDING_MODEL" EMBEDDING_DIMS="$EMBEDDING_DIMS" \
QDRANT_COLLECTION="$QDRANT_COLLECTION" SERVER="$SERVER" CONFIG="$CONFIG" \
python3 - <<'PY'
import json, os

path = os.environ["CONFIG"]
with open(path) as f:
    cfg = json.load(f)

cfg.setdefault("mcp", {})["qdrant"] = {
    "type": "local",
    "command": ["uv", "run", "--with", "openai", "--with", "qdrant-client",
                "python3", os.environ["SERVER"]],
    "environment": {
        "OPENAI_API_KEY": os.environ["ROUTER_API_KEY"],
        "OPENAI_BASE_URL": os.environ["ROUTER_BASE_URL"],
        "OPENAI_EMBEDDING_MODEL": os.environ["ROUTER_EMBEDDING_MODEL"],
        "QDRANT_URL": os.environ["QDRANT_URL"],
        "QDRANT_API_KEY": os.environ["QDRANT_API_KEY"],
        "COLLECTION_NAME": os.environ["QDRANT_COLLECTION"],
        "EMBEDDING_DIMS": os.environ["EMBEDDING_DIMS"],
    },
    "enabled": True,
    "timeout": 30000,
}

with open(path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

echo -e "${GREEN}[OK] MCP 'qdrant' registrado em $CONFIG${NC}"
echo "     backup: $BACKUP"
echo -e "${YELLOW}Reinicie o OpenCode e teste com qdrant-info.${NC}"
