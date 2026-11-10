#!/usr/bin/env python3
"""
mcp-server.py — MCP Server para Qdrant + 9Router (OpenAI-compatible)

Baseado em steiner385/qdrant-mcp-server, com patches para:
  1. QDRANT_API_KEY — suporte a Qdrant Cloud (original só tinha Docker local)
  2. EMBEDDING_DIMS — dimensão via env (default 3072) em vez de hardcoded 1536
  3. OPENAI_BASE_URL — lido automaticamente pela SDK OpenAI → aponta para 9Router

Arquitetura:
  [OpenCode] → MCP stdio → [este script] → OpenAI SDK → 9Router (:20128/v1/embeddings)
                                             → QdrantClient → Qdrant Cloud (:6333)

Env vars:
  OPENAI_API_KEY         — chave do 9Router
  OPENAI_BASE_URL        — http://127.0.0.1:20128/v1 (9Router)
  OPENAI_EMBEDDING_MODEL — gemini/gemini-embedding-001 (default)
  QDRANT_URL             — https://...cloud.qdrant.io:6333
  QDRANT_API_KEY         — chave do Qdrant Cloud
  COLLECTION_NAME        — codebase (default)
  EMBEDDING_DIMS         — 3072 (default)

Dependências: openai, qdrant-client (instaladas via uv run --with)
"""

import os
import sys
import json
import hashlib
import asyncio
import logging
from typing import List, Dict, Any, Optional

logging.basicConfig(
    level=getattr(logging, os.environ.get("MCP_LOG_LEVEL", "INFO").upper(), logging.INFO),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stderr)],
)
logger = logging.getLogger(__name__)

try:
    from openai import OpenAI
    from qdrant_client import QdrantClient
    from qdrant_client.models import (
        Distance,
        VectorParams,
        PointStruct,
        Filter,
        FieldCondition,
        MatchValue,
    )
except ImportError as e:
    logger.error(f"Pacote não instalado: {e}")
    logger.error("Use: uv run --with openai --with qdrant-client python3 mcp-server.py")
    sys.exit(1)


class MCPServer:
    """MCP server para Qdrant com embeddings via 9Router (OpenAI-compatible)."""

    def __init__(self):
        self.openai_api_key = os.environ.get("OPENAI_API_KEY", "")
        if not self.openai_api_key:
            raise ValueError("OPENAI_API_KEY não definido")

        self.qdrant_url = os.environ.get("QDRANT_URL", "http://localhost:6333")
        self.qdrant_api_key = os.environ.get("QDRANT_API_KEY", "")
        self.collection_name = os.environ.get("COLLECTION_NAME", "codebase")
        self.embedding_model = os.environ.get(
            "OPENAI_EMBEDDING_MODEL", "gemini/gemini-embedding-001"
        )
        self.embedding_dims = int(os.environ.get("EMBEDDING_DIMS", "3072"))

        # OpenAI SDK lê OPENAI_BASE_URL do ambiente automaticamente
        # Se não estiver setado, usar o 9Router como default
        os.environ.setdefault("OPENAI_BASE_URL", "http://127.0.0.1:20128/v1")

        self.openai_client = OpenAI(api_key=self.openai_api_key)

        # QdrantClient — passar api_key se definido (Qdrant Cloud)
        client_kwargs = {"url": self.qdrant_url}
        if self.qdrant_api_key:
            client_kwargs["api_key"] = self.qdrant_api_key
        self.qdrant_client = QdrantClient(**client_kwargs)

        logger.info(
            f"MCP Server init: qdrant={self.qdrant_url}, "
            f"collection={self.collection_name}, "
            f"model={self.embedding_model}, dims={self.embedding_dims}"
        )

        self._ensure_collection()

    def _ensure_collection(self):
        """Garantir que a collection existe com a dimensão correta."""
        try:
            collections = self.qdrant_client.get_collections()
            names = [c.name for c in collections.collections]

            if self.collection_name not in names:
                logger.info(f"Criando collection: {self.collection_name}")
                self.qdrant_client.create_collection(
                    collection_name=self.collection_name,
                    vectors_config=VectorParams(
                        size=self.embedding_dims,
                        distance=Distance.COSINE,
                    ),
                )
                logger.info(
                    f"Collection {self.collection_name} criada — "
                    f"{self.embedding_dims} dims, Cosine"
                )
            else:
                logger.info(f"Collection {self.collection_name} já existe")
        except Exception as e:
            logger.error(f"Erro ao verificar/criar collection: {e}")
            raise

    def get_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Gerar embeddings via 9Router (OpenAI-compatible endpoint)."""
        try:
            response = self.openai_client.embeddings.create(
                model=self.embedding_model,
                input=texts,
            )
            return [data.embedding for data in response.data]
        except Exception as e:
            logger.error(f"Erro ao gerar embeddings: {e}")
            raise

    async def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        method = request.get("method")
        params = request.get("params", {})
        request_id = request.get("id")

        try:
            if method == "initialize":
                return self._handle_initialize(request_id)
            elif method == "notifications/initialized":
                return None  # notification, no response
            elif method == "tools/list":
                return self._handle_tools_list(request_id)
            elif method == "tools/call":
                return await self._handle_tool_call(params, request_id)
            else:
                return self._error_response(request_id, f"Unknown method: {method}")
        except Exception as e:
            logger.error(f"Erro handling request: {e}")
            return self._error_response(request_id, str(e))

    def _handle_initialize(self, request_id: Any) -> Dict[str, Any]:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {
                    "name": "qdrant-9router-mcp",
                    "version": "1.0.0",
                },
            },
        }

    def _handle_tools_list(self, request_id: Any) -> Dict[str, Any]:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "tools": [
                    {
                        "name": "qdrant-store",
                        "description": (
                            "Store code snippet, memory, or information in Qdrant "
                            "for later semantic retrieval. Use when asked to "
                            "remember something or index code."
                        ),
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "content": {
                                    "type": "string",
                                    "description": "Content to store",
                                },
                                "metadata": {
                                    "type": "object",
                                    "description": "Metadata (file, type, etc.)",
                                },
                            },
                            "required": ["content"],
                        },
                    },
                    {
                        "name": "qdrant-find",
                        "description": (
                            "Search for code or memories using semantic similarity. "
                            "Use when you need to find code by meaning, not keywords."
                        ),
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "query": {
                                    "type": "string",
                                    "description": "Natural language search query",
                                },
                                "limit": {
                                    "type": "number",
                                    "description": "Max results (default 10)",
                                },
                            },
                            "required": ["query"],
                        },
                    },
                    {
                        "name": "qdrant-info",
                        "description": "Get collection info (points count, vector size).",
                        "inputSchema": {"type": "object", "properties": {}},
                    },
                ]
            },
        }

    async def _handle_tool_call(
        self, params: Dict[str, Any], request_id: Any
    ) -> Dict[str, Any]:
        tool_name = params.get("name")
        arguments = params.get("arguments", {})

        if tool_name == "qdrant-store":
            result = await self._store(
                content=arguments.get("content"),
                metadata=arguments.get("metadata", {}),
            )
        elif tool_name == "qdrant-find":
            result = await self._search(
                query=arguments.get("query"),
                limit=arguments.get("limit", 10),
            )
        elif tool_name == "qdrant-info":
            result = await self._get_collection_info()
        else:
            return self._error_response(request_id, f"Unknown tool: {tool_name}")

        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "content": [{"type": "text", "text": json.dumps(result, indent=2)}]
            },
        }

    async def _search(self, query: str, limit: int = 10) -> Dict[str, Any]:
        try:
            query_embedding = self.get_embeddings([query])[0]
            # Qdrant client 1.20+: usar query_points em vez de search (depreciado)
            results = self.qdrant_client.query_points(
                collection_name=self.collection_name,
                query=query_embedding,
                limit=limit,
            )
            formatted = []
            for r in results.points:
                formatted.append(
                    {"id": str(r.id), "score": float(r.score), "payload": r.payload}
                )
            return {"query": query, "count": len(formatted), "results": formatted}
        except Exception as e:
            logger.error(f"Search error: {e}")
            return {"error": str(e)}

    async def _store(
        self, content: str, metadata: Dict[str, Any]
    ) -> Dict[str, Any]:
        try:
            embedding = self.get_embeddings([content])[0]
            point_id = hashlib.md5(content.encode()).hexdigest()
            point = PointStruct(
                id=point_id, vector=embedding, payload={**metadata, "content": content}
            )
            self.qdrant_client.upsert(
                collection_name=self.collection_name, points=[point]
            )
            return {"id": point_id, "status": "stored", "metadata": metadata}
        except Exception as e:
            logger.error(f"Store error: {e}")
            return {"error": str(e)}

    async def _get_collection_info(self) -> Dict[str, Any]:
        try:
            info = self.qdrant_client.get_collection(self.collection_name)
            return {
                "name": self.collection_name,
                "points_count": info.points_count,
                "vector_size": self.embedding_dims,
                "distance": "Cosine",
            }
        except Exception as e:
            logger.error(f"Collection info error: {e}")
            return {"error": str(e)}

    def _error_response(self, request_id: Any, message: str) -> Dict[str, Any]:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {"code": -32603, "message": message},
        }


async def main():
    server = MCPServer()
    logger.info("MCP Qdrant+9Router server started")

    import concurrent.futures

    executor = concurrent.futures.ThreadPoolExecutor(max_workers=1)
    loop = asyncio.get_event_loop()

    def read_line():
        return sys.stdin.readline()

    while True:
        try:
            line = await loop.run_in_executor(executor, read_line)
            if not line:
                logger.info("EOF received, shutting down")
                break

            line = line.strip()
            if not line:
                continue

            try:
                request = json.loads(line)
            except json.JSONDecodeError as e:
                error = {
                    "jsonrpc": "2.0",
                    "id": None,
                    "error": {"code": -32700, "message": f"Parse error: {e}"},
                }
                sys.stdout.write(json.dumps(error) + "\n")
                sys.stdout.flush()
                continue

            response = await server.handle_request(request)

            # Notifications (no id) não recebem resposta
            if response is None:
                continue

            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()

        except Exception as e:
            logger.error(f"Error in main loop: {e}", exc_info=True)
            error = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32603, "message": f"Internal error: {e}"},
            }
            sys.stdout.write(json.dumps(error) + "\n")
            sys.stdout.flush()

    executor.shutdown(wait=True)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--test":
        logger.info("Test mode")
        logger.info(f"OPENAI_API_KEY set: {bool(os.environ.get('OPENAI_API_KEY'))}")
        logger.info(f"OPENAI_BASE_URL: {os.environ.get('OPENAI_BASE_URL', 'default')}")
        logger.info(f"QDRANT_URL: {os.environ.get('QDRANT_URL', 'localhost')}")
        logger.info(f"COLLECTION_NAME: {os.environ.get('COLLECTION_NAME', 'codebase')}")
        logger.info(f"MODEL: {os.environ.get('OPENAI_EMBEDDING_MODEL', 'default')}")
        try:
            s = MCPServer()
            logger.info("Server initialized successfully")
            sys.exit(0)
        except Exception as e:
            logger.error(f"Failed: {e}")
            sys.exit(1)

    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Server stopped")
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)
