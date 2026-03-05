#!/usr/bin/env pwsh
param()

$ErrorActionPreference = 'Stop'

Write-Host "Verificando suporte a NAT no Windows (WinNAT / NetNat)..." -ForegroundColor Cyan

# 1) Testa se o módulo NetNat/cmdlet Get-NetNat existe
if (-not (Get-Command -Name 'Get-NetNat' -ErrorAction SilentlyContinue)) {
    Write-Warning "Cmdlets de NAT (NetNat) não encontrados."
    Write-Warning "Instale o recurso 'RSAT: Routing and Remote Access Tools' / suporte a WinNAT conforme a versão do Windows."
    Write-Host  "Após instalar, execute novamente este script."
    exit 1
}

Write-Host "Suporte a NAT (NetNat) disponível." -ForegroundColor Green

# 2) Opcional: checar se já existe alguma regra NAT
try {
    $nats = Get-NetNat -ErrorAction SilentlyContinue
} catch {
    $nats = @()
}

if ($nats -and $nats.Count -gt 0) {
    Write-Host "Regras NAT encontradas:" -ForegroundColor Yellow
    $nats | Format-Table Name, ExternalIPInterfaceAddressPrefix, InternalIPInterfaceAddressPrefix -AutoSize
} else {
    Write-Host "Nenhuma regra NAT configurada ainda." -ForegroundColor Yellow
    Write-Host "Seu script 'nat-rede50-desktop.ps1' poderá criar as regras necessárias." -ForegroundColor Yellow
}

exit 0
