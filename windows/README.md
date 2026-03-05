# Configurações Windows

Este diretório contém configurações específicas do Windows Host.

## Estrutura

### fonts/
- **install-fonts.ps1**: Instalação de fontes via Scoop
- **README.md**: Documentação da instalação de fontes

### networking/
- ***.ps1**: Scripts PowerShell para configuração de NAT e rede
- **simple-dhcp-server-qt.yml**: Configuração do servidor DHCP
- **README.md**: Explicação dos scripts de rede

### scoop/
- **scoop-programs.json**: Lista de programas instalados
- **README.md**: Instruções para uso do Scoop e UnigetiUI

### Arquivos Root
- **Set-PowerShell7AsDefault.ps1**: Configura o PowerShell 7 como padrão

## Instalação

### Fontes
```powershell
cd fonts/
.\install-fonts.ps1
```

### PowerShell 7
```powershell
.\Set-PowerShell7AsDefault.ps1
```

### Rede
```powershell
cd networking/
.\Configurar-NAT-Rede50.ps1
```

### Scoop
```powershell
cd scoop/
# Siga as instruções no README.md
```