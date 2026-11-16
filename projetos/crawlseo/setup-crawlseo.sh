#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="${SCRIPT_DIR}/logs"
mkdir -p "${LOGS_DIR}"
LOG_FILE="${LOGS_DIR}/setup-$(date +'%Y%m%d-%H%M%S').log"

# Redireciona stdout e stderr simultaneamente para terminal e arquivo de log
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== [CrawlSEO] Setup e Inicializacao de Containers ==="
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
DEFAULT_DEST="${PROJETOS_DIR}/crawlseo"
DEFAULT_PORT="3000"

read -r -p "Diretorio no WSL [default: ${DEFAULT_DEST}]: " DEST_DIR
DEST_DIR="${DEST_DIR:-$DEFAULT_DEST}"

# Bloqueia caminhos dentro de /mnt/ para evitar falha no Postgres e lentidao
if [[ "${DEST_DIR}" == /mnt/* ]]; then
    echo "AVISO CRITICO: ${DEST_DIR} esta sob /mnt/. Isso degrada I/O e quebra volumes do PostgreSQL."
    read -r -p "Deseja forcar para o filesystem nativo ${DEFAULT_DEST}? [S/n]: " FORCE_NATIVE
    if [[ "${FORCE_NATIVE}" != "n" && "${FORCE_NATIVE}" != "N" ]]; then
        DEST_DIR="${DEFAULT_DEST}"
    fi
fi

read -r -p "Porta HTTP da aplicacao [default: ${DEFAULT_PORT}]: " APP_PORT
APP_PORT="${APP_PORT:-$DEFAULT_PORT}"

# 3. Clone e higienizacao
mkdir -p "$(dirname "${DEST_DIR}")"
if [ ! -d "${DEST_DIR}/.git" ]; then
    echo "Clonando CrawlSEO em ${DEST_DIR}..."
    git clone https://github.com/crawlseo/crawlseo.git "${DEST_DIR}"
else
    echo "Repositorio ja presente em ${DEST_DIR}. Atualizando..."
    git -C "${DEST_DIR}" pull --ff-only || true
fi

cd "${DEST_DIR}"

# Remove lixo herdado de Windows e converte quebras CRLF
rm -rf node_modules .next
find . -type f \( -name "*.sh" -o -name ".env*" -o -name "Dockerfile*" -o -name "*.yml" \) -exec sed -i 's/\r$//' {} + 2>/dev/null || true

# 4. Configuracao do .env
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        touch .env
    fi

    # ponytail: geracao de segredo via openssl ou /dev/urandom; atualize para cofre/secret manager em prod
    SECRET="$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p -c 32)"
    PG_PASS="$(openssl rand -hex 16 2>/dev/null || head -c 16 /dev/urandom | xxd -p -c 16)"

    # Preenche/atualiza chaves essenciais
    grep -q "^NEXTAUTH_SECRET=" .env && sed -i "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=${SECRET}|" .env || echo "NEXTAUTH_SECRET=${SECRET}" >> .env
    grep -q "^NEXTAUTH_URL=" .env && sed -i "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=http://localhost:${APP_PORT}|" .env || echo "NEXTAUTH_URL=http://localhost:${APP_PORT}" >> .env
    grep -q "^AUTH_TRUST_HOST=" .env || echo "AUTH_TRUST_HOST=true" >> .env
    grep -q "^POSTGRES_PASSWORD=" .env && sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${PG_PASS}|" .env || echo "POSTGRES_PASSWORD=${PG_PASS}" >> .env
    grep -q "^DATABASE_URL=" .env && sed -i "s|^DATABASE_URL=.*|DATABASE_URL=postgresql://postgres:${PG_PASS}@db:5432/crawlseo|" .env || echo "DATABASE_URL=postgresql://postgres:${PG_PASS}@db:5432/crawlseo" >> .env

    echo "Arquivo .env gerado com chaves seguras."
fi

# 5. Lembrete Google OAuth
if ! grep -q "^GOOGLE_CLIENT_ID=[a-zA-Z0-9]" .env || ! grep -q "^GOOGLE_CLIENT_SECRET=[a-zA-Z0-9]" .env; then
    echo "================================================================="
    echo "ATENCAO: O primeiro login exige credenciais do Google OAuth!"
    echo "Configure GOOGLE_CLIENT_ID e GOOGLE_CLIENT_SECRET em: ${DEST_DIR}/.env"
    echo "URI de redirecionamento: http://localhost:${APP_PORT}/api/auth/callback/google"
    echo "================================================================="
fi

# 6. Sobe containers
echo "Subindo containers via ${COMPOSE_CMD}..."
${COMPOSE_CMD} pull || true
${COMPOSE_CMD} up -d

echo "CrawlSEO pronto em: http://localhost:${APP_PORT}"
