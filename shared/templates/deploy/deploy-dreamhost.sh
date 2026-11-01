#!/usr/bin/env bash
# ==============================================================================
# deploy-dreamhost.sh — Deploy incremental via rsync/SSH para DreamHost (shared)
# Uso: ./deploy-dreamhost.sh [--dry-run]
# Docs: docs/deploy-dreamhost.md
# ==============================================================================
set -euo pipefail

# --- CONFIGURAÇÃO (sobrescreva editando aqui ou via variáveis de ambiente) ----
REMOTE_USER="${REMOTE_USER:-seu_usuario}"
REMOTE_HOST="${REMOTE_HOST:-seu_servidor_ou_dominio.com}"
DOMAIN_FOLDER="${DOMAIN_FOLDER:-seu_dominio.com}"
LOCAL_PATH="${LOCAL_PATH:-./dist/}"
REMOTE_PATH="/home/${REMOTE_USER}/${DOMAIN_FOLDER}/"

# Modo padrão: autenticação interativa por senha.
# Para deploy sem senha, migre para chave SSH (uma vez):
#   ssh-keygen -t ed25519
#   ssh-copy-id -i ~/.ssh/id_ed25519.pub "${REMOTE_USER}@${REMOTE_HOST}"

# --- VALIDAÇÃO ----------------------------------------------------------------
if [ ! -d "$LOCAL_PATH" ]; then
    echo "Erro: diretório local '$LOCAL_PATH' não existe. Rode o build antes." >&2
    exit 1
fi
# Barra final garante transferência do CONTEÚDO de LOCAL_PATH, não a pasta.
case "$LOCAL_PATH" in */) ;; *) LOCAL_PATH="$LOCAL_PATH/" ;; esac

# --- DRY-RUN ($1 = --dry-run, ou DRY_RUN=1) -----------------------------------
DRY_RUN_FLAG=()
if [ "${1:-}" = "--dry-run" ] || [ "${DRY_RUN:-0}" = "1" ]; then
    DRY_RUN_FLAG=(--dry-run)
    echo "[DRY-RUN] Simulação: nenhum arquivo será alterado no destino."
fi

# --- RSYNC ---------------------------------------------------------------------
# -a: archive (recursivo, preserva permissões/links/timestamps)  -v: verbose
# -z: compressão em trânsito                                    -P: progresso
# --delete: remove do destino o que não existe mais na origem (cuidado!)
RSYNC_EXCLUDES=(
    --exclude=".git/"
    --exclude=".gitignore"
    --exclude=".env"
    --exclude=".env.*"
    --exclude="node_modules/"
    --exclude="*.log"
    --exclude=".DS_Store"
    --exclude="Thumbs.db"
    # Arquivos de configuração que pertencem ao servidor remoto:
    --exclude=".htaccess"
    --exclude=".well-known/"
)

echo "Deploy: $LOCAL_PATH -> ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"
rsync -avzP "${DRY_RUN_FLAG[@]}" \
    -e "ssh -o StrictHostKeyChecking=accept-new" \
    "${RSYNC_EXCLUDES[@]}" \
    "$LOCAL_PATH" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"

echo "Deploy concluído com sucesso."
