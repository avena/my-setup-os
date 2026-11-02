#!/usr/bin/env bash
# install-entire.sh - instala o Entire CLI (checkpoints de sessoes de agentes + brain)
#
# O Entire captura as sessoes dos coding agents e as vincula aos commits.
# Este script instala a CLI e o plugin brain. Login, enable e brain setup/connect
# continuam interativos (veja docs/entire.md).
#
# Uso:
#   bash linux/cli/install-entire.sh [opcoes] [REPO]
#
# Opcoes:
#   --skip-brain   nao instala o plugin brain
#   --force        reinstala a CLI mesmo se ja presente
#   --enable       roda 'entire enable -y' no REPO (padrao: diretorio atual)
#   -h, --help     mostra esta ajuda
#
# REPO: diretorio de um clone git onde rodar 'entire enable' (opcional).

set -euo pipefail

REPO=""
SKIP_BRAIN=0
FORCE=0
DO_ENABLE=0

usage() {
  sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-brain) SKIP_BRAIN=1; shift ;;
    --force)      FORCE=1; shift ;;
    --enable)     DO_ENABLE=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    --*)          echo "opcao desconhecida: $1" >&2; usage; exit 1 ;;
    *)            REPO="$1"; shift ;;
  esac
done

export PATH="$HOME/.local/bin:$PATH"
hash -r 2>/dev/null || true

if command -v entire >/dev/null 2>&1 && [[ "$FORCE" -eq 0 ]]; then
  echo "[OK] Entire CLI ja instalado: $(entire version 2>/dev/null | head -1)"
else
  echo ">> Baixando o instalador oficial (entire.com/install.sh) para inspecao..."
  TMP_INSTALL="$(mktemp)"
  trap 'rm -f "$TMP_INSTALL"' EXIT
  curl -fsSL https://entire.com/install.sh -o "$TMP_INSTALL"
  # AVISO SEGURANCA: instala via script oficial. Inspecione antes em ambiente sensivel.
  bash "$TMP_INSTALL"
  hash -r 2>/dev/null || true
  if ! command -v entire >/dev/null 2>&1; then
    echo "FAIL: entire nao encontrado no PATH apos a instalacao." >&2
    echo "Tente: source ~/.bashrc  (ou adicione ~/.local/bin ao PATH)" >&2
    exit 1
  fi
  echo "[OK] Entire CLI instalado: $(entire version 2>/dev/null | head -1)"
fi

if [[ "$SKIP_BRAIN" -eq 0 ]]; then
  if entire plugin list 2>/dev/null | grep -qE '^[[:space:]]*brain[[:space:]]'; then
    echo "[OK] Plugin brain ja instalado."
  else
    echo ">> Instalando plugin brain..."
    if entire plugin install brain; then
      echo "[OK] Plugin brain instalado."
    else
      echo "[WARN] Falha ao instalar o plugin brain. Rode depois: entire plugin install brain" >&2
    fi
  fi
else
  echo "[SKIP] Plugin brain nao instalado (--skip-brain)."
fi

if [[ "$DO_ENABLE" -eq 1 ]]; then
  TARGET="${REPO:-$PWD}"
  if [[ ! -d "$TARGET/.git" ]]; then
    echo "FAIL: '$TARGET' nao e um repositorio git. Rode 'entire enable' manualmente num clone." >&2
    exit 1
  fi
  echo ">> Habilitando checkpoints em $TARGET..."
  ( cd "$TARGET" && entire enable -y )
  echo "[OK] Entire habilitado em $TARGET."
fi

cat <<'EOF'

Proximos passos (interativos):
  1. Autentique a CLI:             entire login
  2. Clone um repo Entire:         entire repo clone /et/<projeto>/<repo>
     ou aponte um clone existente:
                                     entire repo remote add origin /et/<projeto>/<repo> --override
  3. Se ainda nao habilitou:       entire enable
  4. Construa o brain local:       entire brain setup
  5. Conecte ao brain hospedado:   entire brain connect

Detalhes: docs/entire.md
EOF
