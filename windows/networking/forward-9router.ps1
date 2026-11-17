<#
.SYNOPSIS
    Recria o portproxy 127.0.0.1:20128 -> <IP do WSL>:20128 para o gateway 9Router.

.DESCRIPTION
    O 9Router roda dentro do WSL Ubuntu escutando em 0.0.0.0:20128. O CodeBuddy IDE
    (e outros clientes) rodam no Windows e apontam para http://127.0.0.1:20128, então
    dependem de um portproxy do Windows para o IP do WSL.

    Esse IP muda a cada reinicialização do WSL, o que quebra o portproxy. Este script
    descobre o IP atual e recria a regra. Escuta apenas em 127.0.0.1 (loopback), então
    NÃO precisa de regra de firewall.

    Rode como Administrador. Se o IP mudar, basta rodar de novo.

.PARAMETER Port
    Porta do gateway (padrão 20128).

.PARAMETER Distro
    Nome da distro WSL (padrão: distro padrão do sistema).

.PARAMETER SkipTest
    Não faz o teste HTTP final no /v1/models.

.EXAMPLE
    .\forward-9router.ps1

.EXAMPLE
    .\forward-9router.ps1 -Distro Ubuntu -Port 20128
#>
param(
    [int]$Port = 20128,
    [string]$Distro = "",
    [switch]$SkipTest
)

$ErrorActionPreference = "Stop"

# --- 0. Precisa ser Administrador (netsh portproxy exige) ---------------------
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERRO: execute este script como Administrador (netsh portproxy exige elevacao)." -ForegroundColor Red
    exit 1
}

# --- 1. Descobrir o IP do WSL ------------------------------------------------
Write-Host "Procurando IP do WSL..." -ForegroundColor Cyan

$wslArgs = @()
if ($Distro) { $wslArgs += @("-d", $Distro) }

$ipLine = & wsl @wslArgs -e ip -4 addr show eth0 2>$null |
          Select-String 'inet\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' |
          Select-Object -First 1

if (-not $ipLine) {
    Write-Host "ERRO: WSL nao encontrado ou sem IP em eth0. O WSL esta rodando? (wsl -l -v)" -ForegroundColor Red
    exit 1
}

$WSL_IP = $ipLine.Matches[0].Groups[1].Value
Write-Host "WSL IP: $WSL_IP" -ForegroundColor Green

# --- 2. Verificar se o gateway esta de fato escutando no WSL -----------------
Write-Host "Verificando se o 9Router escuta na porta $Port dentro do WSL..." -ForegroundColor Cyan
$listen = & wsl @wslArgs -e bash -lc "ss -ltn 2>/dev/null | grep -c ':$Port'" 2>$null
if ($LASTEXITCODE -ne 0 -or "$listen".Trim() -eq "0" -or "$listen".Trim() -eq "") {
    Write-Host "AVISO: nada escutando em :$Port dentro do WSL. Suba o gateway: ~/9router/start.sh" -ForegroundColor Yellow
}

# --- 3. Limpar proxies antigos dessa porta ----------------------------------
Write-Host "Removendo portproxy antigo da porta $Port..." -ForegroundColor Cyan
foreach ($addr in @("127.0.0.1", "0.0.0.0")) {
    netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=$addr 2>$null | Out-Null
}

# --- 4. Criar o novo portproxy (loopback -> WSL) -----------------------------
Write-Host "Criando portproxy 127.0.0.1:$Port -> ${WSL_IP}:$Port ..." -ForegroundColor Cyan
netsh interface portproxy add v4tov4 listenport=$Port listenaddress=127.0.0.1 connectport=$Port connectaddress=$WSL_IP | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: falha ao criar o portproxy." -ForegroundColor Red
    exit 1
}

# --- 5. Testar ---------------------------------------------------------------
if (-not $SkipTest) {
    Write-Host "Testando http://127.0.0.1:$Port/v1/models ..." -ForegroundColor Cyan
    $ok = $false
    for ($i = 1; $i -le 3 -and -not $ok; $i++) {
        try {
            $r = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/v1/models" -TimeoutSec 30 -UseBasicParsing
            if ($r.StatusCode -eq 200) {
                Write-Host "OK: HTTP 200 ($($r.RawContentLength) bytes)" -ForegroundColor Green
                $ok = $true
            }
        } catch {
            $msg = $_.Exception.Message
            # 401 = gateway respondeu, só faltou a chave: o tunel esta funcionando
            if ($msg -match '401') {
                Write-Host "OK: HTTP 401 (tunel funciona; sem apiKey no teste)" -ForegroundColor Green
                $ok = $true
            } else {
                Write-Host "  tentativa $i falhou: $msg" -ForegroundColor DarkYellow
                Start-Sleep -Seconds 2
            }
        }
    }
    if (-not $ok) {
        Write-Host "AVISO: o tunel foi criado mas o teste HTTP falhou. Cheque se o 9Router esta de pe." -ForegroundColor Yellow
    }
}

# --- 6. Resumo ---------------------------------------------------------------
Write-Host ""
Write-Host "SUCESSO! Portproxy ativo:" -ForegroundColor Green
Write-Host "  127.0.0.1:$Port --> ${WSL_IP}:$Port" -ForegroundColor Yellow
Write-Host ""
Write-Host "Regras atuais:" -ForegroundColor Cyan
netsh interface portproxy show v4tov4
Write-Host ""
Write-Host "Se o WSL reiniciar e o IP mudar, rode este script novamente." -ForegroundColor Gray
Write-Host "O models.json do CodeBuddy ja aponta para 127.0.0.1 - nao precisa editar nada nele." -ForegroundColor Gray
