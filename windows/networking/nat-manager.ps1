#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Gerenciador de regras NAT do Windows - Lista e limpa configurações NAT

.DESCRIPTION
    Este script lista todas as regras NAT ativas ou remove todas as regras NAT + desabilita IP Forwarding.
    
    USO:
    =====
    # Listar todas as regras NAT
    .\nat-manager.ps1 -List

    # Limpar TUDO (NAT + IP Forwarding)
    .\nat-manager.ps1 -Clean

    # Mostrar ajuda/uso
    .\nat-manager.ps1 -?

.PARAMETER List
    Lista todas as regras NAT ativas com detalhes.

.PARAMETER Clean
    Remove TODAS as regras NAT e desabilita IP Forwarding.

.EXAMPLE
    .\nat-manager.ps1 -List
    .\nat-manager.ps1 -Clean

.NOTES
    Requer PowerShell como Administrador para limpeza.
    Compatível com Windows 10/11/Server.
#>

param(
    [switch]$List,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

Write-Host "🔍 Gerenciador de NATs do Windows`n" -ForegroundColor Cyan

if ($List -or -not ($List -or $Clean)) {
    Write-Host "`n📋 Todas as regras NAT ativas:`n" -ForegroundColor Green
    $nats = Get-NetNat
    if ($nats) {
        $nats | Select-Object Name, InternalIPInterfaceAddressPrefix, @{N='Status';E={$_.Active}}, @{N='Rede Interna';E={$_.InternalIPInterfaceAddressPrefix}} | Format-Table -AutoSize
        Write-Host "`n💡 Para limpar: .\nat-manager.ps1 -Clean" -ForegroundColor Yellow
    } else {
        Write-Host "  ✅ Nenhuma regra NAT ativa" -ForegroundColor Green
    }
}

if ($Clean) {
    Write-Host "`n🗑️  Iniciando limpeza COMPLETA..." -ForegroundColor Red
    $nats = Get-NetNat
    $natCount = 0
    if ($nats) {
        $nats | Remove-NetNat -Confirm:$false -ErrorAction SilentlyContinue
        $natCount = @($nats).Count
        Write-Host "  ✅ $natCount regra(s) NAT removida(s)" -ForegroundColor Green
    } else {
        Write-Host "  ℹ️  Nenhuma regra NAT encontrada" -ForegroundColor Yellow
    }
    
    # IP Forwarding off
    $oldValue = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name IPEnableRouter -ErrorAction SilentlyContinue).IPEnableRouter
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name IPEnableRouter -Value 0
    Write-Host "  ✅ IP Forwarding desabilitado (era: $oldValue)" -ForegroundColor Green
    
    # Limpa IPs 192.168.50.x (opcional)
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -eq "192.168.50.1" } | 
        Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "  ✅ IPs 192.168.50.1 removidos das interfaces" -ForegroundColor Green
    
    Write-Host "`n🧹 Limpeza CONCLUÍDA!" -ForegroundColor Cyan
}

Write-Host "`n📖 COMANDOS RÁPIDOS:`n" -ForegroundColor Gray
Write-Host "  .\nat-manager.ps1 -List     → Lista regras NAT`n" -ForegroundColor Gray
Write-Host "  .\nat-manager.ps1 -Clean    → Remove TUDO`n" -ForegroundColor Gray
Write-Host "  .\nat-manager.ps1           → Mostra lista + ajuda" -ForegroundColor Gray
