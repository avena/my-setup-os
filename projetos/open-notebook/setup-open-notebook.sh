#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="${SCRIPT_DIR}/logs"
mkdir -p "${LOGS_DIR}"
LOG_FILE="${LOGS_DIR}/setup-$(date +'%Y%m%d-%H%M%S').log"

# Redireciona stdout e stderr simultaneamente para terminal e arquivo de log
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== [Open Notebook] Setup e Inicializacao de Containers ==="
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
DEFAULT_DEST="${PROJETOS_DIR}/open-notebook"
DEFAULT_UI_PORT="8502"
DEFAULT_API_PORT="5055"

read -r -p "Diretorio no WSL [default: ${DEFAULT_DEST}]: " DEST_DIR
DEST_DIR="${DEST_DIR:-$DEFAULT_DEST}"

# Bloqueia caminhos dentro de /mnt/ para evitar falhas no RocksDB/SurrealDB
if [[ "${DEST_DIR}" == /mnt/* ]]; then
    echo "AVISO CRITICO: ${DEST_DIR} esta sob /mnt/. O SurrealDB/RocksDB exige file-locking nativo do ext4."
    read -r -p "Deseja forcar para o filesystem nativo ${DEFAULT_DEST}? [S/n]: " FORCE_NATIVE
    if [[ "${FORCE_NATIVE}" != "n" && "${FORCE_NATIVE}" != "N" ]]; then
        DEST_DIR="${DEFAULT_DEST}"
    fi
fi

read -r -p "Porta HTTP da Web UI [default: ${DEFAULT_UI_PORT}]: " UI_PORT
UI_PORT="${UI_PORT:-$DEFAULT_UI_PORT}"

read -r -p "Porta da REST API [default: ${DEFAULT_API_PORT}]: " API_PORT
API_PORT="${API_PORT:-$DEFAULT_API_PORT}"

# 3. Clone e higienizacao
mkdir -p "$(dirname "${DEST_DIR}")"
if [ ! -d "${DEST_DIR}/.git" ]; then
    echo "Clonando Open Notebook em ${DEST_DIR}..."
    git clone https://github.com/lfnovo/open-notebook.git "${DEST_DIR}"
else
    echo "Repositorio ja presente em ${DEST_DIR}. Atualizando..."
    git -C "${DEST_DIR}" pull --ff-only || true
fi

cd "${DEST_DIR}"

# Remove lixo herdado de Windows e converte quebras CRLF
rm -rf node_modules .next
find . -type f \( -name "*.sh" -o -name ".env*" -o -name "Dockerfile*" -o -name "*.yml" \) -exec sed -i 's/\r$//' {} + 2>/dev/null || true

# 4. Pastas de persistencia de dados
mkdir -p surreal_data notebook_data
chmod 777 surreal_data notebook_data 2>/dev/null || true

# 5. Configuracao do .env
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        touch .env
    fi

    # ponytail: geracao de segredo via openssl ou /dev/urandom; mantenha fixo apos o primeiro uso
    ENC_KEY="$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p -c 32)"
    DB_PASS="$(openssl rand -hex 16 2>/dev/null || head -c 16 /dev/urandom | xxd -p -c 16)"

    grep -q "^OPEN_NOTEBOOK_ENCRYPTION_KEY=" .env && sed -i "s|^OPEN_NOTEBOOK_ENCRYPTION_KEY=.*|OPEN_NOTEBOOK_ENCRYPTION_KEY=${ENC_KEY}|" .env || echo "OPEN_NOTEBOOK_ENCRYPTION_KEY=${ENC_KEY}" >> .env
    grep -q "^SURREAL_USER=" .env || echo "SURREAL_USER=root" >> .env
    grep -q "^SURREAL_PASSWORD=" .env && sed -i "s|^SURREAL_PASSWORD=.*|SURREAL_PASSWORD=${DB_PASS}|" .env || echo "SURREAL_PASSWORD=${DB_PASS}" >> .env

    echo "Arquivo .env configurado com chave de criptografia OPEN_NOTEBOOK_ENCRYPTION_KEY unica."
fi

# 6. Override de portas customizadas caso divirjam do padrao
if [[ "${UI_PORT}" != "8502" || "${API_PORT}" != "5055" ]]; then
    cat <<EOF > docker-compose.override.yml
services:
  open_notebook:
    ports:
      - "${UI_PORT}:8502"
      - "${API_PORT}:5055"
EOF
    echo "docker-compose.override.yml criado para mapear UI:${UI_PORT} e API:${API_PORT}."
fi

# 7. Sobe containers
echo "Subindo containers via ${COMPOSE_CMD}..."
${COMPOSE_CMD} pull || true
${COMPOSE_CMD} up -d

echo ""
echo "=== Open Notebook iniciado com sucesso! ==="
echo "Web UI: http://localhost:${UI_PORT}"
echo "API Docs: http://localhost:${API_PORT}/docs"
echo "Passo seguinte: abra http://localhost:${UI_PORT}, acesse Manage -> Models e configure seu provedor de IA (Ollama, 9Router, OpenAI, etc.)."
