# PowerShell Setup for Windows
# Run as Administrator
# Usage: .\setup.ps1

param(
    [switch]$InstallFonts,
    [switch]$InstallScoop,
    [switch]$SetupWSLConfig,
    [switch]$All
)

$ErrorActionPreference = "Stop"

$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$RED = "`e[31m"
$CYAN = "`e[36m"
$NC = "`e[0m"

$REPO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "$RED[ERROR] Execute como Administrador.$NC"
    exit 1
}

Write-Host "$CYAN====================================================$NC"
Write-Host "$CYAN  Setup Unificado - Windows                         $NC"
Write-Host "$CYAN====================================================$NC"

# ============================================================
# 1. Configurar PowerShell 7
# ============================================================
Write-Host "`n$CYAN--- 1. PowerShell 7 ---$NC"
$ps7Path = Get-Command pwsh -ErrorAction SilentlyContinue
if ($ps7Path) {
    Write-Host "$GREEN[OK] PowerShell 7 já instalada.$NC"
} else {
    Write-Host "$YELLOW[INFO] Instalando PowerShell 7...$NC"
    if ($InstallScoop -or $All) {
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop install pwsh
        } else {
            Write-Host "$YELLOW[WARN] Scoop não instalado. Pule e rode setup.ps1 -InstallScoop primeiro.$NC"
        }
    } else {
        Write-Host "$YELLOW[SKIP] Use -InstallScoop ou instale manualmente.$NC"
    }
}

# ============================================================
# 2. Instalar Scoop (se não existir)
# ============================================================
Write-Host "`n$CYAN--- 2. Scoop ---$NC"
if ($InstallScoop -or $All) {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "$GREEN[INFO] Instalando Scoop...$NC"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        iex (Invoke-RestMethod get.scoop.sh)
        Write-Host "$GREEN[OK] Scoop instalado.$NC"
    } else {
        Write-Host "$GREEN[OK] Scoop já instalado.$NC"
    }

    # Adicionar buckets
    $buckets = @("extras", "nerd-fonts")
    foreach ($b in $buckets) {
        if ((scoop bucket list) -notmatch $b) {
            Write-Host "$GREEN[INFO] Adicionando bucket: $b$NC"
            scoop bucket add $b
        }
    }

    # Importar programas
    $scoopJson = Join-Path $REPO_DIR "scoop\scoop-programs.json"
    if (Test-Path $scoopJson) {
        Write-Host "$YELLOW[INFO] Para importar programas:$NC"
        Write-Host "$YELLOW  scoop import $scoopJson$NC"
    }
} else {
    Write-Host "$YELLOW[SKIP] Use -InstallScoop.$NC"
}

# ============================================================
# 3. Instalar Fontes
# ============================================================
Write-Host "`n$CYAN--- 3. Fontes ---$NC"
if ($InstallFonts -or $All) {
    $fontScript = Join-Path $REPO_DIR "fonts\install-fonts.ps1"
    if (Test-Path $fontScript) {
        Write-Host "$GREEN[INFO] Instalando fontes...$NC"
        & $fontScript
    } else {
        Write-Host "$RED[ERROR] Script de fontes não encontrado.$NC"
    }
} else {
    Write-Host "$YELLOW[SKIP] Use -InstallFonts.$NC"
}

# ============================================================
# 4. Configurar .wslconfig
# ============================================================
Write-Host "`n$CYAN--- 4. WSL Config ---$NC"
if ($SetupWSLConfig -or $All) {
    $wslconfig = Join-Path $REPO_DIR ".wslconfig"
    $dest = Join-Path $env:USERPROFILE ".wslconfig"
    if (Test-Path $wslconfig) {
        Copy-Item $wslconfig $dest -Force
        Write-Host "$GREEN[OK] .wslconfig copiado para $dest$NC"
    } else {
        Write-Host "$RED[ERROR] Arquivo .wslconfig não encontrado.$NC"
    }
} else {
    Write-Host "$YELLOW[SKIP] Use -SetupWSLConfig.$NC"
}

# ============================================================
# 5. Configurar Política de Execução
# ============================================================
Write-Host "`n$CYAN--- 5. Execution Policy ---$NC"
$policy = Get-ExecutionPolicy -Scope CurrentUser
Write-Host "$GREEN[OK] ExecutionPolicy: $policy$NC"
if ($policy -eq "Restricted") {
    Write-Host "$YELLOW[INFO] Alterando ExecutionPolicy...$NC"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host "$GREEN[OK] ExecutionPolicy atualizada.$NC"
}

# ============================================================
# Finalização
# ============================================================
Write-Host "`n$CYAN====================================================$NC"
Write-Host "$GREEN[SUCCESS] Setup concluído!                        $NC"
Write-Host "$CYAN====================================================$NC"
Write-Host ""
Write-Host "$YELLOW Próximos passos:$NC"
Write-Host "  1. Reinicie o WSL:          $GREEN wsl --shutdown$NC"
Write-Host "  2. Verifique Scoop:         $GREEN scoop checkup$NC"
Write-Host "  3. Instale programas Scoop: $GREEN scoop import windows\scoop\scoop-programs.json$NC"
Write-Host ""
