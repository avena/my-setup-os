#requires -Version 7

function Show-Menu {
    Clear-Host
    Write-Host "=== WSL2 NETWORKING TOOLS ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Portproxy — configurar redirecionamento de porta (WSL -> Windows)"
    Write-Host "2. Atualizar ponte — IP do WSL mudou, atualizar portproxy"
    Write-Host "3. Configurar túnel SSH — redirecionar porta 2222 -> maquina remota"
    Write-Host "4. Diagnóstico completo — IPs, NAT, portproxy, firewall"
    Write-Host "5. Sair"
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "Escolha uma opcao"
    switch ($choice) {
        "1" {
            $port = Read-Host "Porta (default 3000)"
            if (-not $port) { $port = 3000 }
            & "$PSScriptRoot\portproxy.ps1" -Port $port -Auto
            pause
        }
        "2" {
            $port = Read-Host "Porta (default 3000)"
            if (-not $port) { $port = 3000 }
            & "$PSScriptRoot\atualizar-ponte.ps1" -Port $port
            pause
        }
        "3" {
            & "$PSScriptRoot\config-ssh-tunnel.ps1"
            pause
        }
        "4" {
            & "$PSScriptRoot\diagnostico-rede.ps1"
            pause
        }
        "5" {
            exit 0
        }
        default {
            Write-Host "Opcao invalida." -ForegroundColor Red
            Start-Sleep 1
        }
    }
} while ($true)
