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
- **.wslconfig**: Configuração do WSL 2 (Windows Subsystem for Linux)

## Configuração WSL 2

O arquivo **.wslconfig** (arquivo oculto) controla as configurações do WSL 2 no Windows. Ele deve ser colocado na raiz do diretório do usuário Windows (ex: `C:\Users\seu-usuario\.wslconfig`). Define parâmetros como:

- **Rede**: Modo de rede (NAT ou mirrored) e configurações de DNS
- **Recursos**: Memória, processadores e swap
- **Segurança**: Firewall e proxy automático

### Instalação

Copie o arquivo para o diretório base do usuário Windows:

```powershell
Copy-Item .wslconfig $env:USERPROFILE\.wslconfig -Force
```

**Importante**: O arquivo `.wslconfig` é um arquivo oculto no Windows e deve ser colocado no diretório do usuário (`%USERPROFILE%`).

### Personalização

Você pode ajustar os parâmetros conforme sua necessidade:

- **memory**: Memória máxima para WSL 2
- **processors**: Número de processadores virtuais
- **networkingMode**: NAT ou mirrored (mais estável)
- **swap**: Tamanho do arquivo de swap

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