"""QGIS MCP bridge — abre um socket TCP para o MCP do WSL controlar o QGIS.

Como rodar (Windows):
  1. QGIS > Plugins > Python Console
  2. Cole:  exec(open(r"C:\\caminho\\qgis_mcp_bridge.py", encoding="utf-8").read())
     (ou copie o conteúdo inteiro no console e dê Enter)
  Alternativa: iniciar o QGIS já com o bridge, via atalho:
     qgis-bin.exe --code C:\\caminho\\qgis_mcp_bridge.py

Variáveis de ambiente (defina ANTES de abrir o QGIS, ou edite as constantes):
  QGIS_MCP_HOST   default 0.0.0.0  (precisa ser 0.0.0.0 para o WSL enxergar)
  QGIS_MCP_PORT   default 9874
  QGIS_MCP_TOKEN  default vazio -> qualquer host da rede do WSL pode executar código

Protocolo: JSON por linha. Requisição {"op": "ping"|"layers"|"execute", "code": "...", "token": "..."}
Resposta {"ok": true, ...} ou {"ok": false, "error": "..."}
"""
import contextlib
import io
import json
import os
import socket
import threading
import traceback

HOST = os.environ.get("QGIS_MCP_HOST", "0.0.0.0")
PORT = int(os.environ.get("QGIS_MCP_PORT", "9874"))
TOKEN = os.environ.get("QGIS_MCP_TOKEN", "")

_PRELUDE = """from qgis.core import *
from qgis.gui import *
from qgis.utils import iface
from qgis.PyQt.QtCore import *
from qgis.PyQt.QtGui import *
from qgis.PyQt.QtWidgets import *
"""


def _on_main_thread(fn, timeout=120):
    """Executa fn na thread principal do QGIS (chamadas de GUI fora dela travam/crasham)."""
    from qgis.PyQt.QtCore import QTimer

    done, box = threading.Event(), {}

    def runner():
        try:
            box["value"] = fn()
        except Exception:
            box["error"] = traceback.format_exc()
        finally:
            done.set()

    QTimer.singleShot(0, runner)
    if not done.wait(timeout):
        raise TimeoutError("thread principal do QGIS ocupada (diálogo modal aberto?)")
    if "error" in box:
        raise RuntimeError(box["error"])
    return box["value"]


def _execute(code):
    def run():
        from qgis.core import Qgis

        ns = {"__name__": "__main__", "qgis_version": Qgis.QGIS_VERSION}
        exec(_PRELUDE, ns)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
            exec(code, ns)
        out = buf.getvalue()
        value = ns.get("result")
        return {"ok": True, "stdout": out, "result": "" if value is None else repr(value)}

    return _on_main_thread(run)


def _layers():
    def run():
        from qgis.core import QgsProject

        layers = []
        for lid, layer in QgsProject.instance().mapLayers().items():
            layers.append({"id": lid, "name": layer.name(), "type": layer.type().name,
                           "crs": layer.crs().authid()})
        return {"ok": True, "layers": layers}

    return _on_main_thread(run)


def _ping():
    from qgis.core import Qgis

    return {"ok": True, "qgis": Qgis.QGIS_VERSION, "port": PORT}


def handle(payload):
    if TOKEN and payload.get("token") != TOKEN:
        return {"ok": False, "error": "token inválido"}
    op = payload.get("op")
    if op == "ping":
        return _ping()
    if op == "layers":
        return _layers()
    if op == "execute":
        return _execute(payload.get("code") or "")
    return {"ok": False, "error": f"op desconhecida: {op!r} (use ping|layers|execute)"}


def _serve(client):
    with client:
        f = client.makefile("rwb")
        for line in f:
            try:
                payload = json.loads(line.decode("utf-8"))
                resp = handle(payload)
            except Exception:
                resp = {"ok": False, "error": traceback.format_exc(limit=5)}
            f.write(json.dumps(resp).encode("utf-8") + b"\n")
            f.flush()


_started = []


def start():
    if _started:
        print(f"[qgis-mcp] já está escutando em {_started[0]}")
        return
    if not TOKEN and HOST not in ("127.0.0.1", "localhost"):
        print("[qgis-mcp] AVISO: sem QGIS_MCP_TOKEN, qualquer máquina da rede do WSL "
              "pode executar código no QGIS. Defina o token em produção.")
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(4)
    _started.append(f"{HOST}:{PORT}")
    print(f"[qgis-mcp] escutando em {HOST}:{PORT}")
    while True:
        client, addr = server.accept()
        threading.Thread(target=_serve, args=(client,), daemon=True).start()


threading.Thread(target=start, daemon=True).start()
