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
- **download_notebook_aria2c.ps1**: Script avançado para download de vídeos/áudio com yt-dlp
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

### Download de Vídeos/Áudio (yt-dlp)
O script `download_notebook_aria2c.ps1` fornece uma interface avançada para o yt-dlp com suporte a:

#### Recursos Principais
- **Múltiplas Resoluções**: 360p, 480p, 720p, 1080p
- **Modo Áudio-Only**: Extração de áudio com múltiplos formatos
- **Formatos de Áudio**: mp3, m4a, wav, flac, opus, aac, vorbis
- **Controle de Qualidade**: Qualidade de áudio ajustável (0-10)
- **Legendas**: Download e incorporação de legendas
- **Playlist Control**: Controle de início/fim de playlist
- **SponsorBlock**: Remoção automática de segmentos de patrocinador
- **Metadados**: Incorporação de metadados e thumbnails
- **Download Acelerado**: Uso automático de aria2c quando disponível
- **Autenticação**: Suporte a cookies.txt para conteúdo restrito

#### Exemplos de Uso

**Download de vídeo em 1080p:**
```powershell
.\download_notebook_aria2c.ps1 -Resolucao 1080p
```

**Download apenas de áudio em MP3:**
```powershell
.\download_notebook_aria2c.ps1 -AudioOnly -AudioFormat mp3
```

**Download de áudio em FLAC com melhor qualidade:**
```powershell
.\download_notebook_aria2c.ps1 -AudioOnly -AudioFormat flac -AudioQuality 0
```

**Download com legendas em português:**
```powershell
.\download_notebook_aria2c.ps1 -Resolucao 720p -Subtitles -SubtitleLang pt
```

**Download de playlist (primeiros 5 vídeos):**
```powershell
.\download_notebook_aria2c.ps1 -AudioOnly -PlaylistStart 1 -PlaylistEnd 5
```

**Download com remoção de sponsors:**
```powershell
.\download_notebook_aria2c.ps1 -Resolucao 1080p -Sponsor
```

**Teste sem download (dry run):**
```powershell
.\download_notebook_aria2c.ps1 -Resolucao 1080p -DryRun
```

**Download em diretório personalizado:**
```powershell
.\download_notebook_aria2c.ps1 -Resolucao 720p -OutputDir "C:\Downloads"
```

#### Arquivo de URLs
Crie um arquivo `url.txt` no mesmo diretório com uma URL por linha:
```
https://www.youtube.com/watch?v=example1
https://www.youtube.com/watch?v=example2
https://vimeo.com/example3
```

#### Cookies (Opcional)
Para conteúdo que requer autenticação, coloque um arquivo `cookies.txt` no mesmo diretório.