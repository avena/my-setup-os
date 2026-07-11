param(
    [int]$Port = 3000,
    [string]$Protocol = "TCP",
    [ValidateSet("Add", "Remove")]
    [string]$Action = "Add",
    [switch]$Auto,
    [switch]$Cleanup
)

if ($Cleanup) { $Action = "Remove" }

$wslIP = $null

if ($Auto -or $Action -eq "Add") {
    Write-Host "Detectando IP do WSL..." -ForegroundColor Cyan
    $ipLine = wsl -d Ubuntu hostname -I 2>$null
    if ($ipLine) {
        $wslIP = ($ipLine -split ' ' | Select-Object -First 1).Trim()
    }
    if (-not $wslIP) {
        Write-Error "ERRO: WSL nao esta rodando. Inicie o WSL primeiro."
        exit 1
    }
    Write-Host "WSL IP: $wslIP" -ForegroundColor Green
}

if ($Action -eq "Remove") {
    Write-Host "Removendo regra de portproxy para porta $Port..." -ForegroundColor Yellow
    netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=0.0.0.0 2>$null
    Remove-NetFirewallRule -DisplayName "WSL Portproxy $Port" -ErrorAction SilentlyContinue
    Write-Host "Regra removida." -ForegroundColor Green
    exit 0
}

netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=0.0.0.0 2>$null
Remove-NetFirewallRule -DisplayName "WSL Portproxy $Port" -ErrorAction SilentlyContinue

netsh interface portproxy add v4tov4 listenport=$Port listenaddress=0.0.0.0 connectport=$Port connectaddress=$wslIP
New-NetFirewallRule -DisplayName "WSL Portproxy $Port" -Direction Inbound -LocalPort $Port -Action Allow -Protocol $Protocol

$winIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -match 'Ethernet|Wi-Fi|WiFi' } | Select-Object -First 1).IPAddress
if (-not $winIP) { $winIP = 'IP_WINDOWS' }

Write-Host ""
Write-Host "SUCESSO! Portproxy ativo:" -ForegroundColor Green
Write-Host "Porta $Port --> $wslIP:$Port" -ForegroundColor Yellow
Write-Host "Acesso local: http://localhost:$Port" -ForegroundColor Yellow
Write-Host "Acesso rede: http://$winIP`:$Port" -ForegroundColor Yellow
Write-Host "Verificar: netsh interface portproxy show v4tov4" -ForegroundColor Cyan
