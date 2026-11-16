#Requires -Version 7.0
# =============================================================================
# wslc-common.ps1 - biblioteca compartilhada dos setups wslc
#
# Usada por:
#   open-notebook/setup-open-notebook.ps1
#   crawlseo/setup-crawlseo.ps1
#   mission-control/setup-mission-control.ps1
#   wslc-clean.ps1
#
# Todos os projetos expoem as MESMAS acoes:
#   up | stop | status | logs | delete
#
# Convencao de nomes de recursos: <projeto>-<funcao>
#   containers : <projeto>-database, <projeto>-web, <projeto>-worker
#   volumes    : <projeto>-<funcao>-data
#   rede       : <projeto>-network
#
# IMPORTANTE - dois armazenamentos distintos:
#
#   1. Codigo-fonte (clone, Dockerfile, .env) -> pasta escolhida pelo usuario.
#      E POR PROJETO. Onde o usuario edita o Dockerfile para reduzir a imagem.
#
#   2. Imagens e volumes -> storage.vhdx da sessao wslc.
#      E GLOBAL (uma sessao para todos os projetos), definido em:
#        %LOCALAPPDATA%\wslc\settings.yaml
#          session:
#            storagePath: D:\wslc-data
#      O disco virtual fica em <storagePath>\wslc\sessions\<sessao>\storage.vhdx
#
#   Um `docker compose down -v` na distro Ubuntu NAO apaga nada disso.
# =============================================================================

# NOTA: sem Set-StrictMode. Estes scripts acessam chaves opcionais de
# hashtables de configuracao ($Project.BuildArgs, $Project.ExtraImages), e o
# modo estrito transformaria uma chave ausente em erro fatal.

# -----------------------------------------------------------------------------
# Deteccao do wslc
# -----------------------------------------------------------------------------
function Assert-Wslc {
    $cmd = Get-Command wslc -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "wslc.exe nao encontrado no PATH. Atualize o WSL com: wsl --update (requer WSL >= 2.9.3)"
    }
    return $cmd.Source
}

# Executa wslc e lanca erro se o exit code for != 0.
# Retorna a saida (array de linhas). So ecoa no console quando -Quiet nao foi
# pedido, para nao duplicar saida quando o chamador usa o retorno.
function Invoke-Wslc {
    param(
        [Parameter(Mandatory)][string[]]$ArgsList,
        [switch]$IgnoreError,
        [switch]$Quiet
    )
    $output = & wslc @ArgsList 2>&1
    $code = $LASTEXITCODE
    if (-not $Quiet -and $output) {
        $output | ForEach-Object { Write-Host $_ }
    }
    if (-not $IgnoreError -and $code -ne 0) {
        # Inclui a saida real: sem isso o motivo (porta ocupada, permissao
        # negada, imagem inexistente) fica invisivel com -Quiet.
        $detail = ($output | Out-String).Trim()
        $msg = "Falha: wslc $($ArgsList -join ' ') (exit $code)"
        if ($detail) { $msg += "`n$detail" }
        throw $msg
    }
    return $output
}

# Ecoa a saida de um wslc de leitura (status, logs, list)
function Show-Wslc {
    param([Parameter(Mandatory)][string[]]$ArgsList)
    & wslc @ArgsList 2>&1 | ForEach-Object { Write-Host $_ }
}

# Converte a saida NDJSON do wslc (um objeto JSON por linha) em objetos.
# ConvertFrom-Json nao aceita NDJSON de multiplos objetos de uma vez.
function Get-WslcJsonObjects {
    param([Parameter(Mandatory)][string[]]$ArgsList)
    $out = & wslc @ArgsList 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $out) { return @() }
    $items = @()
    foreach ($line in $out) {
        if (-not $line) { continue }
        $t = "$line".Trim()
        if (-not $t) { continue }
        try { $items += ($t | ConvertFrom-Json) } catch { }
    }
    return $items
}

# Mapa nome -> estado ("running", "exited", ...) de todos os containers
function Get-ContainerStates {
    $items = Get-WslcJsonObjects -ArgsList @("container", "list", "--all", "--format", "json")
    $map = @{}
    foreach ($i in $items) {
        if ($i.Names) { $map["$($i.Names)"] = "$($i.State)" }
    }
    return $map
}

# Volumes anexados a um container (nomeados e anonimos).
# Usa inspect porque `container list` trunca a lista de mounts.
function Get-ContainerVolumes {
    param([Parameter(Mandatory)][string]$Name)
    $out = & wslc container inspect $Name 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $out) { return @() }
    try {
        $obj = (($out -join "`n") | ConvertFrom-Json) | Select-Object -First 1
    } catch {
        return @()
    }
    $names = @()
    foreach ($m in @($obj.Mounts)) {
        if ($m -and $m.Type -eq "volume" -and $m.Name) { $names += "$($m.Name)" }
    }
    return $names
}

# -----------------------------------------------------------------------------
# Storage do wslc: configuracao e localizacao fisica
# -----------------------------------------------------------------------------

# Le o settings.yaml do wslc (usuario). Retorna o caminho base configurado em
# session.storagePath, se houver.
function Get-WslcSettings {
    $file = Join-Path $env:LOCALAPPDATA "wslc\settings.yaml"
    $info = [pscustomobject]@{
        File           = $file
        Exists         = $false
        StoragePath    = $null
        MaxStorageSize = $null
        SessionsRoot   = (Join-Path $env:LOCALAPPDATA "wslc\sessions")
    }
    if (-not (Test-Path $file)) { return $info }

    $info.Exists = $true
    $section = $null
    foreach ($raw in [System.IO.File]::ReadAllLines($file)) {
        $line = $raw -replace '\s+#.*$', ''
        if ($line -match '^\s*#' -or $line -notmatch '\S') { continue }
        if ($line -match '^([A-Za-z_][\w.]*)\s*:\s*(.*)$') {
            $section = $Matches[1].Trim()
            $value = $Matches[2].Trim().Trim('"').Trim("'")
            if ($section -eq 'session.storagePath' -and $value -and $value -ne 'default') {
                $info.StoragePath = $value
            }
            if ($section -eq 'session.maxStorageSize' -and $value -and $value -ne 'default') {
                $info.MaxStorageSize = $value
            }
            continue
        }
        # Chave indentada dentro de "session:"
        if ($section -eq 'session' -and $line -match '^\s+([A-Za-z_][\w]*)\s*:\s*(.*)$') {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim().Trim('"').Trim("'")
            if ($key -eq 'storagePath' -and $value -and $value -ne 'default') {
                $info.StoragePath = $value
            }
            if ($key -eq 'maxStorageSize' -and $value -and $value -ne 'default') {
                $info.MaxStorageSize = $value
            }
        }
    }

    if ($info.StoragePath) {
        $info.SessionsRoot = Join-Path $info.StoragePath "wslc\sessions"
    }
    return $info
}

# Onde o wslc guarda o disco virtual. Retorna tambem se foi criado.
function Get-WslcStorageInfo {
    $settings = Get-WslcSettings
    $root = $settings.SessionsRoot
    $result = [pscustomobject]@{
        Available     = $false
        Root          = $root
        Path          = $null
        SizeGB         = 0
        ConfiguredAt  = $settings.StoragePath
        SettingsFile  = $settings.File
    }
    if (-not (Test-Path $root)) { return $result }
    $vhdx = Get-ChildItem -Path $root -Filter "storage.vhdx" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending | Select-Object -First 1
    if (-not $vhdx) { return $result }
    $result.Available = $true
    $result.Path = $vhdx.FullName
    $result.SizeGB = [math]::Round($vhdx.Length / 1GB, 2)
    return $result
}

# Imprime uma linha resumindo onde os dados do wslc residem.
function Write-StorageSummary {
    param([Parameter(Mandatory)]$Storage)
    if ($Storage.Available) {
        Write-Host "Storage do wslc: $($Storage.Path) ($($Storage.SizeGB) GB)" -ForegroundColor DarkGray
        if ($Storage.ConfiguredAt) {
            Write-Host "  (definido em settings.yaml: session.storagePath = $($Storage.ConfiguredAt))" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "Storage do wslc: ainda nao criado em $($Storage.Root)" -ForegroundColor DarkGray
    }
}

# -----------------------------------------------------------------------------
# Portas: quem esta usando e oferecer parar
# -----------------------------------------------------------------------------
function Get-PortOwner {
    param([int]$Port)

    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $conn) { return $null }

    $pidNum = $conn.OwningProcess
    $procName = try { (Get-Process -Id $pidNum -ErrorAction Stop).ProcessName } catch { "pid $pidNum" }
    $description = $null
    $wslcContainer = $null

    # O wslc publica portas via um proxy dllhost.exe. Nesse caso o processo nao
    # diz nada util: perguntamos ao wslc qual container mapeia a porta.
    try {
        $items = Get-WslcJsonObjects -ArgsList @("container", "list", "--all", "--format", "json")
        foreach ($c in $items) {
            if ($c.Ports -and "$($c.Ports)" -match ":$Port->") {
                $wslcContainer = "$($c.Names)"
                $description = "container wslc '$($c.Names)' ($($c.State)) - imagem $($c.Image)"
                break
            }
        }
    } catch { }

    if (-not $description) {
        if ($procName -match 'dllhost') {
            $description = "proxy do wslc (dllhost.exe) - porta publicada por algum container"
        } else {
            $description = "$procName (PID $pidNum)"
        }
    }

    return [pscustomobject]@{
        Port      = $Port
        Pid       = $pidNum
        Process   = $procName
        Container = $wslcContainer
        Details   = $description
    }
}

# Verifica se as portas de host estao livres.
# Sem isso o wslc falha com WSAEACCES ("acesso a um soquete proibido"), que nao
# diz qual porta e nem quem a ocupa.
#
# Ocupante container do wslc  -> oferece parar (ou para direto com -Force)
# Ocupante servico do Windows -> apenas informa e sugere outras portas
function Assert-PortFree {
    param(
        [int[]]$Ports,
        [switch]$Interactive
    )

    $owners = @()
    foreach ($p in $Ports) {
        $owner = Get-PortOwner -Port $p
        if ($owner) { $owners += $owner }
    }
    if ($owners.Count -eq 0) { return }

    Write-Host "`nPortas ocupadas no Windows:" -ForegroundColor Yellow
    foreach ($o in $owners) {
        Write-Host "  porta $($o.Port) -> $($o.Details)" -ForegroundColor Yellow
    }

    $stoppable = @($owners | Where-Object { $_.Container })
    $blocking = @($owners | Where-Object { -not $_.Container })

    if ($blocking.Count -gt 0) {
        Write-Host "`nEstas portas pertencem a servicos do Windows e nao podem ser liberadas pelo script." -ForegroundColor Red
        Write-Host "Escolha outras portas nos parametros do script (ex.: -WebPort 8503)." -ForegroundColor Red
        throw "Portas indisponiveis: $(($blocking | ForEach-Object { $_.Port }) -join ', ')"
    }

    $names = @($stoppable | ForEach-Object { $_.Container } | Select-Object -Unique)
    Write-Host "`nEssas portas estao em uso por containers do wslc: $($names -join ', ')" -ForegroundColor Yellow

    $doStop = $true
    if ($Interactive) {
        $answer = Read-Host "Parar esses containers agora? [S/n]"
        if ($answer -eq 'n' -or $answer -eq 'N') { $doStop = $false }
    }
    if (-not $doStop) {
        throw "Portas em uso: $(($stoppable | ForEach-Object { $_.Port }) -join ', '). Nada foi alterado."
    }

    foreach ($n in $names) {
        Write-Host "  parando $n..." -ForegroundColor Gray
        $null = Invoke-Wslc -ArgsList @("container", "stop", $n) -IgnoreError -Quiet
    }

    # Aguarda o proxy do wslc liberar os sockets
    $deadline = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt $deadline) {
        $stillBusy = @()
        foreach ($p in $Ports) {
            if (Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue) {
                $stillBusy += $p
            }
        }
        if ($stillBusy.Count -eq 0) {
            Write-Host "  portas liberadas." -ForegroundColor Green
            return
        }
        Start-Sleep -Seconds 2
    }
    throw "As portas $(($Ports) -join ', ') continuam ocupadas apos parar os containers."
}

# -----------------------------------------------------------------------------
# Espera por padrao no log (banco pronto, app healthy)
# -----------------------------------------------------------------------------
function Wait-ForLog {
    param(
        [Parameter(Mandatory)][string]$Container,
        [Parameter(Mandatory)][string]$Pattern,
        [int]$TimeoutSeconds = 120
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $states = Get-ContainerStates
        if ($states.ContainsKey($Container) -and $states[$Container] -eq 'exited') {
            throw "Container '$Container' encerrou. Veja os logs: -Action logs"
        }
        $logs = & wslc logs $Container 2>&1 | Out-String
        if ($logs -match $Pattern) { return $true }
        Start-Sleep -Seconds 3
    }
    return $false
}

# -----------------------------------------------------------------------------
# Arquivos de ambiente
# -----------------------------------------------------------------------------

# Grava texto UTF-8 SEM BOM e com LF.
# O wslc interpreta o BOM como parte do nome da primeira variavel
# (testado: vira "?OPEN_NOTEBOOK_..."), corrompendo o --env-file.
function Write-TextFileNoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Lines
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"))
}

# Le uma variavel de um arquivo .env (retorna $null se ausente ou vazia)
function Get-EnvValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Key
    )
    if (-not (Test-Path $Path)) { return $null }
    $content = [System.IO.File]::ReadAllText($Path)
    $m = [regex]::Match($content, "(?m)^\s*$([regex]::Escape($Key))=(.*)$")
    if (-not $m.Success) { return $null }
    $v = $m.Groups[1].Value.Trim()
    if (-not $v) { return $null }
    return $v
}

# Le todas as variaveis de um .env para um hashtable (ignora comentarios)
function Read-EnvFile {
    param([Parameter(Mandatory)][string]$Path)
    $map = @{}
    if (-not (Test-Path $Path)) { return $map }
    foreach ($raw in [System.IO.File]::ReadAllLines($Path)) {
        $line = $raw.Trim()
        if (-not $line -or $line.StartsWith('#')) { continue }
        $idx = $line.IndexOf('=')
        if ($idx -le 0) { continue }
        $k = $line.Substring(0, $idx).Trim()
        $v = $line.Substring($idx + 1).Trim()
        if ($k) { $map[$k] = $v }
    }
    return $map
}

# Gera segredo hex (mesmo formato de `openssl rand -hex 32`)
function New-RandomHex {
    param([int]$Bytes = 32)
    $buf = New-Object byte[] $Bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($buf)
    return ([Convert]::ToHexString($buf)).ToLower()
}

# -----------------------------------------------------------------------------
# Espaco em disco / caminhos
# -----------------------------------------------------------------------------
function Get-FreeSpaceGB {
    param([Parameter(Mandatory)][string]$Path)
    try {
        $root = [System.IO.Path]::GetPathRoot($Path)
        if (-not $root) { return $null }
        $letter = $root.Substring(0, 1)
        $d = Get-PSDrive -Name $letter -ErrorAction Stop
        if ($null -eq $d.Free) { return $null }
        return [math]::Round($d.Free / 1GB, 1)
    } catch {
        return $null
    }
}

# `wslc build` exige caminho Windows. Contexto UNC (\\wsl.localhost\... ou
# \\wsl$\...) falha com "Falha catastrofica / E_UNEXPECTED".
function Test-WindowsBuildPath {
    param([Parameter(Mandatory)][string]$Path)
    if ($Path.StartsWith('\\')) {
        return [pscustomobject]@{
            Ok     = $false
            Reason = "contexto de build UNC nao e suportado pelo wslc (E_UNEXPECTED). Use um caminho de disco do Windows (C:\... ou D:\...)."
        }
    }
    if ($Path -match '^/[a-zA-Z]/') {
        return [pscustomobject]@{
            Ok     = $false
            Reason = "caminho estilo WSL ($Path). Converta para Windows com: wsl wslpath -w '$Path'"
        }
    }
    if (-not (Test-Path $Path)) {
        return [pscustomobject]@{ Ok = $false; Reason = "caminho nao existe: $Path" }
    }
    return [pscustomobject]@{ Ok = $true; Reason = $null }
}

# -----------------------------------------------------------------------------
# Git: clonar ou atualizar o repositorio do projeto
# -----------------------------------------------------------------------------
function Invoke-GitSync {
    param(
        [Parameter(Mandatory)][string]$RepoUrl,
        [Parameter(Mandatory)][string]$DestPath,
        [switch]$NoUpdate
    )
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git nao encontrado no PATH. Instale o Git for Windows para clonar o repositorio."
    }

    $gitDir = Join-Path $DestPath ".git"
    if (Test-Path $gitDir) {
        if ($NoUpdate) {
            Write-Host "  Repositorio ja presente (atualizacao ignorada por -NoUpdate)." -ForegroundColor Gray
            return
        }
        Write-Host "  Atualizando repositorio existente..." -ForegroundColor Gray
        # --ff-only evita merge inesperado se o usuario editou o Dockerfile localmente
        $null = & git -C $DestPath pull --ff-only 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  AVISO: git pull falhou (alteracoes locais?). Seguindo com o codigo atual." -ForegroundColor Yellow
        }
        return
    }

    $parent = Split-Path -Parent $DestPath
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Write-Host "  Clonando $RepoUrl ..." -ForegroundColor Gray
    # --depth 1: so o necessario para buildar, economiza centenas de MB
    & git clone --depth 1 $RepoUrl $DestPath
    if ($LASTEXITCODE -ne 0) {
        throw "git clone falhou: $RepoUrl -> $DestPath"
    }
}

# -----------------------------------------------------------------------------
# Build local da imagem via wslc
# -----------------------------------------------------------------------------
function Invoke-WslcBuild {
    param(
        [Parameter(Mandatory)][string]$ContextPath,
        [Parameter(Mandatory)][string]$Tag,
        [string]$Target,
        [string[]]$BuildArgs = @(),
        [switch]$NoCache,
        [switch]$Pull
    )

    $check = Test-WindowsBuildPath -Path $ContextPath
    if (-not $check.Ok) { throw "Build inviavel: $($check.Reason)" }

    # NAO use $args: e variavel automatica do PowerShell
    $cmdArgs = @("build", "-t", $Tag)
    if ($Target) { $cmdArgs += @("--target", $Target) }
    foreach ($ba in $BuildArgs) {
        if ($ba) { $cmdArgs += @("--build-arg", $ba) }
    }
    if ($NoCache) { $cmdArgs += "--no-cache" }
    if ($Pull) { $cmdArgs += "--pull" }
    $cmdArgs += $ContextPath

    Write-Host "  wslc $($cmdArgs -join ' ')" -ForegroundColor DarkGray
    $output = & wslc @cmdArgs 2>&1
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        $detail = ($output | Out-String).Trim()
        throw "wslc build falhou (exit $code):`n$detail"
    }
    # Mostra apenas as ultimas linhas para nao inundar o log
    $tail = @($output | Where-Object { $_ } | Select-Object -Last 5)
    foreach ($l in $tail) { Write-Host "  $l" -ForegroundColor DarkGray }
    return $true
}

# Verifica se a imagem local existe
function Test-WslcImageExists {
    param([Parameter(Mandatory)][string]$Tag)
    $items = Get-WslcJsonObjects -ArgsList @("image", "list", "--format", "json")
    $repo, $tagName = $null, $null
    if ($Tag -match '^(.*):([^:/]+)$') { $repo = $Matches[1]; $tagName = $Matches[2] }
    else { $repo = $Tag; $tagName = "latest" }
    foreach ($i in $items) {
        $r = "$($i.Repository)"
        if ($r -eq $repo -and "$($i.Tag)" -eq $tagName) { return $true }
    }
    return $false
}

# -----------------------------------------------------------------------------
# Menu interativo
# -----------------------------------------------------------------------------
function Select-MenuAction {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][array]$Options,
        [string]$DefaultKey = "status",
        [switch]$NonInteractive
    )

    if ($NonInteractive) {
        Write-Host "Sem -Action e em modo nao-interativo. Use -Action $($Options[0].Key)." -ForegroundColor Red
        return $null
    }

    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ""
    foreach ($o in $Options) {
        Write-Host ("  [{0}] {1,-7} {2}" -f $o.Key, $o.Key, $o.Description)
    }
    Write-Host "  [0] sair"
    Write-Host ""

    $keys = @($Options | ForEach-Object { "$($_.Key)" })
    while ($true) {
        $answer = Read-Host "Escolha uma opcao [$DefaultKey]"
        if ($null -eq $answer -or $answer.Trim() -eq "") { return $DefaultKey }
        $a = $answer.Trim().ToLower()
        if ($a -eq "0" -or $a -eq "sair" -or $a -eq "q") { return $null }
        if ($keys -contains $a) { return $a }
        Write-Host "  Opcao invalida: $answer" -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------------
# Onde salvar o codigo-fonte
#
# Pergunta a cada execucao do `up`:
#   [1] pasta do script (padrao)  -> <scriptDir>\repo
#   [2] disco D: (USB!)           -> D:\wslc-src\<projeto>
#   [3] outro caminho
#
# D: pode ser um disco USB que nem sempre esta montado: se nao existir, nem
# aparece como opcao. O codigo-fonte e pequeno (dezenas de MB), entao ficar em
# C: e viavel; quem consome espaco e o storage.vhdx do wslc.
# -----------------------------------------------------------------------------
function Select-SourceLocation {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$ScriptDir,
        [string]$DefaultPath,
        [switch]$NonInteractive
    )

    $localPath = Join-Path $ScriptDir "repo"
    $dPath = "D:\wslc-src\$ProjectName"

    if ($DefaultPath) { $localPath = $DefaultPath }

    $localFree = Get-FreeSpaceGB -Path $ScriptDir
    $dExists = Test-Path "D:\"

    if ($NonInteractive) {
        if (-not $DefaultPath) { return $localPath }
        return $DefaultPath
    }

    Write-Host ""
    Write-Host "=== Onde salvar o codigo-fonte do ${ProjectName}? ===" -ForegroundColor Cyan
    Write-Host "  (o codigo e pequeno; o que ocupa espaco e o storage.vhdx do wslc)"
    Write-Host ""
    $localDesc = "Pasta do script   $localPath"
    if ($localFree -ne $null) { $localDesc += "  ($localFree GB livres)" }
    Write-Host "  [1] $localDesc"

    $haveD = $false
    if ($dExists) {
        $haveD = $true
        $dFree = Get-FreeSpaceGB -Path "D:\"
        $dDesc = "Disco D:          $dPath"
        if ($dFree -ne $null) { $dDesc += "  ($dFree GB livres)" }
        Write-Host "  [2] $dDesc"
        Write-Host "      ATENCAO: se D: for disco USB removivel, nao desconecte com containers rodando." -ForegroundColor DarkYellow
    } else {
        Write-Host "  [2] Disco D:          (indisponivel agora)" -ForegroundColor DarkGray
    }
    Write-Host "  [3] Outro caminho"
    Write-Host ""

    while ($true) {
        $answer = Read-Host "Escolha [1]"
        if ($null -eq $answer -or $answer.Trim() -eq "") { return $localPath }
        switch ($answer.Trim()) {
            "1" { return $localPath }
            "2" {
                if (-not $haveD) {
                    Write-Host "  D: nao esta disponivel neste momento." -ForegroundColor Yellow
                    continue
                }
                return $dPath
            }
            "3" {
                $custom = Read-Host "Caminho completo (ex.: E:\projetos\$ProjectName)"
                if (-not $custom -or -not $custom.Trim()) { continue }
                $custom = $custom.Trim().Trim('"')
                return $custom
            }
            default { Write-Host "  Opcao invalida." -ForegroundColor Yellow }
        }
    }
}

# -----------------------------------------------------------------------------
# Painel de acesso (URLs no inicio do status)
# -----------------------------------------------------------------------------
function Write-AccessPanel {
    param(
        [Parameter(Mandatory)][array]$Entries,
        [hashtable]$States = @{}
    )

    Write-Host "`n=== Acesso ===" -ForegroundColor Cyan
    foreach ($e in $Entries) {
        $isUp = $false
        if ($e.Container -and $States.ContainsKey($e.Container)) {
            $isUp = ($States[$e.Container] -eq "running")
            $tag = if ($isUp) { "[ativo]" } else { "[$($States[$e.Container])]" }
        } else {
            # Container nunca criado (ou removido)
            $tag = "[nao criado]"
        }
        $color = if ($isUp) { "Green" } else { "DarkGray" }
        Write-Host ("  {0,-9}: {1}" -f $e.Label, $e.Url) -ForegroundColor $color
        Write-Host ("             {0}" -f $tag) -ForegroundColor $color
    }
}

# -----------------------------------------------------------------------------
# Remocao de recursos (usada pelo delete)
# -----------------------------------------------------------------------------
function Remove-WslcContainers {
    param(
        [Parameter(Mandatory)][string[]]$Names,
        [switch]$PurgeAnonymousVolumes
    )
    foreach ($c in $Names) {
        $rmArgs = @("container", "rm", "-f")
        # -v remove os volumes ANONIMOS do container (ex.: /data, /logs do
        # SurrealDB). Sem isso eles se acumulam e inflam o storage.vhdx.
        if ($PurgeAnonymousVolumes) { $rmArgs += "-v" }
        $rmArgs += $c
        $null = Invoke-Wslc -ArgsList $rmArgs -IgnoreError -Quiet
    }
}

# -----------------------------------------------------------------------------
# Estado do projeto
#
# O `up` grava onde o codigo-fonte foi clonado. Assim o `delete` sabe
# exatamente o que remover, sem precisar que o usuario repita o -SourcePath.
# -----------------------------------------------------------------------------
function Get-StateFile {
    param([Parameter(Mandatory)][hashtable]$Project)
    return (Join-Path $Project.ScriptDir ".wslc-state.json")
}

function Save-ProjectState {
    param(
        [Parameter(Mandatory)][hashtable]$Project,
        [Parameter(Mandatory)][string]$SourcePath,
        [string]$EnvFile
    )
    $state = [pscustomobject]@{
        Project     = $Project.Name
        SourcePath  = $SourcePath
        EnvFile     = $EnvFile
        UpdatedAt   = (Get-Date).ToString("o")
    }
    Write-TextFileNoBom -Path (Get-StateFile -Project $Project) -Lines @(($state | ConvertTo-Json -Compress))
}

function Read-ProjectState {
    param([Parameter(Mandatory)][hashtable]$Project)
    $file = Get-StateFile -Project $Project
    if (-not (Test-Path $file)) { return $null }
    try {
        return ([System.IO.File]::ReadAllText($file) | ConvertFrom-Json)
    } catch {
        return $null
    }
}

# Diretorio de codigo-fonte conhecido: -SourcePath, senao o estado salvo,
# senao a pasta padrao <scriptDir>\repo.
function Get-OwnedSourceDir {
    param(
        [Parameter(Mandatory)][hashtable]$Project,
        [string]$SourcePath
    )
    if ($SourcePath) { return $SourcePath }
    $state = Read-ProjectState -Project $Project
    if ($state -and $state.SourcePath) { return $state.SourcePath }
    $default = Join-Path $Project.ScriptDir "repo"
    if (Test-Path $default) { return $default }
    return $null
}

# Arquivos de ambiente que este script pode ter criado
function Get-EnvFileCandidates {
    param(
        [Parameter(Mandatory)][hashtable]$Project,
        [string]$SourcePath
    )
    $files = @()
    $envName = if ($Project.EnvFileName) { $Project.EnvFileName } else { ".env.wslc" }
    $src = Get-OwnedSourceDir -Project $Project -SourcePath $SourcePath
    if ($src) { $files += (Join-Path $src $envName) }
    # Versao legada: .env.wslc na pasta do script (scripts antigos)
    $files += (Join-Path $Project.ScriptDir $envName)
    return $files | Select-Object -Unique
}

# -----------------------------------------------------------------------------
# Remocao TOTAL do storage do wslc
#
# Apaga o storage.vhdx inteiro: TODAS as imagens, volumes, containers e redes de
# TODOS os projetos, nao so deste. E a unica forma de devolver o espaco ao
# Windows sem compactar (o VHDX e esparso: remover arquivos de dentro nao
# reduz o tamanho do arquivo).
#
# O wslc recria o storage automaticamente no proximo comando, com ~0,5 GB.
# -----------------------------------------------------------------------------
function Remove-WslcStorage {
    param([switch]$Force)

    $storage = Get-WslcStorageInfo
    if (-not $storage.Available) {
        Write-Host "  storage.vhdx nao existe; nada a remover." -ForegroundColor DarkGray
        return $false
    }

    # Seguranca: nunca apagar com container rodando
    $running = @(Get-WslcJsonObjects -ArgsList @("container", "list", "--format", "json") |
        Where-Object { "$($_.State)" -eq "running" })
    if ($running.Count -gt 0) {
        Write-Host "  ABORTADO: ha $($running.Count) container(s) rodando." -ForegroundColor Red
        foreach ($r in $running) {
            Write-Host "    - $($r.Names)" -ForegroundColor DarkGray
        }
        Write-Host "  Pare-os primeiro: -Action stop" -ForegroundColor Yellow
        return $false
    }

    Write-Host "  ATENCAO: isto apaga TODAS as imagens, volumes e dados do wslc" -ForegroundColor Red
    Write-Host "  (todos os projetos, nao apenas este)." -ForegroundColor Red
    Write-Host "  Arquivo: $($storage.Path) ($($storage.SizeGB) GB)" -ForegroundColor Yellow

    if (-not $Force) {
        $ans = Read-Host "  Confirmar remocao total do storage? Digite SIM"
        if ($ans -ne 'SIM' -and $ans -ne 'sim') {
            Write-Host "  Cancelado." -ForegroundColor Yellow
            return $false
        }
    }

    # Encerra a sessao para liberar o lock do arquivo
    $null = Invoke-Wslc -ArgsList @("system", "session", "terminate") -IgnoreError -Quiet
    Start-Sleep -Seconds 5

    try {
        Remove-Item -Path $storage.Path -Force -ErrorAction Stop
    } catch {
        Write-Host "  Falha ao remover: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Feche o Docker Desktop e terminais WSL e tente de novo." -ForegroundColor DarkGray
        return $false
    }

    # Remove sobras da sessao (swap.vhdx, metadados)
    $sessionDir = Split-Path -Parent $storage.Path
    foreach ($leftover in @("swap.vhdx")) {
        $p = Join-Path $sessionDir $leftover
        if (Test-Path $p) { Remove-Item -Path $p -Force -ErrorAction SilentlyContinue }
    }

    $free = Get-FreeSpaceGB -Path $env:LOCALAPPDATA
    Write-Host "  Storage removido." -ForegroundColor Green
    if ($free -ne $null) {
        Write-Host "  Espaco livre no disco agora: $free GB" -ForegroundColor Green
    }
    Write-Host "  O wslc recria o storage (~0,5 GB) no proximo comando." -ForegroundColor DarkGray
    return $true
}

# -----------------------------------------------------------------------------
# Compactacao do storage.vhdx
#
# O VHDX da sessao wslc e esparso: remover containers/imagens/volumes NAO
# reduz o tamanho do arquivo no Windows. So a compactacao devolve espaco.
# Requer a sessao wslc parada (nenhum container rodando).
# -----------------------------------------------------------------------------
function Compress-WslcStorage {
    param([switch]$Force)

    $storage = Get-WslcStorageInfo
    if (-not $storage.Available) {
        Write-Host "  storage.vhdx nao encontrado; nada a compactar." -ForegroundColor DarkGray
        return
    }

    $running = @(Get-WslcJsonObjects -ArgsList @("container", "list", "--format", "json") |
        Where-Object { "$($_.State)" -eq "running" })
    if ($running.Count -gt 0) {
        Write-Host "  Nao compactado: ha $($running.Count) container(s) rodando." -ForegroundColor Yellow
        foreach ($r in $running) {
            Write-Host "    - $($r.Names) (pare com -Action stop)" -ForegroundColor DarkGray
        }
        Write-Host "  A compactacao exige a sessao wslc parada." -ForegroundColor DarkGray
        return
    }

    Write-Host "  Compactando $($storage.Path) ($($storage.SizeGB) GB)..." -ForegroundColor Gray
    $null = Invoke-Wslc -ArgsList @("system", "session", "terminate") -IgnoreError -Quiet
    Start-Sleep -Seconds 5

    $optimize = Get-Command Optimize-VHD -ErrorAction SilentlyContinue
    if ($optimize) {
        try {
            Optimize-VHD -Path $storage.Path -Mode Full -ErrorAction Stop
        } catch {
            Write-Host "  Falha ao compactar: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  Feche o Docker Desktop e qualquer terminal WSL e tente de novo." -ForegroundColor DarkGray
            return
        }
    } else {
        # Fallback sem o modulo Hyper-V: diskpart
        $script = @"
select vdisk file="$($storage.Path)"
attach vdisk readonly
compact vdisk
detach vdisk
"@
        $tmp = Join-Path $env:TEMP "wslc-compact-$([guid]::NewGuid().ToString('N')).txt"
        Set-Content -Path $tmp -Value $script -Encoding ASCII
        try {
            $out = & diskpart /s $tmp 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  diskpart falhou:" -ForegroundColor Red
                $out | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
                return
            }
        } finally {
            Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
        }
    }

    $after = Get-WslcStorageInfo
    Write-Host "  Compactado: $($storage.SizeGB) GB -> $($after.SizeGB) GB" -ForegroundColor Green
    $freed = [math]::Round($storage.SizeGB - $after.SizeGB, 2)
    if ($freed -gt 0) {
        Write-Host "  Espaco devolvido ao Windows: $freed GB" -ForegroundColor Green
    }
}

# -----------------------------------------------------------------------------
# Orquestrador comum
#
# Garante que os tres projetos tenham EXATAMENTE a mesma estrutura de acoes,
# mensagens, logs e convencao de nomes. Cada script de projeto so declara:
#   - metadados (nome, titulo, repo, portas)
#   - o scriptblock PrepareEnv   (gera/valida o arquivo de ambiente)
#   - o scriptblock RunContainers (comandos `wslc run` especificos)
#   - as entradas do painel de acesso (URLs)
#
# Acoes: up | stop | status | logs | delete
# Sem -Action: abre o MENU interativo (nao executa nada por conta propria).
# -----------------------------------------------------------------------------
function Invoke-ProjectSetup {
    param(
        [Parameter(Mandatory)][hashtable]$Project,

        # Vazio = abre o menu. E o comportamento padrao: rodar o script sem
        # argumentos NUNCA deve subir container por acidente.
        [string]$Action = "",

        [ValidateSet("volume", "bind")]
        [string]$Storage = "volume",

        [int]$WebPort = 0,
        [int]$ApiPort = 0,
        [int]$DbPort = 0,
        [switch]$ExposeDb,

        [switch]$Force,
        [switch]$NonInteractive,
        [switch]$NoBuild,
        [switch]$Rebuild,
        [switch]$KeepImages,
        [string]$SourcePath = "",
        # Remove o storage.vhdx inteiro no `delete` (libera todo o espaco em
        # disco, mas apaga imagens/volumes de TODOS os projetos do wslc)
        [switch]$RemoveStorage
    )

    # --- Metadados -----------------------------------------------------------
    $name        = $Project.Name
    $title       = $Project.Title
    $netName     = $Project.Network
    $containers  = @($Project.Containers)
    $volumes     = @($Project.Volumes)
    $repoUrl     = $Project.RepoUrl
    $buildTarget = $Project.BuildTarget
    $envFileName = $Project.EnvFileName

    if ($WebPort -le 0) { $WebPort = $Project.WebPort }
    if ($ApiPort -le 0) { $ApiPort = $Project.ApiPort }
    if ($DbPort -le 0)  { $DbPort  = $Project.DbPort }

    # Tag local: deixa claro no `image list` que a imagem foi construida aqui,
    # e nao baixada do registry.
    $localImage = "$name-web:local"

    # --- Log -----------------------------------------------------------------
    $logsDir = Join-Path $Project.ScriptDir "logs"
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFile = Join-Path $logsDir "setup-wslc-$timestamp.log"
    Start-Transcript -Path $logFile -Append | Out-Null

    Write-Host "=== [$title / wslc] ===" -ForegroundColor Cyan
    Write-Host "Log: $logFile"

    $null = Assert-Wslc
    $storageInfo = Get-WslcStorageInfo
    Write-StorageSummary -Storage $storageInfo

    # --- Menu (padrao quando -Action nao foi passado) ------------------------
    if (-not $Action) {
        $menuOptions = @(
            [pscustomobject]@{ Key = "up";     Description = "sobe (ou recria) os containers" }
            [pscustomobject]@{ Key = "stop";   Description = "para os containers (dados preservados)" }
            [pscustomobject]@{ Key = "status"; Description = "containers, imagens, volumes, portas e onde os dados ficam" }
            [pscustomobject]@{ Key = "logs";   Description = "ultimas linhas de log de cada container" }
            [pscustomobject]@{ Key = "delete"; Description = "remove containers, volumes, rede e imagens" }
        )
        $Action = Select-MenuAction -Title "=== $title : o que deseja fazer? ===" `
            -Options $menuOptions -DefaultKey "status" -NonInteractive:$NonInteractive
        if (-not $Action) {
            Write-Host "Saindo." -ForegroundColor DarkGray
            Stop-Transcript | Out-Null
            return
        }
        Write-Host ""
    }

    $Action = $Action.Trim().ToLower()
    if (@("up", "stop", "status", "logs", "delete") -notcontains $Action) {
        Stop-Transcript | Out-Null
        throw "Acao invalida: '$Action'. Use up, stop, status, logs ou delete."
    }

    Write-Host "Acao: $Action$(if ($Action -eq 'up') { " | Armazenamento: $Storage" })"

    $ctx = [pscustomobject]@{
        Project     = $Project
        NetName     = $netName
        Containers  = $containers
        Volumes     = $volumes
        LocalImage  = $localImage
        WebPort     = $WebPort
        ApiPort     = $ApiPort
        DbPort      = $DbPort
        ExposeDb    = [bool]$ExposeDb
        Storage     = $Storage
        SourcePath  = $null
        EnvFile     = $null
        StorageInfo = $storageInfo
    }

    switch ($Action) {

        # =====================================================================
        "status" {
            $states = Get-ContainerStates

            # URLs PRIMEIRO: e o que o usuario quer ver ao rodar status
            Write-AccessPanel -Entries @($Project.Access) -States $states

            Write-Host "`n=== Containers do projeto ===" -ForegroundColor Cyan
            $mine = @($containers | ForEach-Object { $_ })
            $found = $false
            foreach ($c in $mine) {
                if ($states.ContainsKey($c)) {
                    $found = $true
                    $color = if ($states[$c] -eq "running") { "Green" } else { "DarkGray" }
                    Write-Host ("  {0,-26} {1}" -f $c, $states[$c]) -ForegroundColor $color
                } else {
                    Write-Host ("  {0,-26} {1}" -f $c, "nao existe") -ForegroundColor DarkGray
                }
            }
            if (-not $found) {
                Write-Host "  (nenhum container criado ainda)" -ForegroundColor DarkGray
            }

            Write-Host "`n=== Portas ===" -ForegroundColor Cyan
            $portEntries = @()
            foreach ($a in @($Project.Access)) {
                if ($a.Port) { $portEntries += $a.Port }
            }
            if ($portEntries.Count -eq 0) { $portEntries = @($WebPort) }
            foreach ($p in ($portEntries | Select-Object -Unique)) {
                $owner = Get-PortOwner -Port $p
                if ($owner) {
                    Write-Host "  $p -> $($owner.Details)"
                } else {
                    Write-Host "  $p -> livre" -ForegroundColor DarkGray
                }
            }

            Write-Host "`n=== Imagens ===" -ForegroundColor Cyan
            $imgItems = Get-WslcJsonObjects -ArgsList @("image", "list", "--format", "json")
            $mineImgs = @($imgItems | Where-Object {
                "$($_.Repository)" -like "$name-*" -or "$($_.Repository)" -eq $Project.UpstreamImage
            })
            if ($mineImgs.Count -eq 0) {
                Write-Host "  (nenhuma imagem do projeto)" -ForegroundColor DarkGray
            } else {
                foreach ($i in $mineImgs) {
                    Write-Host ("  {0}:{1}  {2}  {3}" -f $i.Repository, $i.Tag, $i.Size, $i.CreatedSince)
                }
            }

            Write-Host "`n=== Volumes do projeto ===" -ForegroundColor Cyan
            $volItems = Get-WslcJsonObjects -ArgsList @("volume", "list", "--format", "json")
            foreach ($v in $volumes) {
                $exists = @($volItems | Where-Object { "$($_.Name)" -eq $v }).Count -gt 0
                if ($exists) {
                    Write-Host "  $v" -ForegroundColor Green
                } else {
                    Write-Host "  $v (nao existe)" -ForegroundColor DarkGray
                }
            }

            Write-Host "`n=== Rede ===" -ForegroundColor Cyan
            $netItems = Get-WslcJsonObjects -ArgsList @("network", "list", "--format", "json")
            $hasNet = @($netItems | Where-Object { "$($_.Name)" -eq $netName }).Count -gt 0
            if ($hasNet) { Write-Host "  $netName" -ForegroundColor Green }
            else { Write-Host "  $netName (nao existe)" -ForegroundColor DarkGray }

            Write-Host "`n=== Onde os dados ficam ===" -ForegroundColor Cyan
            if ($storageInfo.Available) {
                Write-Host "  Disco virtual do wslc: $($storageInfo.Path)"
                Write-Host "  Tamanho: $($storageInfo.SizeGB) GB"
                if ($storageInfo.ConfiguredAt) {
                    Write-Host "  Configurado em settings.yaml: session.storagePath = $($storageInfo.ConfiguredAt)"
                } else {
                    Write-Host "  Configurado em settings.yaml: (padrao %LOCALAPPDATA%)"
                }
                Write-Host "  Volumes nomeados ficam em /var/lib/docker/volumes/<nome>/_data"
                Write-Host "  dentro desse disco (visivel so pela sessao wslc, nao pela distro Ubuntu)."
            } else {
                Write-Host "  Ainda nao criado. Sera em: $($storageInfo.Root)"
            }
            Write-Host "  Codigo-fonte: veja -Action up (o script pergunta onde salvar)."
        }

        # =====================================================================
        "logs" {
            foreach ($c in $containers) {
                Write-Host "`n=== $c ===" -ForegroundColor Cyan
                Show-Wslc @("logs", "--tail", "80", $c)
            }
        }

        # =====================================================================
        "stop" {
            Write-Host "Parando containers..." -ForegroundColor Yellow
            foreach ($c in $containers) {
                $null = Invoke-Wslc -ArgsList @("container", "stop", $c) -IgnoreError -Quiet
            }
            $states = Get-ContainerStates
            $still = @($containers | Where-Object { $states.ContainsKey($_) -and $states[$_] -eq "running" })
            if ($still.Count -eq 0) {
                Write-Host "Containers parados." -ForegroundColor Green
            } else {
                Write-Host "Ainda rodando: $($still -join ', ')" -ForegroundColor Yellow
            }
            Write-Host "Dados preservados. Use -Action up para retomar."
            $after = Get-WslcStorageInfo
            if ($after.Available) {
                Write-Host "Storage do wslc: $($after.SizeGB) GB em $($after.Path)" -ForegroundColor DarkGray
            }
        }

        # =====================================================================
        "delete" {
            # Remove TUDO: containers, volumes (nomeados e anonimos), rede,
            # imagens, arquivo de ambiente e, se estiver dentro da pasta do
            # script, o codigo-fonte clonado. Sem instrucoes manuais no final.
            $before = Get-WslcStorageInfo
            Write-Host "`n=== Removendo $title ===" -ForegroundColor Cyan
            if ($before.Available) {
                Write-Host "Storage do wslc antes: $($before.SizeGB) GB" -ForegroundColor DarkGray
            }

            Write-Host "`n[1/6] Containers (com volumes anonimos)..." -ForegroundColor Yellow
            # -v remove os volumes ANONIMOS de cada container (ex.: /data e
            # /logs do SurrealDB). Sem isso eles se acumulam e inflam o
            # storage.vhdx -- foi a causa dos 22 volumes orfaos encontrados.
            Remove-WslcContainers -Names $containers -PurgeAnonymousVolumes

            Write-Host "[2/6] Volumes de dados..." -ForegroundColor Yellow
            foreach ($v in $volumes) {
                $null = Invoke-Wslc -ArgsList @("volume", "rm", "-f", $v) -IgnoreError -Quiet
            }
            # Anonimos orfaos de execucoes anteriores
            $null = Invoke-Wslc -ArgsList @("volume", "prune", "-f") -IgnoreError -Quiet

            Write-Host "[3/6] Rede $netName..." -ForegroundColor Yellow
            $null = Invoke-Wslc -ArgsList @("network", "rm", $netName) -IgnoreError -Quiet

            Write-Host "[4/6] Imagens..." -ForegroundColor Yellow
            if ($KeepImages) {
                Write-Host "  preservadas (-KeepImages)" -ForegroundColor DarkGray
            } else {
                $null = Invoke-Wslc -ArgsList @("image", "rm", "-f", $localImage) -IgnoreError -Quiet
                if ($Project.UpstreamImage) {
                    $null = Invoke-Wslc -ArgsList @("image", "rm", "-f", $Project.UpstreamImage) -IgnoreError -Quiet
                }
                foreach ($extra in @($Project.ExtraImages)) {
                    if ($extra) {
                        $null = Invoke-Wslc -ArgsList @("image", "rm", "-f", $extra) -IgnoreError -Quiet
                    }
                }
                # Camadas pendentes que sobraram dos builds
                $null = Invoke-Wslc -ArgsList @("image", "prune", "-f") -IgnoreError -Quiet
            }

            Write-Host "[5/6] Arquivo de ambiente..." -ForegroundColor Yellow
            $removedEnv = @()
            foreach ($candidate in (Get-EnvFileCandidates -Project $Project -SourcePath $SourcePath)) {
                if ($candidate -and (Test-Path $candidate)) {
                    Remove-Item -Path $candidate -Force -ErrorAction SilentlyContinue
                    if (-not (Test-Path $candidate)) { $removedEnv += $candidate }
                }
            }
            if ($removedEnv.Count -eq 0) {
                Write-Host "  (nenhum encontrado)" -ForegroundColor DarkGray
            } else {
                foreach ($e in $removedEnv) { Write-Host "  removido: $e" -ForegroundColor Gray }
            }

            Write-Host "[6/6] Codigo-fonte clonado..." -ForegroundColor Yellow
            $removedSrc = $null
            $srcDir = Get-OwnedSourceDir -Project $Project -SourcePath $SourcePath
            if ($srcDir -and (Test-Path $srcDir)) {
                # So remove se for um clone gerenciado por este script
                # (pasta "repo" dentro do projeto, ou caminho passado em
                # -SourcePath). Uma pasta arbitraria do usuario nunca e tocada.
                $managed = $false
                $expected = Join-Path $Project.ScriptDir "repo"
                if ($srcDir -eq $expected) { $managed = $true }
                if ($SourcePath -and $srcDir -eq $SourcePath) { $managed = $true }
                if ($managed) {
                    Remove-Item -Path $srcDir -Recurse -Force -ErrorAction SilentlyContinue
                    if (-not (Test-Path $srcDir)) { $removedSrc = $srcDir }
                } else {
                    Write-Host "  preservado (nao foi criado por este script): $srcDir" -ForegroundColor DarkGray
                }
            }
            if ($removedSrc) { Write-Host "  removido: $removedSrc" -ForegroundColor Gray }
            elseif (-not $srcDir) { Write-Host "  (nenhum)" -ForegroundColor DarkGray }

            # Diretorio de bind mount, se existir (criado por este script)
            $bindDir = Join-Path $Project.ScriptDir "wslc-data"
            if (Test-Path $bindDir) {
                Remove-Item -Path $bindDir -Recurse -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $bindDir)) {
                    Write-Host "  removido (bind): $bindDir" -ForegroundColor Gray
                }
            }

            # Arquivo de estado: sem isso sobra um .wslc-state.json apontando
            # para caminhos que nao existem mais.
            $stateFile = Get-StateFile -Project $Project
            if (Test-Path $stateFile) {
                Remove-Item -Path $stateFile -Force -ErrorAction SilentlyContinue
            }

            # --- Resultado ---------------------------------------------------
            $after = Get-WslcStorageInfo
            Write-Host "`n=== Resultado ===" -ForegroundColor Cyan
            if ($before.Available -and $after.Available) {
                Write-Host "  storage.vhdx: $($after.Path)"
                Write-Host "  Antes : $($before.SizeGB) GB"
                Write-Host "  Depois: $($after.SizeGB) GB"
                $delta = [math]::Round($before.SizeGB - $after.SizeGB, 2)
                if ($delta -gt 0) {
                    Write-Host "  Liberado: $delta GB" -ForegroundColor Green
                } else {
                    # O VHDX e esparso: remover arquivos de dentro nao reduz o
                    # tamanho do arquivo no Windows.
                    Write-Host "  O arquivo nao encolheu: o storage.vhdx e esparso." -ForegroundColor DarkGray
                }
            } elseif ($after.Available) {
                Write-Host "  storage.vhdx: $($after.Path) ($($after.SizeGB) GB)"
            }

            Write-Host "`nRecursos do projeto removidos." -ForegroundColor Green

            # O storage.vhdx NAO encolhe ao remover recursos. Para devolver o
            # espaco ao Windows ha duas opcoes: apagar o arquivo inteiro
            # (libera tudo de uma vez) ou compactar. Como o arquivo guarda os
            # dados de TODOS os projetos, perguntamos antes.
            if ($after.Available -and $after.SizeGB -gt 0.2) {
                Write-Host ""
                Write-Host "O storage.vhdx tem $($after.SizeGB) GB em disco e nao encolhe sozinho." -ForegroundColor Yellow
                Write-Host "Para devolver esse espaco ao Windows e preciso apagar o arquivo," -ForegroundColor Yellow
                Write-Host "o que remove imagens/volumes de TODOS os projetos do wslc." -ForegroundColor Yellow

                $doRemove = $Force -or $RemoveStorage
                if (-not $Force -and -not $NonInteractive -and -not $RemoveStorage) {
                    $ans = Read-Host "Apagar o storage.vhdx inteiro agora? Digite SIM"
                    $doRemove = ($ans -eq 'SIM' -or $ans -eq 'sim')
                }
                if ($doRemove) {
                    $null = Remove-WslcStorage -Force
                } else {
                    Write-Host "  Mantido. Para remover depois:" -ForegroundColor DarkGray
                    Write-Host "    .\setup-<projeto>.ps1 -Action delete -Force" -ForegroundColor DarkGray
                }
            }
        }

        # =====================================================================
        "up" {
            # 1. Onde fica o codigo-fonte ------------------------------------
            Write-Host "`n[1/7] Local do codigo-fonte..." -ForegroundColor Cyan
            $src = Select-SourceLocation -ProjectName $name `
                -ScriptDir $Project.ScriptDir `
                -DefaultPath $(if ($SourcePath) { $SourcePath } elseif ($Project.SourcePath) { $Project.SourcePath } else { "" }) `
                -NonInteractive:$NonInteractive
            $ctx.SourcePath = $src
            Write-Host "  $src"

            $free = Get-FreeSpaceGB -Path $src
            if ($free -ne $null -and $free -lt 3) {
                Write-Host "  AVISO: apenas $free GB livres nesse disco. O build pode falhar." -ForegroundColor Yellow
            }

            # 2. Repositorio --------------------------------------------------
            Write-Host "[2/7] Repositorio..." -ForegroundColor Cyan
            Invoke-GitSync -RepoUrl $repoUrl -DestPath $src -NoUpdate:($NonInteractive -and (Test-Path $src))
            $dockerfile = Join-Path $src "Dockerfile"
            if (-not (Test-Path $dockerfile)) {
                throw "Dockerfile nao encontrado em $src. O repositorio foi clonado corretamente?"
            }
            Write-Host "  Dockerfile: $dockerfile" -ForegroundColor Gray

            # 3. Build da imagem ----------------------------------------------
            Write-Host "[3/7] Imagem local..." -ForegroundColor Cyan
            $needBuild = -not $NoBuild
            if ($NoBuild) {
                if (Test-WslcImageExists -Tag $localImage) {
                    Write-Host "  Usando imagem existente: $localImage (-NoBuild)" -ForegroundColor Gray
                } else {
                    Write-Host "  -NoBuild mas a imagem $localImage nao existe. Construindo." -ForegroundColor Yellow
                    $needBuild = $true
                }
            }
            if ($needBuild) {
                Write-Host "  Construindo $localImage (pode levar varios minutos)..." -ForegroundColor Gray
                $buildArgs = @()
                if ($Project.BuildArgs) { $buildArgs = @($Project.BuildArgs) }
                $null = Invoke-WslcBuild -ContextPath $src -Tag $localImage `
                    -Target $buildTarget -BuildArgs $buildArgs -NoCache:$Rebuild
                Write-Host "  Imagem pronta: $localImage" -ForegroundColor Green
            }

            # 4. Rede ---------------------------------------------------------
            Write-Host "[4/7] Garantindo rede $netName..." -ForegroundColor Cyan
            $null = Invoke-Wslc -ArgsList @("network", "create", $netName) -IgnoreError -Quiet

            # 5. Ambiente -----------------------------------------------------
            Write-Host "[5/7] Preparando ambiente..." -ForegroundColor Cyan
            $envPath = & $Project.PrepareEnv $src $ctx
            $ctx.EnvFile = $envPath
            if ($envPath) { Write-Host "  $envPath" -ForegroundColor Gray }

            # 6. Recriar containers -------------------------------------------
            Write-Host "[6/7] Removendo containers antigos (dados preservados)..." -ForegroundColor Cyan
            Remove-WslcContainers -Names $containers

            # Portas checadas DEPOIS de remover: o wslc publica via proxy
            # dllhost.exe, entao os proprios containers deste script apareceriam
            # como conflito e o `up` nunca funcionaria duas vezes seguidas.
            Start-Sleep -Seconds 2
            $portsToCheck = @($WebPort)
            if ($ApiPort -gt 0) { $portsToCheck += $ApiPort }
            if ($ExposeDb) { $portsToCheck += $DbPort }
            Assert-PortFree -Ports $portsToCheck -Interactive:(-not $Force -and -not $NonInteractive)

            # 7. Subir ---------------------------------------------------------
            Write-Host "[7/7] Subindo containers..." -ForegroundColor Cyan
            & $Project.RunContainers $ctx

            # --- Resumo ------------------------------------------------------
            $states = Get-ContainerStates

            # Guarda onde o codigo foi clonado, para o `delete` saber o que
            # remover sem exigir que o usuario repita -SourcePath.
            Save-ProjectState -Project $Project -SourcePath $src -EnvFile $envPath

            Write-Host "`n=== $title iniciado via wslc ===" -ForegroundColor Green
            Write-AccessPanel -Entries @($Project.Access) -States $states
            Write-Host "`nContainers: $($containers -join ', ')"
            Write-Host "Imagem    : $localImage (construida localmente a partir de $src)"
            Write-Host "Codigo    : $src"
            if ($Storage -eq "bind") {
                Write-Host "Dados     : $($Project.BindDataDir)"
            } else {
                Write-Host "Dados     : volumes wslc: $($volumes -join ', ')"
                if ($storageInfo.Available) {
                    Write-Host "            dentro de $($storageInfo.Path) ($($storageInfo.SizeGB) GB)"
                    Write-Host "            NAO fica no ext4.vhdx do Ubuntu."
                }
            }
            if ($Project.NextSteps) {
                Write-Host "`n$($Project.NextSteps)"
            }
            Write-Host "`nLogs: -Action logs | Status: -Action status | Parar: -Action stop"
        }
    }

    Stop-Transcript | Out-Null
}
