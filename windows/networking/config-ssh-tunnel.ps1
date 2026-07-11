param(
    [string]$TargetIP = "192.168.60.6",
    [int]$LocalPort = 2222,
    [int]$TargetPort = 22
)

Write-Host "== Configurando redirecionamento SSH ==" -ForegroundColor Cyan

if (-not (Test-Connection $TargetIP -Count 1 -Quiet)) {
    Write-Warning "Maquina B ($TargetIP) nao responde ao ping."
}

netsh interface portproxy delete v4tov4 listenport=$LocalPort listenaddress=0.0.0.0 2>$null
netsh interface portproxy add v4tov4 listenport=$LocalPort listenaddress=0.0.0.0 connectport=$TargetPort connectaddress=$TargetIP

$rule = netsh interface portproxy show v4tov4 | Select-String "$LocalPort"
if ($rule) {
    Write-Host "[OK] Portproxy criado: $($rule.Line.Trim())" -ForegroundColor Green
} else {
    Write-Error "[ERRO] Falha ao criar portproxy."
}

New-NetFirewallRule -DisplayName "Portproxy $LocalPort" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $LocalPort -ErrorAction SilentlyContinue

$localTest = Test-NetConnection 127.0.0.1 -Port $LocalPort -WarningAction SilentlyContinue
if ($localTest.TcpTestSucceeded) {
    Write-Host "[OK] Porta $LocalPort escutando localmente." -ForegroundColor Green
}

Write-Host "`nComando de teste no WSL:" -ForegroundColor Cyan
Write-Host "  nc -zv 172.26.64.1 $LocalPort" -ForegroundColor Yellow
Write-Host "  ssh livre@172.26.64.1 -p $LocalPort" -ForegroundColor Yellow
