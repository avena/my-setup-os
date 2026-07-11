#!/bin/bash

set -euo pipefail

MODE="${1:-add}"
PORT="${2:-3000}"
TARGET_IP="${3:-192.168.60.6}"
TARGET_PORT="${4:-$PORT}}

case "$MODE" in
    add)
        echo "Criando redirecionamento: porta $PORT -> $TARGET_IP:$TARGET_PORT"
        if command -v socat &>/dev/null; then
            echo "Usando socat (user-space)..."
            nohup socat TCP-LISTEN:$PORT,fork,reuseaddr TCP:$TARGET_IP:$TARGET_PORT &
            echo "PID: $!"
        elif command -v iptables &>/dev/null; then
            echo "Usando iptables (precisa de root)..."
            sudo iptables -t nat -A PREROUTING -p tcp --dport $PORT -j DNAT --to-destination $TARGET_IP:$TARGET_PORT
            sudo iptables -A FORWARD -p tcp -d $TARGET_IP --dport $TARGET_PORT -j ACCEPT
            echo "Regra iptables criada."
        else
            echo "ERRO: instale socat (apt install socat) ou use iptables."
            exit 1
        fi
        ;;
    remove)
        echo "Removendo redirecionamento da porta $PORT..."
        if command -v socat &>/dev/null; then
            pkill -f "socat.*TCP-LISTEN:$PORT" 2>/dev/null && echo "Processo socat finalizado." || echo "Nenhum processo socat encontrado."
        fi
        if command -v iptables &>/dev/null; then
            sudo iptables -t nat -D PREROUTING -p tcp --dport $PORT -j DNAT --to-destination $TARGET_IP:$TARGET_PORT 2>/dev/null
            sudo iptables -D FORWARD -p tcp -d $TARGET_IP --dport $TARGET_PORT -j ACCEPT 2>/dev/null
            echo "Regra iptables removida."
        fi
        ;;
    status)
        echo "=== Portproxy Status ==="
        if command -v socat &>/dev/null; then
            pgrep -a socat | grep "TCP-LISTEN:$PORT" || echo "Nenhum processo socat para porta $PORT"
        fi
        if command -v iptables &>/dev/null; then
            sudo iptables -t nat -L PREROUTING -n 2>/dev/null | grep "$PORT" || echo "Nenhuma regra iptables para porta $PORT"
        fi
        ;;
    *)
        echo "Uso: $0 {add|remove|status} [porta] [ip_destino] [porta_destino]"
        echo "Exemplo: $0 add 3000 192.168.60.6 3000"
        exit 1
        ;;
esac
