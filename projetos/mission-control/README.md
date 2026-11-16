# Mission Control - Setup em Container

Control plane self-hosted para coordenar e inspecionar agentes de IA (Claude Code, Codex, OpenClaw, etc.) apoiado em SQLite WAL.

## Portas e Serviços
- **Painel Web:** `http://localhost:3001` (remap de `3000` para evitar conflito com CrawlSEO)
- **Setup do Admin Inicial:** `http://localhost:3001/setup`

## Pontos Críticos
1. **SQLite WAL e Filesystem:** O SQLite com Write-Ahead Logging (`better-sqlite3`) exige suporte nativo a file-locking. **Nunca rode em `/mnt/c/`**. O script clona e roda direto em `~/projetos/mission-control` (ext4).
2. **Dados Persistentes:** Armazenados em `.data/` no diretório nativo do projeto.
3. **Mapeamento de Porta:** Padronizado na porta `3001` no host para permitir rodar simultaneamente ao CrawlSEO.

## Logs
- Logs de setup: `logs/setup-*.log`
- Ver logs dos containers em execução:
  ```bash
  docker compose logs -f
  # ou caso rode via docker run isolado:
  docker logs -f mission-control
  ```
