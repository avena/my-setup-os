# Libera no firewall do Windows as portas dos MCPs de CAD/GIS para o WSL.
# Rodar em PowerShell como Administrador:
#   powershell -ExecutionPolicy Bypass -File .\Allow-CadMcpFirewall.ps1
# Requer elevação: cria regras Inbound no perfil Any (WSL aparece como rede privada).
$ErrorActionPreference = 'Stop'

if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "Execute como Administrador (o firewall não aceita regras Inbound sem elevação)."
}

$rules = @(
    @{ Name = 'FreeCAD MCP (WSL)'; Port = 9875 },
    @{ Name = 'QGIS MCP (WSL)';    Port = 9874 },
    @{ Name = 'Blender MCP (WSL)'; Port = 9876 }
)

foreach ($r in $rules) {
    if (Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue) {
        Write-Host "[=] $($r.Name) já existe" -ForegroundColor Yellow
        continue
    }
    New-NetFirewallRule -DisplayName $r.Name -Direction Inbound -LocalPort $r.Port `
        -Protocol TCP -Action Allow -Profile Any | Out-Null
    Write-Host "[+] $($r.Name) porta $($r.Port)" -ForegroundColor Green
}

Write-Host "`nRegras ativas:" -ForegroundColor Cyan
Get-NetFirewallRule -DisplayName '* MCP (WSL)' |
    Select-Object DisplayName, Enabled, Profile |
    Format-Table -AutoSize
