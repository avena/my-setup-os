#!/bin/bash

show_menu() {
    clear
    echo "=== WSL2 NETWORKING TOOLS (LINUX) ==="
    echo ""
    echo "1. Diagnóstico completo da rede"
    echo "2. Portproxy — configurar redirecionamento (socat/iptables)"
    echo "3. Portproxy — remover redirecionamento"
    echo "4. Portproxy — status"
    echo "5. Sair"
    echo ""
}

while true; do
    show_menu
    read -p "Escolha uma opcao: " choice
    case $choice in
        1)
            bash "$(dirname "$0")/diagnostico-rede.sh"
            read -p "Pressione Enter para continuar..."
            ;;
        2)
            read -p "Porta (default 3000): " port
            port=${port:-3000}
            bash "$(dirname "$0")/portproxy.sh" add "$port"
            read -p "Pressione Enter para continuar..."
            ;;
        3)
            read -p "Porta (default 3000): " port
            port=${port:-3000}
            bash "$(dirname "$0")/portproxy.sh" remove "$port"
            read -p "Pressione Enter para continuar..."
            ;;
        4)
            bash "$(dirname "$0")/portproxy.sh" status
            read -p "Pressione Enter para continuar..."
            ;;
        5)
            exit 0
            ;;
        *)
            echo "Opcao invalida."
            sleep 1
            ;;
    esac
done
