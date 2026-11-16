#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="${SCRIPT_DIR}/logs"
mkdir -p "${LOGS_DIR}"
LOG_FILE="${LOGS_DIR}/setup-$(date +'%Y%m%d-%H%M%S').log"

# Redireciona stdout e stderr simultaneamente para terminal e arquivo de log
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== [Mission Control] Setup e Inicializacao de Containers ==="
echo "Log: ${LOG_FILE}"

# 1. Detecta runtime de container (docker ou finch)
CONTAINER_CLI=""
COMPOSE_CMD=""
if command -v docker >/dev/null 2>&1; then
    CONTAINER_CLI="docker"
    COMPOSE_CMD="docker compose"
elif command -v finch >/dev/null 2>&1; then
    CONTAINER_CLI="finch"
    COMPOSE_CMD="finch compose"
else
    echo "ERRO: Nem 'docker' nem 'finch' foram encontrados no PATH."
    exit 1
fi
echo "Engine detectada: ${CONTAINER_CLI}"

# 2. Parametros interativos usando $HOME como referencia padrao
PROJETOS_DIR="${HOME}/projetos"
DEFAULT_DEST="${PROJETOS_DIR}/mission-control"
DEFAULT_PORT="3001"

read -r -p "Diretorio no WSL [default: ${DEFAULT_DEST}]: " DEST_DIR
DEST_DIR="${DEST_DIR:-$DEFAULT_DEST}"

# Bloqueia caminhos dentro de /mnt/ para evitar corrupcao de SQLite WAL
if [[ "${DEST_DIR}" == /mnt/* ]]; then
    echo "AVISO CRITICO: ${DEST_DIR} esta sob /mnt/. O SQLite WAL nao suporta file-locking de 9P."
    read -r -p "Deseja forcar para o filesystem nativo ${DEFAULT_DEST}? [S/n]: " FORCE_NATIVE
    if [[ "${FORCE_NATIVE}" != "n" && "${FORCE_NATIVE}" != "N" ]]; then
        DEST_DIR="${DEFAULT_DEST}"
    fi
fi

read -r -p "Porta HTTP externa [default: ${DEFAULT_PORT}]: " APP_PORT
APP_PORT="${APP_PORT:-$DEFAULT_PORT}"

# 3. Clone e higienizacao
mkdir -p "$(dirname "${DEST_DIR}")"
if [ ! -d "${DEST_DIR}/.git" ]; then
    echo "Clonando Mission Control em ${DEST_DIR}..."
    git clone https://github.com/builderz-labs/mission-control.git "${DEST_DIR}"
else
    echo "Repositorio ja presente em ${DEST_DIR}. Atualizando..."
    git -C "${DEST_DIR}" pull --ff-only || true
fi

cd "${DEST_DIR}"

# Remove lixo herdado de Windows e converte quebras CRLF
rm -rf node_modules .next
find . -type f \( -name "*.sh" -o -name ".env*" -o -name "Dockerfile*" -o -name "*.yml" \) -exec sed -i 's/\r$//' {} + 2>/dev/null || true

# 4. Estrutura de dados persistente (SQLite WAL)
mkdir -p .data
chmod 777 .data 2>/dev/null || true

# 5. Mapeamento de porta limpo via docker-compose.override.yml
# ponytail: override local evita alterar arquivo rastreado pelo git; remova se a porta original 3000 for liberada
cat <<EOF > docker-compose.override.yml
services:
  mission-control:
    ports:
      - "${APP_PORT}:3000"
    volumes:
      - .data:/app/.data
EOF

# 6. Sobe containers
echo "Subindo containers via ${COMPOSE_CMD}..."
${COMPOSE_CMD} pull || true
${COMPOSE_CMD} up -d

echo "Mission Control pronto em: http://localhost:${APP_PORT}"
echo "Configure a conta admin inicial em: http://localhost:${APP_PORT}/setup"
