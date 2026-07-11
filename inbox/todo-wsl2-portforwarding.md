# TODO: WSL2 Port Forwarding — Script de Configuração de Rede Híbrida

## Contexto

Ambiente de desenvolvimento remoto com duas máquinas Windows + WSL2.  
O WSL2 usa rede NAT — o IP interno (`172.xx.xx.xx`) não é roteável externamente.  
Precisamos de scripts para criar e manter o redirecionamento de portas (portproxy) entre a rede física e a rede do WSL.

## Arquitetura

| Máquina | SO | IP Rede Local | IP WSL (dinâmico) | Função |
|---------|----|---------------|-------------------|--------|
| **A** | Windows + WSL Ubuntu | `192.168.60.1` | `172.26.78.107/20` | Estação de trabalho (acessa B via SSH) |
| **B** | Windows + WSL Ubuntu | `192.168.60.6` | `172.22.117.202/20` | Servidor de desenvolvimento (roda Browsersync) |

## O que desenvolver

### 1. Script PowerShell (Windows — principal)
- Detectar IP atual do WSL (`wsl hostname -I`)
- Configurar `netsh interface portproxy` para redirecionar porta(s) do IP físico para o IP do WSL
- Liberar porta no Firewall do Windows (`New-NetFirewallRule`)
- Parâmetros: `-Port` (porta), `-Protocol` (TCP), `-Action` (Add/Remove)
- Modo `--auto` para detectar IP do WSL automaticamente
- Modo `--cleanup` para remover regras

### 2. Script de Manutenção (PowerShell)
- Script rápido para reconfigurar portproxy quando o IP do WSL mudar
- Deve detectar IP atual do WSL e atualizar a regra

### 3. Script Bash (Linux)
- Alternativa para quando o servidor estiver em Linux nativo (sem WSL)
- Usar `iptables` ou `socat` para redirecionamento equivalente

### 4. Automação (futuro)
- Serviço Windows ou tarefa agendada para manter portproxy atualizado automaticamente
- Detecção de mudança de IP do WSL

## Comandos de Diagnóstico

- `netsh interface portproxy show v4tov4`
- `netstat -an | findstr :3000`
- `Test-NetConnection 127.0.0.1 -Port 3000`

## Próximos Passos

1. Criar script PowerShell principal (`windows/portproxy.ps1`)
2. Criar script de manutenção rápida (`windows/atualizar-ponte.ps1`)
3. Criar script bash equivalente (`linux/portproxy.sh`)
4. Testar em ambiente real
5. Documentar instruções de uso
