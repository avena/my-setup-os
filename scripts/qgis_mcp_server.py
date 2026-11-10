#!/usr/bin/env python3
"""Servidor MCP (stdio) que fala com o qgis_mcp_bridge.py rodando dentro do QGIS no Windows.

Uso no opencode.json:
  "command": ["uv","run","--quiet","--with","mcp[cli]<2","python3",
              "/home/livre/my-setup-os/scripts/qgis_mcp_server.py"]

O IP do Windows é o gateway do WSL e muda a cada reboot: se --host não for passado,
o script descobre sozinho (ip route show default). QGIS_MCP_TOKEN opcional.
"""
import argparse
import json
import os
import socket
import subprocess
import sys

from mcp.server.fastmcp import FastMCP

TIMEOUT = 180


def _gateway() -> str:
    out = subprocess.run(["ip", "route", "show", "default"], capture_output=True, text=True).stdout
    parts = out.split()
    return parts[2] if len(parts) > 2 else "127.0.0.1"


def _call(op: str, **kw):
    payload = {"op": op, "token": TOKEN, **kw}
    with socket.create_connection((HOST, PORT), timeout=10) as s:
        s.settimeout(TIMEOUT)
        s.sendall(json.dumps(payload).encode() + b"\n")
        buf = b""
        while not buf.endswith(b"\n"):
            chunk = s.recv(65536)
            if not chunk:
                break
            buf += chunk
    resp = json.loads(buf.decode("utf-8") or "{}")
    if not resp.get("ok"):
        raise RuntimeError(resp.get("error") or f"resposta inesperada: {resp}")
    return resp


parser = argparse.ArgumentParser()
parser.add_argument("--host", default=None, help="IP do Windows (default: gateway do WSL)")
parser.add_argument("--port", type=int, default=9874)
parser.add_argument("--token", default=None)
args = parser.parse_args()

HOST = args.host or _gateway()
PORT = args.port
TOKEN = args.token or os.environ.get("QGIS_MCP_TOKEN", "")

mcp = FastMCP("qgis")


@mcp.tool()
def qgis_ping() -> str:
    """Verifica se o QGIS está aberto com o bridge ativo. Use antes de qualquer outra tool."""
    return json.dumps(_call("ping"), ensure_ascii=False)


@mcp.tool()
def qgis_layers() -> str:
    """Lista camadas do projeto QGIS aberto (id, nome, tipo, CRS)."""
    return json.dumps(_call("layers"), ensure_ascii=False)


@mcp.tool()
def qgis_execute(code: str) -> str:
    """Executa PyQGIS no QGIS aberto. `from qgis.core import *` já está importado.

    Tudo que for printado é retornado; a variável `result` também é devolvida.
    Ex.: processing.run("native:buffer", {...}) e depois print(out["OUTPUT"]).
    """
    resp = _call("execute", code=code)
    out = resp.get("stdout", "")
    if resp.get("result"):
        out += f"\nresult = {resp['result']}"
    return out or "(sem saída)"


if __name__ == "__main__":
    print(f"[qgis-mcp] QGIS em {HOST}:{PORT}", file=sys.stderr)
    mcp.run()
