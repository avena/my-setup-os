# TODO: WSL2 Diagnóstico e Configuração de Rede — Especificação Técnica

## Contexto

Especificação técnica completa do diagnóstico e configuração de rede entre WSL2, Windows e Máquina B (`192.168.60.6`). Documenta problemas encontrados, soluções aplicadas e scripts de automação.

## Arquitetura

| Máquina | SO | IP Rede Local | IP WSL | Gateway WSL | Função |
|---------|----|---------------|--------|-------------|--------|
| **A** | Windows 10/11 | `192.168.60.1` | `172.26.78.107/20` | `172.26.64.1` | Hospedeiro WSL, gateway |
| **B** | Windows + WSL Ubuntu | `192.168.60.6` | `172.22.117.202/20` | `172.22.112.1` | Servidor SSH (porta 22) |
| **WSL A** | Ubuntu 24.04 | NAT | `172.26.78.107/20` | `172.26.64.1` | Cliente SSH |

## Problemas Encontrados

1. **NAT do WSL não roteava para rede física** — Windows bloqueava tráfego da interface virtual WSL (perfil Público + falta de regras NAT)
2. **Porta 22 ocupada pelo Windows** — OpenSSH Server do Windows já usa porta 22
3. **WSL não acessava porta 22 do Windows** — WinNAT/firewall bloqueando

## Solução Implementada

Portproxy no Windows: `0.0.0.0:2222` → `192.168.60.6:22`

## O que desenvolver

### 1. Script de Diagnóstico Windows (PowerShell)
- Coletar IPs, NAT, portproxy, firewall, ping e teste de porta
- Copiar resultado para área de transferência

### 2. Script de Diagnóstico WSL (Bash)
- IPs, rota, ping gateway/destino, teste de porta, status SSH

### 3. Script de Automação (`config-ssh-tunnel.ps1`)
- Parâmetros: `-TargetIP`, `-LocalPort`, `-TargetPort`
- Verificar conectividade com destino
- Remover/criar regra portproxy
- Configurar firewall
- Testar porta local

### 4. Script de Manutenção
- Atualizar portproxy quando IP da Máquina B mudar
- Verificar status do SSH na Máquina B

## Regras Ativas (Windows)

| Porta | Destino | Função |
|-------|---------|--------|
| `2222` | `192.168.60.6:22` | SSH para Máquina B |
| `5500` | `127.0.0.1:5500` | (local) |
| `9222` | `127.0.0.1:9222` | (local) |

## Serviços

- `WinNAT` — Running
- `OpenSSH Server` (Windows) — porta 22
- `sshd` (WSL Máquina B) — porta 22

## Próximos Passos

1. Criar script de diagnóstico Windows (`windows/diagnostico-rede.ps1`)
2. Criar script de diagnóstico WSL (`linux/diagnostico-rede.sh`)
3. Criar script de automação (`windows/config-ssh-tunnel.ps1`)
4. Criar script de manutenção (`windows/atualizar-portproxy.ps1`)
5. Testar em ambiente real
6. Documentar procedimentos de manutenção
