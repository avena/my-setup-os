# Open Notebook - Setup em Container

Implementação open-source, privada e auto-hospedada do **Google NotebookLM** criada por [@lfnovo](https://github.com/lfnovo/open-notebook).
Suporta múltiplos provedores de IA (OpenAI, Anthropic, Google, Groq, Ollama, 9Router e qualquer endpoint OpenAI-compatible), geração de podcasts com 1 a 4 participantes, anotações inteligentes, busca vetorial e armazenamento local em SurrealDB.

## Portas e Serviços
- **Web UI:** `http://localhost:8502`
- **REST API:** `http://localhost:5055`
- **SurrealDB (Debug local):** `127.0.0.1:8000`

## Pontos Críticos de Atenção
1. **Chave de Criptografia (`OPEN_NOTEBOOK_ENCRYPTION_KEY`):**
   O script gera automaticamente um hash aleatório de 32 bytes (`openssl rand -hex 32`) no `.env`. Essa chave é usada para criptografar as chaves de API dos provedores no banco de dados. **Nunca altere essa chave após o primeiro uso**, senão o sistema não conseguirá descriptografar os provedores configurados.
2. **Filesystem Nativo WSL (ext4):**
   O SurrealDB usa RocksDB para armazenamento de dados em `./surreal_data`. **Nunca rode em `/mnt/c/`**, pois a ponte 9P corrompe o lock de arquivos do RocksDB e degrada a velocidade de busca vetorial. Mantenha em `~/projetos/open-notebook`.
3. **Provedores de IA:**
   Ao acessar `http://localhost:8502`, vá em **Manage → Models** e configure seu provedor favorito (chave de API para nuvem ou a URL local do Ollama/9Router).

## Como Executar

Existem duas formas. Escolha **uma** — elas usam runtimes diferentes e não
compartilham imagens, containers nem dados.

### Opção A — `wslc.exe` (runtime nativo de containers do WSL)

Não depende de Docker Engine nem de distro Linux instalada. Requer WSL >= 2.9.3
(`wsl --version`; atualize com `wsl --update`).

```powershell
# subir (padrão: dados em volumes nomeados ext4)
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action up

# portas alternativas (a porta do banco só é publicada com -ExposeDb)
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action up -WebPort 8502 -ApiPort 5055

# publicar o SurrealDB no host para debug (Surrealist / surreal sql)
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action up -ExposeDb -DbPort 8010

# status / logs / parar / remover tudo
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action status
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action logs
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action stop
pwsh ./projetos/open-notebook/setup-open-notebook.ps1 -Action delete
```

Recursos criados (convenção `<projeto>-<função>`):

| Tipo | Nome |
|---|---|
| Container (banco) | `open-notebook-database` |
| Container (app) | `open-notebook-web` |
| Volume (banco) | `open-notebook-database-data` |
| Volume (app) | `open-notebook-web-data` |
| Rede | `open-notebook-network` |

Detalhes de implementação que não são óbvios:

- **`--user root` no SurrealDB é obrigatório.** A imagem roda como uid `65532`,
  mas o volume nomeado é criado como `root:root`. Sem isso o RocksDB falha com
  `Failed to create RocksDB directory: PermissionDenied (os error 13)`.
- **Rede custom é obrigatória.** Na bridge padrão do `wslc` o DNS não resolve
  nome de container (`NXDOMAIN`). O app alcança o banco pelo alias `surrealdb`
  dentro de `open-notebook-network`.
- **`.env.wslc` é gerado sem BOM e com LF.** Com BOM, o `wslc` interpreta o
  byte como parte do nome da primeira variável e
  `OPEN_NOTEBOOK_ENCRYPTION_KEY` chega corrompida.
- **`-Storage bind`** monta `wslc-data\` (NTFS/9P) em vez de volumes. Funciona,
  mas o item 2 dos Pontos Críticos vale: 9P pode corromper o lock do RocksDB.
  Use apenas se precisar abrir os arquivos pelo Explorer.

### Opção B — Docker Engine dentro da distro WSL (legado)

Script mantido como `setup-open-notebook-docker.ps1`. Use apenas se você já tem
containers criados por ele; para instalações novas prefira a Opção A.

```powershell
# Do Windows (PowerShell 7 via WSL)
pwsh ./projetos/open-notebook/setup-open-notebook-docker.ps1
```

```bash
# Do Linux ou WSL nativo (Bash)
./projetos/open-notebook/setup-open-notebook.sh
```

## Logs e Monitoramento

- Logs de setup (`wslc`): `logs/setup-wslc-*.log`
- Logs de setup (Docker): `logs/setup-windows-*.log` e `logs/setup-*.log`

```powershell
# wslc
wslc logs -f open-notebook-web
wslc logs -f open-notebook-database
```

```bash
# Docker dentro da distro
docker compose logs -f open_notebook
docker compose logs -f surrealdb
```
