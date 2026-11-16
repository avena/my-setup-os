#Requires -Version 7.0
# =============================================================================
# setup-open-notebook.ps1 - Open Notebook via wslc (WSL Containers)
#
# Constroi a imagem LOCALMENTE a partir do repositorio clonado, em vez de
# baixar lfnovo/open_notebook do Docker Hub. Assim o Dockerfile pode ser
# editado (reduzir tamanho) e o .env local e usado.
#
# Sem -Action: abre o MENU de acoes (nao sobe nada por acidente).
#
# Acoes: up | stop | status | logs | delete
#
# Convencao de nomes (<projeto>-<funcao>):
#   containers : open-notebook-database, open-notebook-web
#   volumes    : open-notebook-database-data, open-notebook-web-data
#   rede       : open-notebook-network
#
# Exemplos:
#   .\setup-open-notebook.ps1                          # menu
#   .\setup-open-notebook.ps1 -Action status           # URLs e estado
#   .\setup-open-notebook.ps1 -Action up               # pergunta onde salvar
#   .\setup-open-notebook.ps1 -Action up -SourcePath D:\wslc-src\open-notebook
#   .\setup-open-notebook.ps1 -Action up -NoBuild      # usa imagem ja construida
#   .\setup-open-notebook.ps1 -Action up -Rebuild      # --no-cache
#   .\setup-open-notebook.ps1 -Action delete -KeepImages
# =============================================================================
[CmdletBinding()]
param(
    # Vazio = abre o menu interativo
    [ValidateSet("", "up", "stop", "delete", "status", "logs")]
    [string]$Action = "",

    # volume = volume nomeado no storage do wslc (ext4, RECOMENDADO)
    # bind   = pasta wslc-data\ (NTFS/9P, risco de corromper o RocksDB)
    [ValidateSet("volume", "bind")]
    [string]$Storage = "volume",

    [int]$WebPort = 8502,
    [int]$ApiPort = 5055,

    # Publicar a porta do SurrealDB serve apenas para debug (Surrealist).
    # Por padrao NAO publicamos: evita conflito com servicos do Windows
    # (a porta 8000, por exemplo, e usada pelo iphlpsvc).
    [switch]$ExposeDb,
    [int]$DbPort = 8010,

    # Onde clonar o repositorio. Vazio = pergunta a cada execucao.
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

# -----------------------------------------------------------------------------
# Metadados do projeto
# -----------------------------------------------------------------------------
$projectName = "open-notebook"
$dbAlias     = "surrealdb"   # alias DNS curto dentro da rede custom

$project = @{
    Name          = $projectName
    Title         = "Open Notebook"
    ScriptDir     = $scriptDir
    RepoUrl       = "https://github.com/lfnovo/open-notebook.git"
    Network       = "$projectName-network"
    Containers    = @("$projectName-database", "$projectName-web")
    Volumes       = @("$projectName-database-data", "$projectName-web-data")
    WebPort       = $WebPort
    ApiPort       = $ApiPort
    DbPort        = $DbPort
    UpstreamImage = "lfnovo/open_notebook:v1-latest"
    ExtraImages   = @("docker.io/surrealdb/surrealdb:v2")

    # O Dockerfile tem 6 stages. `runtime` (default) = app sem SurrealDB
    # embutido, que e o que queremos: o banco roda em container separado.
    # Evita o stage `single`, que embute o binario do SurrealDB na imagem.
    BuildTarget   = "runtime"

    BindDataDir   = (Join-Path $scriptDir "wslc-data")

    Access = @(
        [pscustomobject]@{ Label = "Web UI";   Url = "http://localhost:$WebPort";        Port = $WebPort; Container = "$projectName-web" }
        [pscustomobject]@{ Label = "API Docs"; Url = "http://localhost:$ApiPort/docs";   Port = $ApiPort; Container = "$projectName-web" }
    )

    NextSteps = "Proximo passo: abra a Web UI, va em Manage -> Models e configure seu provedor de IA."

    # -------------------------------------------------------------------------
    # PrepareEnv: gera .env para o container a partir do repo clonado.
    # Preserva a chave de criptografia entre execucoes (perder a chave torna
    # os dados existentes ilegiveis).
    # -------------------------------------------------------------------------
    PrepareEnv = {
        param($src, $ctx)

        $envFile = Join-Path $src ".env.wslc"
        $existingKey = Get-EnvValue -Path $envFile -Key "OPEN_NOTEBOOK_ENCRYPTION_KEY"
        if (-not $existingKey) {
            # Tambem tenta recuperar do .env do repositorio, se o usuario ja tinha um
            $existingKey = Get-EnvValue -Path (Join-Path $src ".env") -Key "OPEN_NOTEBOOK_ENCRYPTION_KEY"
        }

        if ($existingKey) {
            Write-Host "  Chave de criptografia existente preservada." -ForegroundColor Gray
            $key = $existingKey
        } else {
            $key = New-RandomHex -Bytes 32
            Write-Host "  Nova chave de criptografia gerada (64 hex)." -ForegroundColor Gray
        }

        $lines = @(
            "OPEN_NOTEBOOK_ENCRYPTION_KEY=$key"
            "SURREAL_URL=ws://${dbAlias}:8000/rpc"
            "SURREAL_USER=root"
            "SURREAL_PASSWORD=root"
            "SURREAL_NAMESPACE=open_notebook"
            "SURREAL_DATABASE=open_notebook"
        )
        Write-TextFileNoBom -Path $envFile -Lines $lines
        return $envFile
    }

    # -------------------------------------------------------------------------
    # RunContainers: sobe banco e aplicacao
    # -------------------------------------------------------------------------
    RunContainers = {
        param($ctx)

        # --- Dados ---------------------------------------------------------
        if ($ctx.Storage -eq "bind") {
            $bindDir = Join-Path $ctx.Project.ScriptDir "wslc-data"
            $dbDir  = Join-Path $bindDir "database_data"
            $webDir = Join-Path $bindDir "web_data"
            New-Item -ItemType Directory -Path $dbDir, $webDir -Force | Out-Null
            Write-Host "  AVISO: bind mount NTFS. O 9P pode corromper o lock do RocksDB." -ForegroundColor Yellow
            $dbMount  = "${dbDir}:/mydata"
            $webMount = "${webDir}:/app/data"
        } else {
            foreach ($v in $ctx.Volumes) {
                $null = Invoke-Wslc -ArgsList @("volume", "create", $v) -IgnoreError -Quiet
            }
            $dbMount  = "$($ctx.Project.Name)-database-data:/mydata"
            $webMount = "$($ctx.Project.Name)-web-data:/app/data"
        }

        # --- Banco (SurrealDB) ---------------------------------------------
        # --user root e obrigatorio: a imagem roda como uid 65532 e o volume
        # nomeado e criado como root:root. Sem isso o RocksDB falha com
        # "Failed to create RocksDB directory: PermissionDenied (os error 13)".
        Write-Host "  Subindo $($ctx.Project.Name)-database..." -ForegroundColor Gray
        $dbRunArgs = @(
            "run", "-d",
            "--name", "$($ctx.Project.Name)-database",
            "--user", "root",
            "--network", $ctx.NetName,
            "--network-alias", $dbAlias,
            "--restart", "always"
        )
        if ($ctx.ExposeDb) { $dbRunArgs += @("-p", "0.0.0.0:$($ctx.DbPort):8000") }
        $dbRunArgs += @(
            "-v", $dbMount,
            "docker.io/surrealdb/surrealdb:v2",
            "start", "--log", "info",
            "--user", "root", "--pass", "root",
            "rocksdb:/mydata/mydatabase.db"
        )
        $null = Invoke-Wslc -ArgsList $dbRunArgs -Quiet

        Write-Host "  Aguardando o banco ficar pronto..." -ForegroundColor Gray
        $ready = Wait-ForLog -Container "$($ctx.Project.Name)-database" `
            -Pattern "Started web server" -TimeoutSeconds 120
        if ($ready) {
            Write-Host "  Banco pronto." -ForegroundColor Green
        } else {
            Write-Host "  AVISO: banco nao confirmou inicio em 120s. Veja: -Action logs" -ForegroundColor Yellow
        }

        # --- Aplicacao ------------------------------------------------------
        Write-Host "  Subindo $($ctx.Project.Name)-web..." -ForegroundColor Gray
        $null = Invoke-Wslc -ArgsList @(
            "run", "-d",
            "--name", "$($ctx.Project.Name)-web",
            "--network", $ctx.NetName,
            "--restart", "always",
            "-p", "0.0.0.0:$($ctx.WebPort):8502",
            "-p", "0.0.0.0:$($ctx.ApiPort):5055",
            "--env-file", $ctx.EnvFile,
            "-v", $webMount,
            $ctx.LocalImage
        ) -Quiet
    }
}

Invoke-ProjectSetup -Project $project -Action $Action -Storage $Storage `
    -WebPort $WebPort -ApiPort $ApiPort -DbPort $DbPort -ExposeDb:$ExposeDb `
    -Force:$Force -NonInteractive:$NonInteractive -NoBuild:$NoBuild `
    -Rebuild:$Rebuild -KeepImages:$KeepImages -RemoveStorage:$RemoveStorage -SourcePath $SourcePath
