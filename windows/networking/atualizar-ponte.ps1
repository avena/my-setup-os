param(
    [int]$Port = 3000
)

Write-Host "Atualizando portproxy para o novo IP do WSL..." -ForegroundColor Cyan

$ipLine = wsl -d Ubuntu hostname -I 2>$null
if (-not $ipLine) {
    Write-Error "ERRO: WSL nao esta rodando. Inicie o WSL primeiro."
    exit 1
}

$wslIP = ($ipLine -split ' ' | Select-Object -First 1).Trim()
Write-Host "Novo IP do WSL: $wslIP" -ForegroundColor Green

netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=0.0.0.0 2>$null
netsh interface portproxy add v4tov4 listenport=$Port listenaddress=0.0.0.0 connectport=$Port connectaddress=$wslIP

$rule = netsh interface portproxy show v4tov4 | Select-String "$Port"
if ($rule) {
    Write-Host "Portproxy atualizado com sucesso!" -ForegroundColor Green
    Write-Host "Porta $Port --> $wslIP:$Port" -ForegroundColor Yellow
} else {
    Write-Error "ERRO: Falha ao atualizar portproxy."
}
