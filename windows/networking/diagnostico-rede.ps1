& {
    $out = @()
    $out += "=== DIAGNOSTICO COMPLETO - WINDOWS ==="
    $out += "[1] IPs:"
    $out += ipconfig | Select-String IPv4
    $out += ""
    $out += "[2] NAT:"
    $out += Get-NetNat | Out-String
    $out += "[3] Portproxy:"
    $out += netsh interface portproxy show v4tov4
    $out += ""
    $out += "[4] Firewall porta 22:"
    $out += Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True | Get-NetFirewallPortFilter | Where-Object { $_.LocalPort -eq 22 }
    $out += ""
    $out += "[5] Ping 192.168.60.6:"
    $out += Test-Connection 192.168.60.6 -Count 2 -ErrorAction SilentlyContinue
    $out += ""
    $out += "[6] Teste porta 22:"
    $out += Test-NetConnection 192.168.60.6 -Port 22 -WarningAction SilentlyContinue
    $out += ""
    $out += "=== FIM ==="
    $out -join "`r`n" | Set-Clipboard
    Write-Host "Diagnostico copiado para a area de transferencia." -ForegroundColor Green
    $out
}
