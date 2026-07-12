# Project: my-setup-os

## Shell
- Windows scripts: PowerShell 7 (`pwsh`)
- Linux scripts: Bash

## Conventions
- PowerShell scripts use `#requires -Version 7`
- All networking scripts require Administrator privileges
- Linux scripts are executable (chmod +x)

## Structure
- `windows/` — Windows host configuration (PowerShell 7)
- `linux/` — WSL/Linux configuration (Bash)
- `shared/` — cross-platform configs (.gitconfig, etc.)
- `inbox/` — TODO documents and ideas

## Networking (windows/networking/)
- Scripts must be run as Administrator
- `run.ps1` — interactive menu launcher
- `portproxy.ps1` — main portproxy script
- `atualizar-ponte.ps1` — update when WSL IP changes
- `config-ssh-tunnel.ps1` — SSH tunnel to remote machine
- `diagnostico-rede.ps1` — full network diagnostic

## Networking (linux/)
- `run.sh` — interactive menu launcher
- `diagnostico-rede.sh` — WSL network diagnostic
- `portproxy.sh` — port forwarding via socat/iptables
