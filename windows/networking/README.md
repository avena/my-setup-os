# Windows Networking

## Overview
Esta pasta contém scripts PowerShell para gerenciamento de rede no Windows, especialmente voltados para configurações NAT (Network Address Translation) e servidor DHCP, frequentemente usados em ambientes WSL.

## Arquivos na Pasta

### Scripts de NAT
- `check_nat_install.ps1`: Verifica se a função de NAT está instalada
- `Configurar-NAT-Rede50.ps1`: Configura NAT para a rede 50.x.x.x
- `forward-ssh.ps1`: Configura encaminhamento de porta SSH
- `nat-duas-redes.ps1`: Gerenciamento de NAT para duas redes
- `nat-manager.ps1`: Gerenciador de NAT (interface para configurações)
- `nat-rede137.ps1`: Configura NAT para a rede 137.x.x.x
- `nat-rede50-desktop.ps1`: Configuração NAT específica para desktop
- `nat-rede50.ps1`: Configuração NAT básica para rede 50.x.x.x

### Servidor DHCP
- `simple-dhcp-server-qt.yml`: Configuração do servidor DHCP Simple DHCP Server
- `url-programa.txt`: URL para download do Simple DHCP Server

## Uso Básico

### Executando Scripts
1. Abra o PowerShell como Administrador
2. Navegue até a pasta:
   ```powershell
   cd C:\caminho\para\meu-setup-os\windows\networking
   ```
3. Execute o script desejado:
   ```powershell
   .\Configurar-NAT-Rede50.ps1
   ```

### Verificando Status do NAT
```powershell
Get-NetNat
```

### Removendo Configurações NAT
```powershell
Remove-NetNat -Name "WSLNAT"
```

## Requisitos

### Permissões
- Todos os scripts precisam ser executados como **Administrador**
- Permissões de execução de scripts PowerShell:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### Componentes Necessários
- Hyper-V (para algumas configurações)
- Windows 10/11 Professional ou Enterprise (para Hyper-V)

## Configuração DHCP

### Instalando o Simple DHCP Server
1. Baixe o programa do link em `url-programa.txt`
2. Extraia o arquivo zip
3. Execute o `SimpleDHCP.exe` (não precisa instalar)
4. Carregue a configuração do arquivo `simple-dhcp-server-qt.yml`

### Arquivo de Configuração
O `simple-dhcp-server-qt.yml` contém:
- Configurações do servidor DHCP
- Faixa de endereços IP disponíveis
- Gateway padrão
- Servidores DNS
- Tempo de lease

## Troubleshooting

### Script Não Executa
Verifique a política de execução de scripts:
```powershell
Get-ExecutionPolicy
```

### NAT Não Funciona
1. Verifique se o Hyper-V está ativado
2. Verifique a configuração da rede virtual
3. Reinicie o serviço WSL:
   ```powershell
   wsl --shutdown
   ```

### Erro de Permissão
Certifique-se de estar executando o PowerShell como Administrador.

