#!/bin/bash

echo "=== DIAGNOSTICO WSL $(date) ==="
echo ""
echo "[1] IPs:"
ip -4 addr show | grep inet
echo ""
echo "[2] Rota:"
ip route
echo ""
echo "[3] Ping gateway:"
ping -c 2 172.26.64.1
echo ""
echo "[4] Ping destino (192.168.60.6):"
ping -c 2 192.168.60.6
echo ""
echo "[5] Teste porta 2222:"
nc -zv -w 3 172.26.64.1 2222
echo ""
echo "[6] Teste porta 22:"
nc -zv -w 3 172.26.64.1 22
echo ""
echo "[7] Status SSH:"
sudo service ssh status 2>/dev/null || systemctl status ssh 2>/dev/null || echo "ssh service not found"
echo ""
echo "=== FIM ==="
