# Projetos Containerizados (WSL / Docker / Finch)

Automações para clonar, construir e executar projetos em containers.

Há **dois caminhos independentes**, escolhidos pelo sistema operacional:

| Sistema | Script | Runtime | Como obtém a imagem |
|---|---|---|---|
| Windows (PowerShell 7) | `setup-*.ps1` | `wslc.exe` (WSL Containers) | **clone + `wslc build` local** |
| Linux / WSL (Bash) | `setup-*.sh` | `docker` → `finch` | `docker compose` (pull do registry) |

Os `.sh` **não são alterados** por este padrão: continuam funcionando com
`docker` ou `finch` via `docker compose`/`finch compose`.

## Projetos

| Projeto | Containers | Volume de dados | Rede | Portas |
|---|---|---|---|---|
| `crawlseo` | `crawlseo-database`, `crawlseo-web`, `crawlseo-worker` | `crawlseo-database-data` | `crawlseo-network` | `3002` |
| `mission-control` | `mission-control-web` | `mission-control-web-data` | `mission-control-network` | `3003` |
| `open-notebook` | `open-notebook-database`, `open-notebook-web` | `open-notebook-database-data`, `open-notebook-web-data` | `open-notebook-network` | `8502` (UI), `5055` (API) |

> As portas `3000` e `3001` estão ocupadas no Windows pelo serviço `iphlpsvc`
> (faixa excluída do Hyper-V), que não pode ser liberado. Por isso os padrões
> são `3002` e `3003`.

Convenção de nomes: `<projeto>-<função>` para containers, volumes e rede.

## Estrutura comum dos `.ps1` (Windows / `wslc`)

Todos os três scripts têm **exatamente as mesmas ações e parâmetros**, porque
compartilham a biblioteca `wslc-common.ps1`:

```powershell
-Action up|stop|status|logs|delete
```

| Ação | O que faz |
|---|---|
| *(sem `-Action`)* | **Abre o menu interativo.** Rodar o script sem argumentos nunca sobe nada. |
| `up` | Pergunta onde salvar o código → `git clone` → `wslc build` → sobe os containers |
| `stop` | Para os containers, preservando dados |
| `status` | **URLs no início**, depois containers, portas, imagens, volumes, rede e onde os dados ficam |
| `logs` | Últimas 80 linhas de cada container |
| `delete` | Remove containers, volumes (nomeados e anônimos), rede, imagens, `.env` e o código-fonte clonado |

### Parâmetros comuns

| Parâmetro | Padrão | Descrição |
|---|---|---|
| `-Storage volume\|bind` | `volume` | `volume` = volume nomeado no storage do wslc (ext4, **recomendado**). `bind` = pasta em NTFS, com aviso (corrompe RocksDB/SQLite WAL). |
| `-WebPort` | por projeto | Porta HTTP da aplicação |
| `-ApiPort` | por projeto | Porta da API (open-notebook) |
| `-ExposeDb` / `-DbPort` | desligado | Publica a porta do banco para debug |
| `-SourcePath` | pergunta | Onde clonar o repositório |
| `-Force` | — | Não pergunta nada; para containers do wslc que seguram a porta |
| `-NonInteractive` | — | Sem perguntas (usa padrões) |
| `-NoBuild` | — | Usa a imagem local existente, sem rebuild |
| `-Rebuild` | — | `wslc build --no-cache` |
| `-KeepImages` | — | `delete` preserva as imagens |
| `-RemoveStorage` | — | `delete` apaga o `storage.vhdx` inteiro (libera todo o espaço) |

### Onde salvar o código-fonte

O `up` **pergunta a cada execução**:

```
=== Onde salvar o codigo-fonte do open-notebook? ===
  [1] Pasta do script   <projeto>\repo   (1.6 GB livres)
  [2] Disco D:          D:\wslc-src\open-notebook  (325.3 GB livres)
      ATENCAO: se D: for disco USB removivel, nao desconecte com containers rodando.
  [3] Outro caminho
```

Se `D:` não estiver montado, a opção nem aparece. O código-fonte é pequeno
(dezenas de MB); quem consome espaço é o `storage.vhdx` do wslc.

## Build local: sem pull da imagem do projeto

O `up` **não baixa a imagem pronta** do Docker Hub/GHCR. Ele clona o
repositório e constrói a imagem com `wslc build`, o que permite:

- editar o `Dockerfile` para reduzir o tamanho da imagem;
- usar o `.env` local do projeto.

| Projeto | Origem antiga (pull) | Agora |
|---|---|---|
| open-notebook | `lfnovo/open_notebook:v1-latest` | `wslc build --target runtime` → `open-notebook-web:local` |
| crawlseo | `ghcr.io/crawlseo/crawlseo:latest` | `wslc build` → `crawlseo-web:local` (web e worker) |
| mission-control | *(não havia imagem publicada)* | `wslc build` → `mission-control-web:local` |

As **imagens-base** (`node:22-slim`, `python:3.12-slim`, `postgres:16-alpine`,
`busybox`) continuam vindo do registry — é inevitável, todo Dockerfile tem
`FROM`. Elas ficam em cache depois do primeiro uso.

### Restrição do `wslc build`

O contexto de build **precisa ser um caminho do Windows** (`C:\...`, `D:\...`).
Caminho UNC (`\\wsl.localhost\<distro>\...`) falha com
`Falha catastrófica / E_UNEXPECTED`. O script valida isso antes de tentar.

## Onde os dados ficam

Há **dois armazenamentos distintos**:

### 1. Código-fonte — por projeto
Na pasta escolhida no `up` (item acima). Contém o clone, o `Dockerfile` e o
arquivo de ambiente.

### 2. Imagens e volumes — **global**

Ficam no disco virtual da sessão `wslc`:

```
%LOCALAPPDATA%\wslc\sessions\wslc-cli-<usuario>\storage.vhdx
```

O caminho pode ser movido (útil quando `C:` está cheio) em
`%LOCALAPPDATA%\wslc\settings.yaml`:

```yaml
session:
  # Base directory for the default session's storage; the session VHD is
  # created at <storagePath>\wslc\sessions\<session>\storage.vhdx
  storagePath: D:\wslc-data
  maxStorageSize: 200GB
```

> O próprio `wslc` avisa: *"Changing this after a session already exists does
> not move existing storage, containers, or images; the previous location is
> left in place and a new empty session is created at the new path."*
> Ou seja: os dados antigos **não migram** — é preciso removê-los à mão.

Dentro do `storage.vhdx`, os volumes nomeados ficam em
`/var/lib/docker/volumes/<nome>/_data`. Esse caminho é visível **apenas** de
dentro da sessão `wslc`, não da distro Ubuntu.

**Consequência prática:** `docker volume ls` no Ubuntu **não vê** esses
volumes, e `docker compose down -v` **não apaga** esses dados. É um
armazenamento separado.

## Limpeza

### `wslc-clean.ps1` — limpeza global

O `storage.vhdx` é **esparso**: remover containers, imagens e volumes **não
reduz o arquivo** no Windows. Só a compactação devolve espaço.

```powershell
.\projetos\wslc-clean.ps1                              # preview (nada é alterado)
.\projetos\wslc-clean.ps1 -Action execute              # limpa órfãos
.\projetos\wslc-clean.ps1 -Action execute -Compact     # + compacta o VHDX
```

O `preview` é implementado no script (o `wslc` não tem `--dry-run`): ele lista
via JSON o que é órfão e calcula o total.

| Flag | Efeito |
|---|---|
| *(nenhuma)* | Preview: lista o que sairia, sem tocar em nada |
| `-Action execute` | Executa a remoção |
| `-IncludeInUse` | Inclui recursos em uso (**perigoso**) |
| `-Compact` | `Optimize-VHD` no `storage.vhdx` (exige sessão parada) |
| `-Force` | Não pergunta |

### `-Action delete` de cada projeto

Remove tudo do projeto — containers, volumes nomeados e anônimos, rede,
imagens, `.env` e o código-fonte clonado.

> **Volumes anônimos** são a causa silenciosa do crescimento do disco: cada
> `wslc run` cria volumes anônimos para `/data`, `/logs` etc., e
> `wslc container rm -f` **sem `-v`** não os remove. O `delete` usa `-v` e
> `volume prune -f`.

#### Recuperar o espaço em disco

O `storage.vhdx` é **esparso**: remover containers, imagens e volumes **não
reduz o tamanho do arquivo** no Windows. Depois de remover os recursos, o
`delete` avisa e oferece apagar o arquivo inteiro:

```powershell
.\setup-open-notebook.ps1 -Action delete -RemoveStorage
```

| Item | Detalhe |
|---|---|
| O que libera | **Todo** o espaço ocupado pelo `storage.vhdx` |
| O que apaga | Imagens, volumes e dados de **todos** os projetos do wslc |
| Recriação | Automática, ~0,5 GB, no próximo comando `wslc` |

Medido na prática: `storage.vhdx` de **6,14 GB** → removido → recriado em
**0,57 GB** (C: passou de 1,5 GB para 7,7 GB livres).

Como o arquivo é **global** (compartilhado entre os três projetos), a remoção
pede confirmação digitando `SIM` — a não ser com `-Force`.

## Como executar

### Windows (PowerShell 7)

```powershell
# Menu interativo (recomendado na primeira vez)
pwsh ./projetos/open-notebook/setup-open-notebook.ps1

# Ações diretas
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action up
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action status
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action stop
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action delete

# Mesma estrutura nos três
pwsh ./projetos/crawlseo/setup-crawlseo.ps1 -Action up
pwsh ./projetos/mission-control/setup-mission-control.ps1 -Action up
```

### Linux / WSL (Bash) — inalterado

```bash
./projetos/crawlseo/setup-crawlseo.sh
./projetos/mission-control/setup-mission-control.sh
./projetos/open-notebook/setup-open-notebook.sh
```

## Logs

Cada execução grava um log em `logs/` dentro da pasta do projeto:

- `.ps1`: `logs/setup-wslc-YYYYMMDD-HHMMSS.log`
- `.sh`: `logs/setup-YYYYMMDD-HHMMSS.log`
- limpeza: `projetos/logs/wslc-clean-YYYYMMDD-HHMMSS.log`

## Requisitos

- **Windows**: PowerShell 7+ e `wslc.exe` (WSL 3.0.5+; atualize com `wsl --update`)
- **Git** no PATH para o `git clone`
- **Linux/WSL**: `docker` ou `finch` com o plugin `compose`
