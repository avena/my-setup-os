# Qdrant — busca semântica de código e memória

O Qdrant **não gera embeddings**: ele armazena vetores e busca por similaridade. Quem gera o
vetor é um modelo de embedding — aqui, o **9Router** local (`/v1/embeddings`, compatível com OpenAI).

```text
OpenCode ──MCP stdio──> shared/mcp/qdrant/mcp-server.py
                              ├─> 9Router 127.0.0.1:20128/v1/embeddings   (gera o vetor)
                              └─> Qdrant (Cloud ou docker)                 (guarda e busca)
```

Ferramentas expostas ao agente:

| Tool | O que faz |
|---|---|
| `qdrant-store` | Gera o embedding de um trecho e faz upsert |
| `qdrant-find` | Busca semântica ("onde o cache é invalidado") |
| `qdrant-info` | Nome da collection, nº de pontos, dimensão |

## 1. Instalar/registrar no OpenCode

Pré-requisitos: `uv`, `python3` e um 9Router respondendo em `ROUTER_BASE_URL`.

```bash
cp shared/mcp/qdrant/.env.example ~/.config/opencode/.env.mcp   # se ainda não existir
# edite QDRANT_URL / QDRANT_API_KEY / ROUTER_API_KEY

bash linux/cli/install-qdrant-mcp.sh
```

O script injeta em `~/.config/opencode/opencode.json` (com backup):

```json
"qdrant": {
  "type": "local",
  "command": ["uv", "run", "--with", "openai", "--with", "qdrant-client",
              "python3", "/caminho/para/shared/mcp/qdrant/mcp-server.py"],
  "environment": {
    "OPENAI_API_KEY": "<ROUTER_API_KEY>",
    "OPENAI_BASE_URL": "http://127.0.0.1:20128/v1",
    "OPENAI_EMBEDDING_MODEL": "gemini/gemini-embedding-001",
    "QDRANT_URL": "http://localhost:6333",
    "QDRANT_API_KEY": "",
    "COLLECTION_NAME": "codebase",
    "EMBEDDING_DIMS": "3072"
  },
  "enabled": true,
  "timeout": 30000
}
```

Reinicie o OpenCode e rode `qdrant-info` para confirmar.

## 2. Qdrant local (opcional)

Use local para testar sem nuvem:

```bash
docker run -d --name qdrant -p 6333:6333 -p 6334:6334 \
  -v "$PWD/qdrant_storage:/qdrant/storage" qdrant/qdrant
# REST: http://localhost:6333 · dashboard: http://localhost:6333/dashboard
```

A collection é criada automaticamente na primeira conexão, com `EMBEDDING_DIMS` e distância Cosine.

> A dimensão precisa bater com o modelo. `gemini-embedding-001` = **3072**.
> Trocar de modelo/dimensão exige **outra collection** — `size` não é alterável.

## 3. Uso pelo agente

```text
"Indexe esta função no Qdrant com metadata {file, symbol}."
"Onde fica a lógica de exclusão de calagem? Busque no Qdrant."
```

Bom para busca conceitual. Para nome exato de símbolo, string literal ou import, `grep`/`rg`
continua mais preciso — use os dois em conjunto.

## 4. Sem MCP (REST ou Python)

```bash
# upsert de um ponto (vetor já calculado)
curl -X PUT "$QDRANT_URL/collections/codebase/points" \
  -H "api-key: $QDRANT_API_KEY" -H 'Content-Type: application/json' \
  -d '{"points":[{"id":"uuid-estavel","vector":[...],"payload":{"file":"src/x.py"}}]}'

# busca
curl -X POST "$QDRANT_URL/collections/codebase/points/search" \
  -H "api-key: $QDRANT_API_KEY" -H 'Content-Type: application/json' \
  -d '{"vector":[...],"limit":5,"with_payload":true}'
```

```python
from openai import OpenAI
from qdrant_client import QdrantClient

vec = OpenAI(base_url="http://127.0.0.1:20128/v1", api_key=KEY) \
    .embeddings.create(model="gemini/gemini-embedding-001", input="texto").data[0].embedding

qc = QdrantClient(url="http://localhost:6333")
qc.upsert(collection_name="codebase",
          points=[{"id": "uuid-estavel", "vector": vec, "payload": {"texto": "texto"}}])
qc.query_points(collection_name="codebase", query=vec, limit=5)
```

IDs estáveis tornam o upsert idempotente: reindexar sobrescreve em vez de duplicar. Para volume,
envie em lotes e use `wait=false`, com `wait=true` no último.

## 5. Indexar um repositório inteiro

O MCP indexa **sob demanda** (`qdrant-store`). Para indexação em massa, use o script do
[`9router/embedding`](https://github.com/avena/9router) (bulk index) ou um loop próprio que
quebre os arquivos em chunks de ~60 linhas, gere embeddings em lote e faça upsert com
`file_path`/`start_line`/`end_line` no payload — assim `qdrant-find` devolve o trecho já citável.

## Checklist

- [ ] `qdrant-info` responde no OpenCode
- [ ] `qdrant-store` seguido de `qdrant-find` devolve o trecho gravado
- [ ] `EMBEDDING_DIMS` igual à dimensão do modelo e da collection
- [ ] `QDRANT_API_KEY` presente quando o cluster é Cloud
