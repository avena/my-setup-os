#!/usr/bin/env bash
# gerar-chaves-ssh.sh - Gera chaves SSH com escolha de nome, tamanho/tipo e configuração opcional de ~/.ssh/config.
set -euo pipefail

# Self-check
if [ "${1:-}" = "--test" ]; then
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    HOME="$TMP_DIR" "$0" "test_key" "2048" "s" "meuhost" "example.com" "meuuser" >/dev/null
    test -f "$TMP_DIR/.ssh/test_key"
    test -f "$TMP_DIR/.ssh/test_key.pub"
    test -f "$TMP_DIR/.ssh/config"
    grep -q "Host meuhost" "$TMP_DIR/.ssh/config"
    grep -q "IdentityFile $TMP_DIR/.ssh/test_key" "$TMP_DIR/.ssh/config"
    echo "[TEST OK] Auto-verificação passou."
    exit 0
fi

KEY_NAME="${1:-}"
KEY_SIZE="${2:-}"
CONF_OPT="${3:-}"
HOST_ALIAS="${4:-}"
HOST_NAME="${5:-}"
HOST_USER="${6:-}"

if [ -z "$KEY_NAME" ]; then
    read -r -p "Nome do arquivo da chave [id_ed25519_deploy]: " KEY_NAME
    KEY_NAME="${KEY_NAME:-id_ed25519_deploy}"
fi

if [ -z "$KEY_SIZE" ]; then
    read -r -p "Tamanho/Tipo (ed25519 | 4096 | 3072 | 2048) [ed25519]: " KEY_SIZE
    KEY_SIZE="${KEY_SIZE:-ed25519}"
fi

TARGET_DIR="$HOME/.ssh"
mkdir -p "$TARGET_DIR" && chmod 700 "$TARGET_DIR"
KEY_PATH="$TARGET_DIR/$KEY_NAME"

if [ -f "$KEY_PATH" ]; then
    echo "Erro: O arquivo $KEY_PATH já existe. Operação cancelada." >&2
    exit 1
fi

if [ "$KEY_SIZE" = "ed25519" ]; then
    ssh-keygen -t ed25519 -N "" -C "$KEY_NAME" -f "$KEY_PATH" -q
elif [[ "$KEY_SIZE" =~ ^(2048|3072|4096)$ ]]; then
    ssh-keygen -t rsa -b "$KEY_SIZE" -N "" -C "$KEY_NAME" -f "$KEY_PATH" -q
else
    echo "Erro: Tamanho inválido '$KEY_SIZE'. Use ed25519, 4096, 3072 ou 2048." >&2
    exit 1
fi

chmod 600 "$KEY_PATH"
chmod 644 "${KEY_PATH}.pub"

echo ""
echo "=== CHAVES SALVAS COM SUCESSO ==="
echo "Chave Privada (Secret CI/CD): $KEY_PATH"
echo "Chave Pública (Servidor):     ${KEY_PATH}.pub"

# 2. Configuração opcional de login fácil em ~/.ssh/config
if [ -z "$CONF_OPT" ]; then
    echo ""
    read -r -p "Deseja configurar o ~/.ssh/config para facilitar o login direto (ex: 'ssh dreamhost')? (s/N): " CONF_OPT
fi

if [[ "$CONF_OPT" =~ ^[sSyY]$ ]]; then
    if [ -z "$HOST_ALIAS" ]; then
        read -r -p "Apelido do host (ex: dreamhost): " HOST_ALIAS
    fi
    if [ -z "$HOST_NAME" ]; then
        read -r -p "HostName ou IP do servidor (ex: batemacumba.net): " HOST_NAME
    fi
    if [ -z "$HOST_USER" ]; then
        read -r -p "Usuário remoto (ex: agronomiauser): " HOST_USER
    fi

    CONFIG_FILE="$TARGET_DIR/config"
    touch "$CONFIG_FILE" && chmod 600 "$CONFIG_FILE"

    cat << EOF >> "$CONFIG_FILE"

Host $HOST_ALIAS
    HostName $HOST_NAME
    User $HOST_USER
    IdentityFile $KEY_PATH
    # ponytail: default 60s ping para evitar timeout em hosts como DreamHost; mover para Match host se precisar de regras complexas
    ServerAliveInterval 60
EOF

    echo ""
    echo "[OK] Configuração gravada em $CONFIG_FILE"
    echo "Agora você pode conectar diretamente com: ssh $HOST_ALIAS"
fi

echo ""
echo "Comando para enviar a chave ao servidor remoto:"
echo "  ssh-copy-id -i ${KEY_PATH}.pub usuario@ip-servidor"
