#Requires -Version 7.0
# =============================================================================
# wslc-clean.ps1 - limpeza do runtime wslc (imagens, volumes, redes, VHDX)
#
# O storage.vhdx da sessao wslc so cresce: ele NAO encolhe sozinho quando um
# container ou volume e removido. Este script mostra o que da para liberar e,
# so com -Execute, executa de fato.
#
#   preview  (padrao)  apenas lista. NADA e alterado.
#   execute            executa a limpeza.
#
# O wslc NAO tem --dry-run em nenhum comando de prune, por isso o preview e
# implementado aqui: listamos os recursos via JSON, calculamos o que e orfao e
# mostramos. A execucao usa os comandos nativos.
#
# Exemplos:
#   .\wslc-clean.ps1                       # preview
#   .\wslc-clean.ps1 -Action execute       # limpa orfaos
#   .\wslc-clean.ps1 -Action execute -Compact
#   .\wslc-clean.ps1 -Action execute -IncludeInUse    # perigoso
# =============================================================================
[CmdletBinding()]
param(
    [ValidateSet("preview", "execute")]
    [string]$Action = "preview",

    # Inclui imagens e volumes EM USO por containers. Perigoso: os containers
    # passam a referenciar imagens/volumes que nao existem mais.
    [switch]$IncludeInUse,

    # Compacta o storage.vhdx com Optimize-VHD. Encolhe o arquivo em disco
    # (recupera espaco no Windows), mas exige a sessao wslc parada.
    [switch]$Compact,

    # Nao pergunta nada
    [switch]$Force,

    # Somente relatorio, sem tocar em nada (equivalente a preview)
    [switch]$Report
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$common = Join-Path $scriptDir "wslc-common.ps1"
if (-not (Test-Path $common)) {
    throw "Biblioteca nao encontrada: $common"
}
. $common

$logsDir = Join-Path $scriptDir "logs"
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir "wslc-clean-$timestamp.log"
Start-Transcript -Path $logFile -Append | Out-Null

if ($Report) { $Action = "preview" }

Write-Host "=== [wslc-clean] ===" -ForegroundColor Cyan
Write-Host "Log: $logFile"
Write-Host "Acao: $Action$(if ($IncludeInUse) { ' | INCLUINDO RECURSOS EM USO' })"
$null = Assert-Wslc

$storageBefore = Get-WslcStorageInfo
Write-StorageSummary -Storage $storageBefore

$settings = Get-WslcSettings
if ($settings.Exists -and -not $settings.StoragePath) {
    Write-Host "  storagePath nao configurado (usa %LOCALAPPDATA%)." -ForegroundColor DarkGray
}

# -----------------------------------------------------------------------------
# Levantamento do estado atual
# -----------------------------------------------------------------------------
$containers = Get-WslcJsonObjects -ArgsList @("container", "list", "--all", "--format", "json")
$images     = Get-WslcJsonObjects -ArgsList @("image", "list", "--format", "json")
$volumes    = Get-WslcJsonObjects -ArgsList @("volume", "list", "--format", "json")
$networks   = Get-WslcJsonObjects -ArgsList @("network", "list", "--format", "json")

# Volumes realmente anexados a algum container (nomeados e anonimos).
# `container list` trunca a lista, entao usamos inspect por container.
$usedVolumes = New-Object System.Collections.Generic.HashSet[string]
foreach ($c in $containers) {
    $name = "$($c.Names)"
    if (-not $name) { continue }
    foreach ($v in (Get-ContainerVolumes -Name $name)) {
        if ($v) { [void]$usedVolumes.Add($v) }
    }
}

# Imagens em uso (o campo Containers do image list nem sempre reflete o real)
$usedImages = New-Object System.Collections.Generic.HashSet[string]
foreach ($c in $containers) {
    if ($c.Image) { [void]$usedImages.Add("$($c.Image)") }
}

# Redes embutidas que nunca devem ser removidas
$builtinNetworks = @("bridge", "host", "none")

# -----------------------------------------------------------------------------
# Classificacao
# -----------------------------------------------------------------------------
$candidateContainers = @($containers | Where-Object { "$($_.State)" -ne "running" })

$candidateImages = @()
foreach ($i in $images) {
    $repo = "$($i.Repository)"
    $tag  = "$($i.Tag)"
    if (-not $repo -or $repo -eq "<none>") { continue }
    $fullName = "${repo}:${tag}"
    $inUse = $usedImages.Contains($fullName) -or $usedImages.Contains($repo)
    if ($inUse -and -not $IncludeInUse) { continue }
    $candidateImages += [pscustomobject]@{
        Name     = $fullName
        Id       = "$($i.ID)"
        Size     = "$($i.Size)"
        InUse    = $inUse
        Created  = "$($i.CreatedSince)"
    }
}

$candidateVolumes = @()
foreach ($v in $volumes) {
    $name = "$($v.Name)"
    if (-not $name) { continue }
    $inUse = $usedVolumes.Contains($name)
    if ($inUse -and -not $IncludeInUse) { continue }
    # Volume anonimo: label com.docker.volume.anonymous (nome e um hash hex)
    $anonymous = ("$($v.Labels)" -match 'com\.docker\.volume\.anonymous') -or ($name -match '^[0-9a-f]{32,}$')
    $candidateVolumes += [pscustomobject]@{
        Name      = $name
        InUse     = $inUse
        Anonymous = $anonymous
        Mount     = "$($v.Mountpoint)"
    }
}

$candidateNetworks = @()
foreach ($n in $networks) {
    $name = "$($n.Name)"
    if (-not $name) { continue }
    if ($builtinNetworks -contains $name) { continue }
    $inUse = @($containers | Where-Object { "$($_.Networks)" -match [regex]::Escape($name) }).Count -gt 0
    if ($inUse -and -not $IncludeInUse) { continue }
    $candidateNetworks += [pscustomobject]@{ Name = $name; InUse = $inUse }
}

# -----------------------------------------------------------------------------
# Relatorio
# -----------------------------------------------------------------------------
Write-Host "`n=== Containers parados ($($candidateContainers.Count)) ===" -ForegroundColor Cyan
if ($candidateContainers.Count -eq 0) {
    Write-Host "  (nenhum)" -ForegroundColor DarkGray
} else {
    foreach ($c in $candidateContainers) {
        Write-Host "  $($c.Names)  [$($c.State)]  imagem $($c.Image)"
    }
}

Write-Host "`n=== Imagens removiveis ($($candidateImages.Count)) ===" -ForegroundColor Cyan
if ($candidateImages.Count -eq 0) {
    Write-Host "  (nenhuma)" -ForegroundColor DarkGray
} else {
    $totalImg = 0.0
    foreach ($i in $candidateImages) {
        $flag = if ($i.InUse) { " [EM USO]" } else { "" }
        Write-Host ("  {0,-38} {1,8}  {2}{3}" -f $i.Name, $i.Size, $i.Created, $flag)
        if ($i.Size -match '^([\d.]+)\s*(GB|MB|kB|B)$') {
            $n = [double]$Matches[1]
            switch ($Matches[2]) {
                "GB" { $totalImg += $n }
                "MB" { $totalImg += $n / 1024 }
                "kB" { $totalImg += $n / 1024 / 1024 }
            }
        }
    }
    Write-Host ("  Total aproximado: {0:N2} GB" -f $totalImg) -ForegroundColor Yellow
}

Write-Host "`n=== Volumes removiveis ($($candidateVolumes.Count)) ===" -ForegroundColor Cyan
if ($candidateVolumes.Count -eq 0) {
    Write-Host "  (nenhum)" -ForegroundColor DarkGray
} else {
    foreach ($v in $candidateVolumes) {
        $kind = if ($v.Anonymous) { "anonimo" } else { "nomeado" }
        $flag = if ($v.InUse) { " [EM USO]" } else { "" }
        Write-Host ("  {0,-70} {1}{2}" -f $v.Name, $kind, $flag)
    }
}

Write-Host "`n=== Redes removiveis ($($candidateNetworks.Count)) ===" -ForegroundColor Cyan
if ($candidateNetworks.Count -eq 0) {
    Write-Host "  (nenhuma)" -ForegroundColor DarkGray
} else {
    foreach ($n in $candidateNetworks) {
        $flag = if ($n.InUse) { " [EM USO]" } else { "" }
        Write-Host "  $($n.Name)$flag"
    }
}

Write-Host "`n=== Storage ===" -ForegroundColor Cyan
if ($storageBefore.Available) {
    Write-Host "  storage.vhdx: $($storageBefore.Path)"
    Write-Host "  Tamanho atual: $($storageBefore.SizeGB) GB"
    Write-Host "  (o arquivo NAO encolhe sozinho; use -Compact para recuperar espaco no Windows)"
} else {
    Write-Host "  ainda nao criado"
}

if ($Compact) {
    $optimize = Get-Command Optimize-VHD -ErrorAction SilentlyContinue
    if ($optimize) {
        Write-Host "  Compactacao: Optimize-VHD disponivel" -ForegroundColor Green
    } else {
        Write-Host "  Compactacao: Optimize-VHD NAO disponivel (modulo Hyper-V ausente)" -ForegroundColor Yellow
        Write-Host "  Alternativa: diskpart (ver instrucoes no fim)" -ForegroundColor DarkGray
    }
}

# -----------------------------------------------------------------------------
# Execucao
# -----------------------------------------------------------------------------
if ($Action -eq "preview") {
    Write-Host "`n--- PREVIEW: nada foi alterado ---" -ForegroundColor Yellow
    Write-Host "Para executar:  .\wslc-clean.ps1 -Action execute"
    if (-not $IncludeInUse) {
        Write-Host "Para incluir recursos EM USO (perigoso): -IncludeInUse" -ForegroundColor DarkYellow
    }
    if (-not $Compact) {
        Write-Host "Para compactar o storage.vhdx: -Compact" -ForegroundColor DarkGray
    }
    Stop-Transcript | Out-Null
    return
}

# --- execute -----------------------------------------------------------------
$total = $candidateContainers.Count + $candidateImages.Count + $candidateVolumes.Count + $candidateNetworks.Count
if ($total -eq 0 -and -not $Compact) {
    Write-Host "`nNada para limpar." -ForegroundColor Green
    Stop-Transcript | Out-Null
    return
}

if (-not $Force) {
    Write-Host ""
    $answer = Read-Host "Executar a limpeza acima? [s/N]"
    if ($answer -ne 's' -and $answer -ne 'S') {
        Write-Host "Cancelado. Nada foi alterado." -ForegroundColor Yellow
        Stop-Transcript | Out-Null
        return
    }
}

if ($candidateContainers.Count -gt 0) {
    Write-Host "`nRemovendo containers parados..." -ForegroundColor Yellow
    foreach ($c in $candidateContainers) {
        $null = Invoke-Wslc -ArgsList @("container", "rm", "-f", "-v", "$($c.Names)") -IgnoreError -Quiet
        Write-Host "  removido: $($c.Names)" -ForegroundColor Gray
    }
}

if ($candidateImages.Count -gt 0) {
    Write-Host "`nRemovendo imagens..." -ForegroundColor Yellow
    foreach ($i in $candidateImages) {
        $null = Invoke-Wslc -ArgsList @("image", "rm", "-f", $i.Name) -IgnoreError -Quiet
        Write-Host "  removida: $($i.Name)" -ForegroundColor Gray
    }
}

if ($candidateVolumes.Count -gt 0) {
    Write-Host "`nRemovendo volumes..." -ForegroundColor Yellow
    foreach ($v in $candidateVolumes) {
        $null = Invoke-Wslc -ArgsList @("volume", "rm", "-f", $v.Name) -IgnoreError -Quiet
        Write-Host "  removido: $($v.Name)" -ForegroundColor Gray
    }
}

if ($candidateNetworks.Count -gt 0) {
    Write-Host "`nRemovendo redes..." -ForegroundColor Yellow
    foreach ($n in $candidateNetworks) {
        $null = Invoke-Wslc -ArgsList @("network", "rm", $n.Name) -IgnoreError -Quiet
        Write-Host "  removida: $($n.Name)" -ForegroundColor Gray
    }
}

# Prune final: pega o que sobrou (camadas pendentes, anonimos orfaos)
Write-Host "`nPrune final..." -ForegroundColor Yellow
$null = Invoke-Wslc -ArgsList @("container", "prune", "-f") -IgnoreError -Quiet
$null = Invoke-Wslc -ArgsList @("volume", "prune", "-f") -IgnoreError -Quiet
$null = Invoke-Wslc -ArgsList @("network", "prune", "-f") -IgnoreError -Quiet
$null = Invoke-Wslc -ArgsList @("image", "prune", "-f") -IgnoreError -Quiet

# --- compactacao -------------------------------------------------------------
if ($Compact) {
    Write-Host "`n=== Compactando storage.vhdx ===" -ForegroundColor Cyan
    $storage = Get-WslcStorageInfo
    if (-not $storage.Available) {
        Write-Host "  storage.vhdx nao encontrado." -ForegroundColor Yellow
    } else {
        Write-Host "  Antes: $($storage.SizeGB) GB"
        Write-Host "  A sessao wslc precisa estar parada (nenhum container rodando)." -ForegroundColor DarkGray
        $running = @($containers | Where-Object { "$($_.State)" -eq "running" })
        if ($running.Count -gt 0) {
            Write-Host "  AVISO: ha $($running.Count) container(s) rodando. Pare-os antes de compactar:" -ForegroundColor Yellow
            foreach ($r in $running) { Write-Host "    wslc container stop $($r.Names)" }
        } else {
            $optimize = Get-Command Optimize-VHD -ErrorAction SilentlyContinue
            if ($optimize) {
                Write-Host "  Encerrando sessao wslc..." -ForegroundColor Gray
                $null = Invoke-Wslc -ArgsList @("system", "session", "terminate") -IgnoreError -Quiet
                Start-Sleep -Seconds 5
                try {
                    Optimize-VHD -Path $storage.Path -Mode Full -ErrorAction Stop
                    $after = Get-WslcStorageInfo
                    Write-Host "  Depois: $($after.SizeGB) GB" -ForegroundColor Green
                } catch {
                    Write-Host "  Falha ao compactar: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "  Feche o Docker Desktop/WSL e tente de novo." -ForegroundColor DarkGray
                }
            } else {
                Write-Host "  Optimize-VHD indisponivel. Use diskpart:" -ForegroundColor Yellow
                Write-Host "    wsl --shutdown"
                Write-Host "    diskpart"
                Write-Host "      select vdisk file=`"$($storage.Path)`""
                Write-Host "      attach vdisk readonly"
                Write-Host "      compact vdisk"
                Write-Host "      detach vdisk"
            }
        }
    }
}

# --- resumo final ------------------------------------------------------------
$storageAfter = Get-WslcStorageInfo
Write-Host "`n=== Resumo ===" -ForegroundColor Cyan
if ($storageBefore.Available) { Write-Host "  storage.vhdx antes : $($storageBefore.SizeGB) GB" }
if ($storageAfter.Available)  { Write-Host "  storage.vhdx depois: $($storageAfter.SizeGB) GB" }
if ($storageBefore.Available -and $storageAfter.Available) {
    $delta = [math]::Round($storageBefore.SizeGB - $storageAfter.SizeGB, 2)
    if ($delta -gt 0) {
        Write-Host "  Liberado: $delta GB" -ForegroundColor Green
    } else {
        Write-Host "  Sem reducao no arquivo (use -Compact para encolher o VHDX)" -ForegroundColor DarkGray
    }
}
Write-Host "`nConcluido." -ForegroundColor Green

Stop-Transcript | Out-Null
