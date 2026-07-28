# Windows Setup Guide

## Visão Geral

Este guia documenta todas as configurações específicas do Windows Host neste repositório. A pasta `windows/` contém scripts PowerShell para fontes, rede, pacotes e utilitários.

## Arquitetura

```
windows/
├── README.md                           # Visão geral das configs Windows
├── .wslconfig                          # Configuração do WSL 2
├── Set-PowerShell7AsDefault.ps1        # Define PS7 como shell padrão
├── download_notebook_aria2c.ps1        # yt-dlp avançado (vídeo/áudio)
├── fonts/
│   ├── install-fonts.ps1               # Instalação de fontes via Scoop
│   └── README.md
├── networking/
│   ├── check_nat_install.ps1           # Verifica NAT
│   ├── Configurar-NAT-Rede50.ps1       # NAT rede 50.x.x.x
│   ├── forward-ssh.ps1                 # SSH port forwarding
│   ├── nat-duas-redes.ps1              # NAT duas redes
│   ├── nat-manager.ps1                 # Gerenciador de NAT
│   ├── nat-rede137.ps1                 # NAT rede 137.x.x.x
│   ├── nat-rede50-desktop.ps1          # NAT desktop específico
│   ├── nat-rede50.ps1                  # NAT básico rede 50
│   ├── simple-dhcp-server-qt.yml       # Config DHCP Server
│   ├── url-programa.txt                # Link download DHCP
│   └── README.md
└── scoop/
    ├── scoop-programs.json             # Lista de programas instalados
    └── README.md
```

---

## WSL 2 Configuration (`.wslconfig`)

O arquivo `.wslconfig` controla o comportamento do WSL 2. Deve ser copiado para `%USERPROFILE%\.wslconfig` no Windows.

### Instalação

```powershell
Copy-Item .wslconfig $env:USERPROFILE\.wslconfig -Force
```

### Parâmetros Configuráveis

| Parâmetro | Descrição |
|---|---|
| `memory` | Memória máxima alocada ao WSL 2 |
| `processors` | Número de CPUs virtuais |
| `networkingMode` | Modo de rede: `nat` ou `mirrored` |
| `swap` | Tamanho do arquivo de swap |

> **Nota:** `mirrored` mode é mais estável para configurações de rede customizadas com NAT.

---

## PowerShell 7

### Configurar como Padrão

```powershell
.\Set-PowerShell7AsDefault.ps1
```

Este script define o PowerShell 7 como o shell padrão para terminais Windows.

---

## Scoop — Package Manager

### Instalação do Scoop

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

### Buckets Configurados

| Bucket | Fonte |
|---|---|
| `main` | ScoopInstaller/Main |
| `extras` | ScoopInstaller/Extras |
| `nerd-fonts` | scoop-nerd-fonts |

### Comandos Úteis

```powershell
# Instalar programas do JSON exportado
scoop import scoop-programs.json

# Exportar programas atuais
scoop export > scoop-programs.json

# Atualizar tudo
scoop update *

# Limpar cache
scoop cache rm *

# Verificar problemas
scoop checkup
```

### UnigetiUI (Interface Gráfica)

```powershell
scoop install unigetui
```

UnigetiUI fornece uma GUI para gerenciar pacotes, buckets e atualizações do Scoop.

---

## Fontes

### Instalação via Scoop

```powershell
cd fonts/
.\install-fonts.ps1
```

### Fontes Instaladas

| Fonte | Tipo |
|---|---|
| Fira Code | Clean |
| Fira Code NF | Nerd Font |
| JetBrains Mono | Clean |
| JetBrains Mono NF | Nerd Font |
| Cascadia Code | Clean |
| Cascadia Code NF | Nerd Font |

### Configuração no Windows Terminal

Edite `settings.json`:
```json
{
  "profiles": {
    "defaults": {
      "fontFace": "Fira Code NF"
    }
  }
}
```

---

## Networking — NAT e DHCP

Scripts PowerShell para configurar redes customizadas, especialmente úteis para cenários com WSL 2.

### Scripts de NAT

| Script | Função |
|---|---|
| `check_nat_install.ps1` | Verifica se NAT está instalado |
| `Configurar-NAT-Rede50.ps1` | Configura NAT para rede 50.x.x.x |
| `nat-rede50.ps1` | NAT básico para rede 50 |
| `nat-rede50-desktop.ps1` | NAT específico para desktop |
| `nat-rede137.ps1` | NAT para rede 137.x.x.x |
| `nat-duas-redes.ps1` | Gerencia NAT para duas redes |
| `nat-manager.ps1` | Interface gerenciadora de NAT |
| `forward-ssh.ps1` | Configura SSH port forwarding |

### Execução

Todos os scripts de rede devem ser executados como **Administrador**:

```powershell
# Abrir PowerShell como Admin
cd windows/networking/
.\Configurar-NAT-Rede50.ps1
```

### Políticas de Execução

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### DHCP Server

O arquivo `simple-dhcp-server-qt.yml` é configuração para o **Simple DHCP Server** — um servidor DHCP portátil que não requer instalação.

1. Baixe o programa do link em `url-programa.txt`
2. Extraia o zip
3. Execute `SimpleDHCP.exe`
4. Carregue `simple-dhcp-server-qt.yml`

---

## Download de Vídeos/Áudio (`download_notebook_aria2c.ps1`)

Script avançado baseado em **yt-dlp** com interface de linha de comando e suporte a aria2c para downloads acelerados.

### Recursos

| Recurso | Descrição |
|---|---|
| **Resoluções** | 360p, 480p, 720p, 1080p |
| **Audio-Only** | Extração de áudio em múltiplos formatos |
| **Formatos de Áudio** | mp3, m4a, wav, flac, opus, aac, vorbis |
| **Qualidade de Áudio** | Ajustável (0-10) |
| **Legendas** | Download e incorporação de legendas |
| **Playlist** | Controle de início/fim de playlist |
| **SponsorBlock** | Remoção automática de segmentos de patrocinador |
| **Metadados** | Incorporação de metadados e thumbnails |
| **aria2c** | Download acelerado (se disponível) |
| **Cookies** | Suporte a cookies.txt para conteúdo restrito |

### Exemplos de Uso

```powershell
# Download de vídeo em 1080p
.\download_notebook_aria2c.ps1 -Resolucao 1080p

# Download de áudio em MP3
.\download_notebook_aria2c.ps1 -AudioOnly -AudioFormat mp3

# Download de áudio em FLAC (melhor qualidade)
.\download_notebook_aria2c.ps1 -AudioOnly -AudioFormat flac -AudioQuality 0

# Download com legendas em português
.\download_notebook_aria2c.ps1 -Resolucao 720p -Subtitles -SubtitleLang pt

# Download de playlist (primeiros 5 vídeos)
.\download_notebook_aria2c.ps1 -AudioOnly -PlaylistStart 1 -PlaylistEnd 5

# Download com remoção de sponsors
.\download_notebook_aria2c.ps1 -Resolucao 1080p -Sponsor

# Teste sem download (dry run)
.\download_notebook_aria2c.ps1 -Resolucao 1080p -DryRun

# Download em diretório personalizado
.\download_notebook_aria2c.ps1 -Resolucao 720p -OutputDir "C:\Downloads"
```

### Arquivo de URLs

Crie `url.txt` no mesmo diretório, uma URL por linha:
```
https://www.youtube.com/watch?v=example1
https://www.youtube.com/watch?v=example2
https://vimeo.com/example3
```

### Cookies (Opcional)

Para conteúdo que requer autenticação, coloque `cookies.txt` no mesmo diretório.

---

## Pós-Setup Windows

Após configurar:

```powershell
# 1. Verificar WSL 2
wsl --status

# 2. Verificar Scoop
scoop list

# 3. Verificar fontes
fc-list | Select-String "Fira Code"

# 4. Verificar NAT
Get-NetNat
```
