#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$Distro = "",
    [string]$WslCommand = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logsDir = Join-Path $scriptDir "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir "setup-windows-$timestamp.log"

Start-Transcript -Path $logFile -Append | Out-Null
Write-Host "=== [Open Notebook Windows -> WSL Container Bridge] ===" -ForegroundColor Cyan
Write-Host "Log gravado em: $logFile"

# 1. Detecta engine de container do WSL (wsl.exe prioritario, wslc como fallback)
# wslc nao suporta os flags '-e' / '-d' nem o subcomando 'wslpath' do wsl.exe,
# entao wsl.exe e sempre preferido quando disponivel.
$wslExe = Get-Command "wsl" -ErrorAction SilentlyContinue
$wslcBin = Get-Command "wslc" -ErrorAction SilentlyContinue

$wslBin = if ($WslCommand) {
    $WslCommand
} elseif ($wslExe) {
    "wsl"
} elseif ($wslcBin) {
    "wslc"
} else {
    Write-Error "Nem 'wsl' nem 'wslc' foram encontrados no Windows."
    Stop-Transcript | Out-Null
    exit 1
}

$IsWslExe = if ($WslCommand) { ($WslCommand -eq "wsl") } else { ($wslBin -eq "wsl") }

Write-Host "Ferramenta WSL selecionada: $wslBin" -ForegroundColor Yellow

# 2. Converte caminho do script bash para formato Linux dentro do WSL
$bashScriptWin = Join-Path $scriptDir "setup-open-notebook.sh"

if ($IsWslExe) {
    $distroParams = if ($Distro) { @("-d", $Distro) } else { @() }
    $bashScriptWsl = (& $wslBin @distroParams wslpath -u "$bashScriptWin" 2>$null)
} else {
    $bashScriptWsl = $null  # wslc nao tem wslpath; usa conversao manual abaixo
}

if (-not $bashScriptWsl) {
    $drive = $bashScriptWin.Substring(0, 1).ToLower()
    $rest = ($bashScriptWin.Substring(2) -replace "\\", "/")
    $bashScriptWsl = "/mnt/$drive$rest"
} else {
    $bashScriptWsl = $bashScriptWsl.Trim()
}

# 3. Monta comando e dispara no WSL nativo
Write-Host "Invocando setup no filesystem nativo do WSL (ext4)..." -ForegroundColor Yellow
$wslCmd = "chmod +x '$bashScriptWsl' && bash '$bashScriptWsl'"

if ($IsWslExe) {
    $bashArgs = @("-e", "bash", "-lic", "$wslCmd")
    if ($Distro) {
        & $wslBin -d $Distro @bashArgs
    } else {
        & $wslBin @bashArgs
    }
} else {
    # wslc nao reconhece '-e' nem '-d'; executa o comando direto
    & $wslBin "bash" "-lic" "$wslCmd"
}

Write-Host "`nProcesso concluido. Acesso local: http://localhost:8502" -ForegroundColor Green
Stop-Transcript | Out-Null
