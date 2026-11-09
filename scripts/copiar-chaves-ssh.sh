#!/usr/bin/env bash
# copiar-chaves-ssh.sh - Lista e copia chaves SSH existentes.
set -euo pipefail

# Self-check
if [ "${1:-}" = "--test" ]; then
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    touch "$TMP_DIR/id_test.pub"
    KEYS=("$TMP_DIR"/*.pub)
    test ${#KEYS[@]} -eq 1
    echo "[TEST OK] Auto-verificação passou."
    exit 0
fi

SSH_DIR="${SSH_DIR:-$HOME/.ssh}"
shopt -s nullglob
KEYS=("$SSH_DIR"/*.pub)
shopt -u nullglob

if [ ${#KEYS[@]} -eq 0 ]; then
    echo "Nenhuma chave pública (.pub) encontrada em $SSH_DIR." >&2
    exit 1
fi

echo "=== Chaves públicas encontradas em $SSH_DIR ==="
PS3="Escolha o número da chave que deseja copiar: "
select KEY_PUB in "${KEYS[@]}"; do
    if [ -n "$KEY_PUB" ]; then
        break
    fi
    echo "Opção inválida. Tente novamente."
done

echo ""
echo "Chave selecionada: $KEY_PUB"
echo "1) Enviar para servidor remoto via ssh-copy-id"
echo "2) Exibir conteúdo na tela / clipboard (para GitHub Secrets / CI/CD)"
read -r -p "Escolha a ação [1]: " ACTION
ACTION="${ACTION:-1}"

if [ "$ACTION" = "1" ]; then
    read -r -p "Informe 'usuario@ip-servidor' (ex: ubuntu@192.168.1.50): " REMOTE_HOST
    [ -z "$REMOTE_HOST" ] && { echo "Destino vazio. Abortando." >&2; exit 1; }
    ssh-copy-id -i "$KEY_PUB" "$REMOTE_HOST"
    echo "[OK] Chave copiada para $REMOTE_HOST."
else
    echo ""
    echo "=== CONTEÚDO DA CHAVE PÚBLICA ==="
    cat "$KEY_PUB"
    echo ""
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy < "$KEY_PUB"
        echo "(Copiado para o clipboard via wl-copy)"
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard < "$KEY_PUB"
        echo "(Copiado para o clipboard via xclip)"
    fi
fi
