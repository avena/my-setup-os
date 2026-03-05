# Scoop - Gerenciador de Pacotes para Windows

## Overview
Esta pasta contém a configuração do **Scoop**, um gerenciador de pacotes open-source para Windows que permite instalar e gerenciar aplicativos de forma simples e organizada.

## Arquivos na Pasta

### 1. scoop-programs.json
Arquivo de exportação dos programas instalados via Scoop, gerado com o comando:
```powershell
scoop export > scoop-programs.json
```
Contém:
- Lista de aplicativos instalados (com versão e fonte)
- Buckets configurados (repositórios de pacotes)
- Data de atualização dos pacotes

### 2. buckets.json (Template)
Arquivo que define os buckets (repositórios de pacotes) para o Scoop. Exemplo:
```json
{
  "buckets": [
    { "name": "main", "source": "https://github.com/ScoopInstaller/Main" },
    { "name": "extras", "source": "https://github.com/ScoopInstaller/Extras" },
    { "name": "nerd-fonts", "source": "https://github.com/matthewjberger/scoop-nerd-fonts" }
  ]
}
```

## Instalação do Scoop

### Pré-requisitos
- PowerShell 5.1+ (padrão no Windows 10/11)
- Permissões de execução de scripts PowerShell

### Passo a Passo
1. Abra o PowerShell como Administrador
2. Execute o comando de instalação:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```
3. Verifique a instalação:
```powershell
scoop help
```

## Importando e Exportando Programas

### Exportar Programas Atuais
```powershell
scoop export > scoop-programs.json
```

### Importar Programas
```powershell
scoop import scoop-programs.json
```

## Gerenciamento de Buckets

### Adicionar Buckets
```powershell
scoop bucket add extras
scoop bucket add nerd-fonts https://github.com/matthewjberger/scoop-nerd-fonts
```

### Listar Buckets
```powershell
scoop bucket list
```

## UnigetiUI - Interface Gráfica

### Instalação
```powershell
scoop install unigetui
```

### Funcionalidades
- Interface gráfica para gerenciar pacotes Scoop
- Visualização de updates disponíveis
- Instalação e desinstalação de programas
- Gerenciamento de buckets
- Busca por pacotes

## Dicas Úteis

### Atualizar Todos os Pacotes
```powershell
scoop update *
```

### Limpar Cache
```powershell
scoop cache rm *
```

### Verificar Problemas
```powershell
scoop checkup
```

## Troubleshooting

### Erro de Execução de Scripts
Se você receber um erro sobre execução de scripts, execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Proxy Configurations
```powershell
scoop config proxy "http://user:pass@proxy.example.com:8080"
```

