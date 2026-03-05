#==============================================================================
# Script: Configurar-NAT-DuasRedes.ps1
# Descricao: Configura NAT para DUAS redes simultaneamente
#   - Rede50:  192.168.50.x   via Ethernet         (MAC: 04-58-5D-21-3B-93)
#   - Rede137: 192.168.137.x  via Conexao Local*10 (MAC: 26-B2-B9-FD-51-8B)
# Requisito: Executar como ADMINISTRADOR
#==============================================================================

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole( `
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERRO: Execute este script como ADMINISTRADOR!"
    Write-Host "Clique com botao direito no PowerShell > Executar como Administrador"
    Start-Sleep -Seconds 3
    exit 1
}

Write-Host "=============================================="
Write-Host "  Configurando NAT - Rede50 + Rede137         "
Write-Host "=============================================="
Write-Host ""

#------------------------------------------------------------------------------
# Definicao das redes (identificadas por MAC - imutavel)
#------------------------------------------------------------------------------
$Redes = @(
    @{
        Nome         = "Rede50"
        MAC          = "04-58-5D-21-3B-93"
        IPAddress    = "192.168.50.1"
        PrefixLength = 24
        Subnet       = "192.168.50.0/24"
        Faixa        = "192.168.50.10 a 192.168.50.200"
    },
    @{
        Nome         = "Rede137"
        MAC          = "26-B2-B9-FD-51-8B"
        IPAddress    = "192.168.137.1"
        PrefixLength = 24
        Subnet       = "192.168.137.0/24"
        Faixa        = "192.168.137.10 a 192.168.137.200"
    }
)

#------------------------------------------------------------------------------
# Valida se todas as interfaces foram encontradas antes de comecar
#------------------------------------------------------------------------------
Write-Host "Validando interfaces..."
foreach ($Rede in $Redes) {
    $adapter = Get-NetAdapter | Where-Object { $_.MacAddress -eq $Rede.MAC }
    if (-not $adapter) {
        Write-Host "ERRO: Interface '$($Rede.Nome)' com MAC $($Rede.MAC) nao encontrada!"
        Write-Host "Verifique com: Get-NetAdapter | Select-Object Name, MacAddress"
        Start-Sleep -Seconds 3
        exit 1
    }
    $Rede.InterfaceAlias = $adapter.Name
    Write-Host "   $($Rede.Nome): '$($adapter.Name)' (MAC: $($Rede.MAC))"
}
Write-Host ""

#------------------------------------------------------------------------------
# 1. Configurar Servico WinNAT (unico, compartilhado)
#------------------------------------------------------------------------------
Write-Host "[1/4] Configurando servico WinNAT..."

try {
    Set-Service -Name "WinNAT" -StartupType Automatic -ErrorAction Stop
    Start-Service -Name "WinNAT" -ErrorAction Stop
    Write-Host "   Servico WinNAT configurado e iniciado"
} catch {
    Write-Host "   Aviso: Nao foi possivel configurar WinNAT ($_)"
}

#------------------------------------------------------------------------------
# 2. Habilitar encaminhamento de IP no registro (unico, compartilhado)
#------------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/4] Habilitando encaminhamento de IP no registro..."

try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" `
        -Name "IPEnableRouter" -Value 1 -Type DWord -Force -ErrorAction Stop
    Write-Host "   Registro IPEnableRouter = 1"
} catch {
    Write-Host "   Erro ao configurar registro: $_"
}

#------------------------------------------------------------------------------
# 3. Configurar IP e NAT para cada rede
#------------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/4] Configurando IPs e regras NAT..."

foreach ($Rede in $Redes) {
    Write-Host ""
    Write-Host "   --- $($Rede.Nome) ($($Rede.Subnet)) | '$($Rede.InterfaceAlias)' ---"

    # IP na interface
    try {
        $existingIP = Get-NetIPAddress -InterfaceAlias $Rede.InterfaceAlias -IPAddress $Rede.IPAddress -ErrorAction SilentlyContinue
        if ($existingIP) {
            Remove-NetIPAddress -InterfaceAlias $Rede.InterfaceAlias -IPAddress $Rede.IPAddress `
                -PrefixLength $Rede.PrefixLength -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "   IP existente removido"
        }
        New-NetIPAddress -InterfaceAlias $Rede.InterfaceAlias -IPAddress $Rede.IPAddress `
            -PrefixLength $Rede.PrefixLength -ErrorAction Stop
        Write-Host "   IP $($Rede.IPAddress) configurado"
    } catch {
        Write-Host "   Aviso: IP pode ja estar configurado ($_)"
    }

    # Regra NAT
    try {
        $existingNat = Get-NetNat -Name $Rede.Nome -ErrorAction SilentlyContinue
        if ($existingNat) {
            $existingNat | Remove-NetNat -Confirm:$false
            Write-Host "   Regra NAT '$($Rede.Nome)' antiga removida"
        }
        New-NetNat -Name $Rede.Nome -InternalIPInterfaceAddressPrefix $Rede.Subnet -ErrorAction Stop
        Write-Host "   Regra NAT '$($Rede.Nome)' criada para $($Rede.Subnet)"
    } catch {
        Write-Host "   Erro ao criar regra NAT: $_"
    }
}

#------------------------------------------------------------------------------
# 4. Verificacao Final
#------------------------------------------------------------------------------
Write-Host ""
Write-Host "[4/4] Verificando configuracao..."
Write-Host ""

Write-Host "Servico WinNAT:"
Get-Service -Name "WinNAT" | Select-Object Name, Status, StartType | Format-Table

Write-Host "Interfaces de Rede (192.168.x.x):"
Get-NetIPAddress | Where-Object {$_.IPAddress -like "192.168.*"} | `
    Select-Object InterfaceAlias, IPAddress, PrefixLength | Format-Table

Write-Host "Regras NetNat:"
Get-NetNat | Select-Object Name, InternalIPInterfaceAddressPrefix | Format-Table

#------------------------------------------------------------------------------
# Resumo
#------------------------------------------------------------------------------
Write-Host ""
Write-Host "=============================================="
Write-Host "  CONFIGURACAO CONCLUIDA!                     "
Write-Host "=============================================="
Write-Host ""

foreach ($Rede in $Redes) {
    Write-Host "$($Rede.Nome) - Interface: $($Rede.InterfaceAlias)"
    Write-Host "   Gateway: $($Rede.IPAddress)"
    Write-Host "   Faixa DHCP sugerida: $($Rede.Faixa)"
    Write-Host ""
}

Write-Host "PROXIMOS PASSOS:"
Write-Host "   1. Reinicie o computador (Recomendado)"
Write-Host "   2. Configure seu servidor DHCP para cada rede conforme acima"
Write-Host "   3. Desative o ICS em interfaces que nao precisem dele"
Write-Host ""
Write-Host "SE NAO FUNCIONAR:"
Write-Host "   - Execute: Set-NetFirewallProfile -Profile Public,Private -Enabled False"
Write-Host "   - Verifique: Get-NetNat"
Write-Host ""

Write-Host "Pressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
