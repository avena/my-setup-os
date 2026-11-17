# CodeBuddy — modelos customizados via 9Router

Referência do `~/.codebuddy/models.json`: como o CodeBuddy enxerga os modelos, o papel do
gateway local **9Router** e o provedor **Alibaba Token Plan** (último configurado).

Cópia versionada do arquivo ativo (87 modelos): [`shared/templates/codebuddy/models.json`](../shared/templates/codebuddy/models.json).

```text
CodeBuddy ──OpenAI chat/completions──> 9Router 127.0.0.1:20128
                                        ├─ prefixo nvidia/     → NVIDIA NIM
                                        ├─ prefixo openrouter/ → OpenRouter
                                        ├─ prefixo alib/       → Alibaba Token Plan
                                        └─ ... (demais provedores conectados)
```

## 1. Formato do arquivo

- **Linux/WSL:** `~/.codebuddy/models.json` · **Windows:** `%USERPROFILE%\.codebuddy\models.json`
- Cada entrada é um modelo customizado apontando para um endpoint OpenAI-compatível:

```json
{
  "models": [
    {
      "id": "alib/qwen3.8-max",
      "name": "9router",
      "url": "http://127.0.0.1:20128/v1/chat/completions",
      "apiKey": "<chave do gateway 9router>",
      "maxInputTokens": 1000000
    }
  ]
}
```

- `id` = `<prefixo>/<modelo>` — o **prefixo decide o provedor** dentro do 9Router.
- `name` é só o rótulo exibido na UI (aqui, todos `"9router"`).
- `apiKey` é a chave **do gateway local**, não a do provedor final. As chaves upstream
  (OpenRouter, NVIDIA, Token Plan `sk-sp-…`, OAuth do CodeBuddy/Cline/Kilo) ficam no
  9Router (`~/.9router/db/data.sqlite`, tabela `providerConnections`).

## 2. Estado atual (2026-11-16)

**87 modelos, todos apontando para `http://127.0.0.1:20128/v1/chat/completions`**, mesma chave.

| Prefixo | Qtd | Provedor no 9Router | Observações |
|---|---|---|---|
| `alib/` | 23 | **Token Plan (Alibaba)** | `maxInputTokens: 1000000`; ver §3 |
| `nvidia/` | 16 | NVIDIA NIM | ids com duplo namespace, ex. `nvidia/nvidia/nemotron-3-ultra-550b-a55b` |
| `openrouter/` | 14 | OpenRouter | sufixos `:free` / `:floor` (roteamento de menor custo) |
| `oc/` | 12 | OpenCode | modelos free do ecossistema OpenCode |
| `kc/` | 10 | Kilo Code | inclui `kc/kilo-auto/free` |
| `cbai/` | 8 | CodeBuddy intl (OAuth) | caminho normal do CodeBuddy; token renovado pelo 9Router |
| `mmg/` | 3 | MiniMax (code global) | `MiniMax-M3`, `M3.1-Flash`, `M3.1-Flash-Preview` |
| `cl/` | 1 | Cline | `cl/cline-free/solar-mini4` |

## 3. Alibaba Token Plan (`alib/`) — último provedor configurado

Conexão openai-compatible registrada no 9Router como **"Token Plan"**:

- **Base URL upstream:** `https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1`
- **Prefixo:** `alib` · **Modelo padrão:** `qwen4-max-preview` · **Chave:** `sk-sp-…` (no banco do 9Router)
- Chat: `qwen3.7-max/plus`, `qwen3.8-max/flash`, `qwen4-max(-preview)`, `glm-5.2/5.3`,
  `deepseek-v4-pro(-0813)`, `deepseek-v4.1-flash(-1017)`, `deepseek-v4-flash-0731`, `gpt-4o`, `auto`.
- Multimodais também registrados como entradas de chat: `wan2.7-image(-pro)`, `wan3.0-video`,
  `qwen-image-3.0-pro`, `qwen-audio-3.0-tts-plus`, `qwen-audio-3.0-asr-flash`,
  `qwen-audio-3.0-realtime-plus`. **Atenção:** imagem/vídeo/áudio podem exigir endpoints
  próprios do DashScope — a entrada via `chat/completions` só funciona se o backend aceitar.

### Histórico da migração

Antes, os 23 `alib/*` apontavam **direto** para a URL da Alibaba (64 modelos no gateway + 23 diretos).
Em 2026-11-16 foram migrados para o gateway: o 9Router já servia os `alib/*` no `GET /v1/models`,
então bastou trocar `url` e `apiKey` nas 23 entradas → **87/87 no mesmo gateway**.

## 4. Uso e manutenção

```bash
# Subir o gateway (repo ~/9router, estado ~/.9router)
~/9router/start.sh            # --status | --restart | --stop

# Conferir o que o gateway serve
curl -s http://127.0.0.1:20128/v1/models -H "Authorization: Bearer <chave>" | jq '.data[].id'

# Sanidade do models.json (contagem por prefixo e URLs)
python3 -c "import json,collections as c; m=json.load(open('$HOME/.codebuddy/models.json'))['models']; \
print(len(m), c.Counter(x['id'].split('/')[0] for x in m), c.Counter(x['url'] for x in m))"

# Restaurar a cópia versionada
cp shared/templates/codebuddy/models.json ~/.codebuddy/models.json
```

### Windows (`%USERPROFILE%\.codebuddy\models.json`)

O arquivo é o **mesmo** do Linux (87 modelos, todos em `http://127.0.0.1:20128`).
A ponte até o gateway roda no WSL é um **portproxy** do Windows:

```text
CodeBuddy (Windows) → 127.0.0.1:20128 → portproxy → <IP do WSL>:20128 → 9Router
```

O IP do WSL muda a cada reboot, então o portproxy precisa ser recriado:

```powershell
# PowerShell como Administrador
cd windows\networking
.\forward-9router.ps1          # descobre o IP, recria o portproxy e testa /v1/models
```

Como escuta em `127.0.0.1` (loopback), não precisa de regra de firewall no Windows.

```powershell
# Copiar a versão versionada para o perfil do Windows
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codebuddy" | Out-Null
Copy-Item shared\templates\codebuddy\models.json "$env:USERPROFILE\.codebuddy\models.json" -Force
```

> O `%USERPROFILE%\.codebuddy\models-README.txt` no Windows documenta o mesmo fluxo
> (portproxy, teste, firewall) para consulta sem o repo à mão.

**Adicionar um modelo:** nova entrada com `id = <prefixo>/<modelo>`, `url` e `apiKey` do gateway.
O prefixo precisa existir como conexão no 9Router; para um provedor novo, registre a conexão
openai-compatible lá (definindo `prefix` e `baseUrl`) antes de adicionar entradas aqui.

> A cópia em `shared/templates/codebuddy/` contém a chave do gateway local (não as chaves
> upstream). Se o repo for publicado, troque a chave por placeholder antes.

## Relacionados

- [`docs/qdrant.md`](qdrant.md) — embeddings via o mesmo 9Router (`/v1/embeddings`).
- [`docs/references/projetos-e-ferramentas.md`](references/projetos-e-ferramentas.md) — catálogo de ferramentas (open-notebook etc. usam o gateway).
