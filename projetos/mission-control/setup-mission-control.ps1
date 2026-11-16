#Requires -Version 7.0
# =============================================================================
# setup-mission-control.ps1 - Mission Control via wslc (WSL Containers)
#
# Este projeto NAO tem imagem publicada: o compose usa `build: .`. Portanto o
# clone do repositorio + `wslc build` e obrigatorio (nao ha alternativa de pull).
#
# Sem -Action: abre o MENU de acoes (nao sobe nada por acidente).
#
# Acoes: up | stop | status | logs | delete
#
# Convencao de nomes (<projeto>-<funcao>):
#   containers : mission-control-web
#   volumes    : mission-control-web-data
#   rede       : mission-control-network
#
# Limitacoes do `wslc run` em relacao ao compose original:
#   - `read_only: true`      -> nao suportado
#   - `cap_drop: ALL`        -> nao suportado
#   - `security_opt: no-new-privileges` -> nao suportado
#   - `extra_hosts` host-gateway -> nao suportado (use o IP do host se precisar)
# O container roda com o usuario `nextjs` definido na imagem, como no original.
#
# Exemplos:
#   .\setup-mission-control.ps1                      # menu
#   .\setup-mission-control.ps1 -Action up
#   .\setup-mission-control.ps1 -Action status
#   .\setup-mission-control.ps1 -Action delete -KeepImages
# =============================================================================
[CmdletBinding()]
param(
    [ValidateSet("", "up", "stop", "delete", "status", "logs")]
    [string]$Action = "",

    [ValidateSet("volume", "bind")]
    [string]$Storage = "volume",

    [int]$WebPort = 3003,

    # Endereco do gateway OpenClaw. Sem gateway, o painel funciona em modo
    # standalone (NEXT_PUBLIC_GATEWAY_OPTIONAL=true).
    [string]$GatewayHost = "host.docker.internal",
    [int]$GatewayPort = 18789,

    [string]$SourcePath = "",

    [switch]$Force,
    [switch]$NonInteractive,
    [switch]$NoBuild,
    [switch]$Rebuild,
    [switch]$KeepImages,

    # Apaga o storage.vhdx inteiro no delete (libera todo o espaco em disco,
    # mas remove imagens/volumes de TODOS os projetos do wslc)
    [switch]$RemoveStorage
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# A biblioteca pode estar na pasta pai (estrutura projetos/) ou na mesma
# pasta (quando o script e copiado sozinho para outro lugar).
$common = Join-Path (Split-Path -Parent $scriptDir) "wslc-common.ps1"
if (-not (Test-Path $common)) {
    $common = Join-Path $scriptDir "wslc-common.ps1"
}
if (-not (Test-Path $common)) {
    throw "Biblioteca nao encontrada: wslc-common.ps1 (procurei em '$(Split-Path -Parent $scriptDir)' e '$scriptDir')"
}
. $common

$projectName = "mission-control"

$project = @{
    Name          = $projectName
    Title         = "Mission Control"
    ScriptDir     = $scriptDir
    RepoUrl       = "https://github.com/builderz-labs/mission-control.git"
    Network       = "$projectName-network"
    Containers    = @("$projectName-web")
    Volumes       = @("$projectName-web-data")
    WebPort       = $WebPort
    ApiPort       = 0
    DbPort        = 0
    UpstreamImage = $null       # nao existe imagem publicada
    ExtraImages   = @()

    # Dockerfile tem 3 stages (base/deps/build/runtime); o default ja e o runtime.
    BuildTarget   = ""

    # NEXT_PUBLIC_* sao embutidas no bundle do browser em tempo de BUILD.
    BuildArgs     = @(
        "NEXT_PUBLIC_GATEWAY_HOST="
        "NEXT_PUBLIC_GATEWAY_PORT=$GatewayPort"
    )

    BindDataDir   = (Join-Path $scriptDir "wslc-data")

    Access = @(
        [pscustomobject]@{ Label = "Web UI"; Url = "http://localhost:$WebPort";       Port = $WebPort; Container = "$projectName-web" }
        [pscustomobject]@{ Label = "Setup";  Url = "http://localhost:$WebPort/setup"; Port = $WebPort; Container = "$projectName-web" }
    )

    NextSteps = @"
Proximo passo: crie a conta admin inicial em http://localhost:$WebPort/setup
Gateway OpenClaw: $GatewayHost`:$GatewayPort
  (se nao houver gateway rodando, o painel abre em modo standalone)
"@

    # -------------------------------------------------------------------------
    # PrepareEnv: gera .env.wslc com segredos, preservando os existentes.
    # -------------------------------------------------------------------------
    PrepareEnv = {
        param($src, $ctx)

        $envFile = Join-Path $src ".env.wslc"
        $existing = Read-EnvFile -Path $envFile

        # O entrypoint da imagem gera AUTH_SECRET/API_KEY sozinho e persiste em
        # /app/.data. Mas se o volume for recriado, gerar aqui evita perder a
        # sessao. Preservamos o que ja existe.
        $authSecret = $existing["AUTH_SECRET"]
        if (-not $authSecret) { $authSecret = New-RandomHex -Bytes 32 }
        else { Write-Host "  AUTH_SECRET existente preservado." -ForegroundColor Gray }

        $authUser = $existing["AUTH_USER"]; if (-not $authUser) { $authUser = "admin" }
        $authPass = $existing["AUTH_PASS"]

        $lines = @(
            "PORT=3000"
            "AUTH_USER=$authUser"
            "AUTH_SECRET=$authSecret"
            "OPENCLAW_GATEWAY_HOST=$GatewayHost"
            "OPENCLAW_GATEWAY_PORT=$GatewayPort"
            "NEXT_PUBLIC_GATEWAY_PORT=$GatewayPort"
            "MC_COOKIE_SECURE=false"
            "MC_COOKIE_SAMESITE=lax"
            "MC_ALLOWED_HOSTS=localhost:$($ctx.WebPort)"
        )
        if ($authPass) {
            $lines += "AUTH_PASS=$authPass"
        } else {
            Write-Host "  AUTH_PASS nao definida: use a tela /setup para criar o admin." -ForegroundColor Gray
        }
        Write-TextFileNoBom -Path $envFile -Lines $lines
        return $envFile
    }

    # -------------------------------------------------------------------------
    # RunContainers: um unico container (SQLite em volume nomeado)
    # -------------------------------------------------------------------------
    RunContainers = {
        param($ctx)

        # --- Dados ---------------------------------------------------------
        # O compose original usa mc-data:/app/.data (SQLite WAL). Volume nomeado
        # e obrigatorio: SQLite WAL nao suporta file-locking sobre 9P/NTFS.
        if ($ctx.Storage -eq "bind") {
            $bindDir = Join-Path $ctx.Project.ScriptDir "wslc-data"
            $dataDir = Join-Path $bindDir "web_data"
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            Write-Host "  AVISO CRITICO: bind mount NTFS. O SQLite WAL nao suporta file-locking de 9P." -ForegroundColor Red
            Write-Host "  Use -Storage volume (padrao) para evitar corrupcao do banco." -ForegroundColor Red
            $dataMount = "${dataDir}:/app/.data"
        } else {
            foreach ($v in $ctx.Volumes) {
                $null = Invoke-Wslc -ArgsList @("volume", "create", $v) -IgnoreError -Quiet
            }
            $dataMount = "$($ctx.Project.Name)-web-data:/app/.data"
        }

        Write-Host "  Subindo $($ctx.Project.Name)-web..." -ForegroundColor Gray
        $null = Invoke-Wslc -ArgsList @(
            "run", "-d",
            "--name", "$($ctx.Project.Name)-web",
            "--network", $ctx.NetName,
            "--restart", "always",
            "-p", "0.0.0.0:$($ctx.WebPort):3000",
            "--env-file", $ctx.EnvFile,
            "-e", "PORT=3000",
            "-e", "HOSTNAME=0.0.0.0",
            "-v", $dataMount,
            $ctx.LocalImage
        ) -Quiet

        Write-Host "  Aguardando a aplicacao responder..." -ForegroundColor Gray
        $ok = $false
        $deadline = (Get-Date).AddSeconds(180)
        while ((Get-Date) -lt $deadline) {
            try {
                $resp = Invoke-WebRequest -Uri "http://localhost:$($ctx.WebPort)/" `
                    -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
                if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400) { $ok = $true; break }
            } catch { }
            Start-Sleep -Seconds 5
        }
        if ($ok) { Write-Host "  Aplicacao respondendo." -ForegroundColor Green }
        else { Write-Host "  AVISO: nao respondeu em 180s. Veja: -Action logs" -ForegroundColor Yellow }
    }
}

Invoke-ProjectSetup -Project $project -Action $Action -Storage $Storage `
    -WebPort $WebPort -Force:$Force -NonInteractive:$NonInteractive `
    -NoBuild:$NoBuild -Rebuild:$Rebuild -KeepImages:$KeepImages `
    -RemoveStorage:$RemoveStorage -SourcePath $SourcePath
