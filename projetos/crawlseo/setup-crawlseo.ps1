#Requires -Version 7.0
# =============================================================================
# setup-crawlseo.ps1 - CrawlSEO via wslc (WSL Containers)
#
# Constroi a imagem LOCALMENTE a partir do repositorio clonado, em vez de
# baixar ghcr.io/crawlseo/crawlseo:latest. Assim o Dockerfile pode ser editado
# (reduzir tamanho) e o .env local e usado.
#
# Sem -Action: abre o MENU de acoes (nao sobe nada por acidente).
#
# Acoes: up | stop | status | logs | delete
#
# Convencao de nomes (<projeto>-<funcao>):
#   containers : crawlseo-database, crawlseo-web, crawlseo-worker
#   volumes    : crawlseo-database-data
#   rede       : crawlseo-network
#
# A mesma imagem serve web e worker (o worker roda `node worker.cjs`).
#
# Exemplos:
#   .\setup-crawlseo.ps1                         # menu
#   .\setup-crawlseo.ps1 -Action up              # pergunta onde salvar
#   .\setup-crawlseo.ps1 -Action status          # URLs e estado
#   .\setup-crawlseo.ps1 -Action up -WebPort 3000
#   .\setup-crawlseo.ps1 -Action delete -KeepImages
# =============================================================================
[CmdletBinding()]
param(
    [ValidateSet("", "up", "stop", "delete", "status", "logs")]
    [string]$Action = "",

    [ValidateSet("volume", "bind")]
    [string]$Storage = "volume",

    [int]$WebPort = 3002,

    # Publicar o Postgres serve apenas para debug (psql/Prisma do host).
    # O compose publica em 127.0.0.1:5432 por padrao; aqui e opt-in.
    [switch]$ExposeDb,
    [int]$DbPort = 5432,

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

$projectName = "crawlseo"
$dbAlias     = "db"

$project = @{
    Name          = $projectName
    Title         = "CrawlSEO"
    ScriptDir     = $scriptDir
    RepoUrl       = "https://github.com/crawlseo/crawlseo.git"
    Network       = "$projectName-network"
    Containers    = @("$projectName-database", "$projectName-web", "$projectName-worker")
    Volumes       = @("$projectName-database-data")
    WebPort       = $WebPort
    ApiPort       = 0
    DbPort        = $DbPort
    UpstreamImage = "ghcr.io/crawlseo/crawlseo:latest"
    ExtraImages   = @("docker.io/library/postgres:16-alpine")

    # O Dockerfile termina no stage `runner` (web + worker.cjs na mesma imagem).
    # Deixamos vazio para usar o default do Dockerfile.
    BuildTarget   = ""

    BindDataDir   = (Join-Path $scriptDir "wslc-data")

    Access = @(
        [pscustomobject]@{ Label = "Web UI"; Url = "http://localhost:$WebPort"; Port = $WebPort; Container = "$projectName-web" }
        [pscustomobject]@{ Label = "Health"; Url = "http://localhost:$WebPort/api/health"; Port = $WebPort; Container = "$projectName-web" }
    )

    NextSteps = @"
Proximo passo: o primeiro login exige credenciais do Google OAuth.
  1. Crie um OAuth Client em https://console.cloud.google.com/apis/credentials
  2. URI de redirecionamento: http://localhost:$WebPort/api/auth/callback/google
  3. Preencha GOOGLE_CLIENT_ID e GOOGLE_CLIENT_SECRET em: <codigo>\.env.wslc
  4. Rode: -Action up
"@

    # -------------------------------------------------------------------------
    # PrepareEnv: gera .env.wslc com segredos, preservando os existentes.
    # -------------------------------------------------------------------------
    PrepareEnv = {
        param($src, $ctx)

        $envFile = Join-Path $src ".env.wslc"
        $existing = Read-EnvFile -Path $envFile

        # Preserva segredos ja gerados: trocar NEXTAUTH_SECRET invalida as
        # sessoes ativas; trocar a senha do Postgres quebra a conexao com um
        # volume de dados ja inicializado.
        $nextAuthSecret = $existing["NEXTAUTH_SECRET"]
        if (-not $nextAuthSecret) { $nextAuthSecret = New-RandomHex -Bytes 32 }
        else { Write-Host "  NEXTAUTH_SECRET existente preservado." -ForegroundColor Gray }

        $pgPass = $existing["POSTGRES_PASSWORD"]
        if (-not $pgPass) { $pgPass = New-RandomHex -Bytes 16 }
        else { Write-Host "  POSTGRES_PASSWORD existente preservada." -ForegroundColor Gray }

        $pgUser = $existing["POSTGRES_USER"]; if (-not $pgUser) { $pgUser = "crawlseo" }
        $pgDb   = $existing["POSTGRES_DB"];   if (-not $pgDb)   { $pgDb   = "crawlseo" }

        $googleId     = $existing["GOOGLE_CLIENT_ID"]
        $googleSecret = $existing["GOOGLE_CLIENT_SECRET"]

        $lines = @(
            "NEXTAUTH_URL=http://localhost:$($ctx.WebPort)"
            "NEXTAUTH_SECRET=$nextAuthSecret"
            "AUTH_TRUST_HOST=true"
            "POSTGRES_USER=$pgUser"
            "POSTGRES_PASSWORD=$pgPass"
            "POSTGRES_DB=$pgDb"
            "DATABASE_URL=postgresql://${pgUser}:${pgPass}@${dbAlias}:5432/${pgDb}"
            "GOOGLE_CLIENT_ID=$googleId"
            "GOOGLE_CLIENT_SECRET=$googleSecret"
            "NODE_ENV=production"
        )
        Write-TextFileNoBom -Path $envFile -Lines $lines

        if (-not $googleId -or -not $googleSecret) {
            Write-Host "  AVISO: GOOGLE_CLIENT_ID/SECRET vazios. O primeiro login vai falhar." -ForegroundColor Yellow
            Write-Host "  Edite: $envFile" -ForegroundColor Yellow
        }
        return $envFile
    }

    # -------------------------------------------------------------------------
    # RunContainers: db -> espera pg_isready -> web -> espera health -> worker
    # -------------------------------------------------------------------------
    RunContainers = {
        param($ctx)

        $envMap = Read-EnvFile -Path $ctx.EnvFile
        $pgUser = $envMap["POSTGRES_USER"]; if (-not $pgUser) { $pgUser = "crawlseo" }
        $pgPass = $envMap["POSTGRES_PASSWORD"]
        $pgDb   = $envMap["POSTGRES_DB"];   if (-not $pgDb) { $pgDb = "crawlseo" }

        # --- Dados ---------------------------------------------------------
        if ($ctx.Storage -eq "bind") {
            $bindDir = Join-Path $ctx.Project.ScriptDir "wslc-data"
            $dbDir = Join-Path $bindDir "database_data"
            New-Item -ItemType Directory -Path $dbDir -Force | Out-Null
            Write-Host "  AVISO: bind mount NTFS. O Postgres sobre 9P e lento e pode corromper." -ForegroundColor Yellow
            $dbMount = "${dbDir}:/var/lib/postgresql/data"
        } else {
            foreach ($v in $ctx.Volumes) {
                $null = Invoke-Wslc -ArgsList @("volume", "create", $v) -IgnoreError -Quiet
            }
            $dbMount = "$($ctx.Project.Name)-database-data:/var/lib/postgresql/data"
        }

        # --- Banco (Postgres) ----------------------------------------------
        Write-Host "  Subindo $($ctx.Project.Name)-database..." -ForegroundColor Gray
        $dbRunArgs = @(
            "run", "-d",
            "--name", "$($ctx.Project.Name)-database",
            "--network", $ctx.NetName,
            "--network-alias", $dbAlias,
            "--restart", "always",
            "-e", "POSTGRES_USER=$pgUser",
            "-e", "POSTGRES_PASSWORD=$pgPass",
            "-e", "POSTGRES_DB=$pgDb",
            "-v", $dbMount
        )
        if ($ctx.ExposeDb) { $dbRunArgs += @("-p", "0.0.0.0:$($ctx.DbPort):5432") }
        $dbRunArgs += "docker.io/library/postgres:16-alpine"
        $null = Invoke-Wslc -ArgsList $dbRunArgs -Quiet

        Write-Host "  Aguardando o Postgres aceitar conexoes..." -ForegroundColor Gray
        $ready = $false
        $deadline = (Get-Date).AddSeconds(120)
        while ((Get-Date) -lt $deadline) {
            $logs = & wslc logs "$($ctx.Project.Name)-database" 2>&1 | Out-String
            if ($logs -match "database system is ready to accept connections") { $ready = $true; break }
            Start-Sleep -Seconds 3
        }
        if ($ready) { Write-Host "  Banco pronto." -ForegroundColor Green }
        else { Write-Host "  AVISO: Postgres nao confirmou inicio em 120s. Veja: -Action logs" -ForegroundColor Yellow }

        # --- Aplicacao ------------------------------------------------------
        # O CMD da imagem roda `prisma migrate deploy && node server.js`
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
            "-e", "WORKER_MODE=off",
            $ctx.LocalImage
        ) -Quiet

        Write-Host "  Aguardando a aplicacao responder em /api/health..." -ForegroundColor Gray
        $appOk = $false
        $deadline = (Get-Date).AddSeconds(180)
        while ((Get-Date) -lt $deadline) {
            try {
                $resp = Invoke-WebRequest -Uri "http://localhost:$($ctx.WebPort)/api/health" `
                    -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
                if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400) { $appOk = $true; break }
            } catch { }
            Start-Sleep -Seconds 5
        }
        if ($appOk) { Write-Host "  Aplicacao respondendo." -ForegroundColor Green }
        else { Write-Host "  AVISO: /api/health nao respondeu em 180s (migrations podem estar rodando)." -ForegroundColor Yellow }

        # --- Worker ---------------------------------------------------------
        # Mesma imagem, comando diferente. Serve para que o app nao precise
        # rodar jobs inline (WORKER_MODE=off acima).
        Write-Host "  Subindo $($ctx.Project.Name)-worker..." -ForegroundColor Gray
        $null = Invoke-Wslc -ArgsList @(
            "run", "-d",
            "--name", "$($ctx.Project.Name)-worker",
            "--network", $ctx.NetName,
            "--restart", "always",
            "--env-file", $ctx.EnvFile,
            "-e", "NODE_ENV=production",
            "-e", "WORKER_MODE=worker",
            $ctx.LocalImage,
            "node", "worker.cjs"
        ) -Quiet
    }
}

Invoke-ProjectSetup -Project $project -Action $Action -Storage $Storage `
    -WebPort $WebPort -DbPort $DbPort -ExposeDb:$ExposeDb `
    -Force:$Force -NonInteractive:$NonInteractive -NoBuild:$NoBuild `
    -Rebuild:$Rebuild -KeepImages:$KeepImages -RemoveStorage:$RemoveStorage -SourcePath $SourcePath
