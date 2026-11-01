#!/usr/bin/env bash
# ==============================================================================
# setup-mcps.sh - Gerenciador e Instalador de Servidores MCP para OpenCode
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates/mcp"
OPENCODE_GLOBAL="$HOME/.config/opencode/opencode.json"
ENV_FILE="$HOME/.config/opencode/.env.mcp"

check_dependencies() {
  echo "==> Verificando dependências de runtime..."
  local missing=()
  for cmd in node npx python3 uv jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    else
      echo "  [OK] $cmd: $(command -v "$cmd")"
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "  [AVISO] Ferramentas ausentes: ${missing[*]}"
  else
    echo "  [OK] Todas as dependências essenciais estão instaladas."
  fi
}

init_env() {
  echo "==> Inicializando arquivo de ambiente .env.mcp..."
  mkdir -p "$(dirname "$ENV_FILE")"
  if [ -f "$ENV_FILE" ]; then
    echo "  [INFO] $ENV_FILE já existe. Preservando conteúdo atual."
  else
    cp "$TEMPLATES_DIR/.env.mcp.example" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "  [CRIADO] $ENV_FILE criado com permissões 600. Preencha seus tokens lá."
  fi
}

check_syntax() {
  echo "==> Validando sintaxe dos templates JSONC de MCP..."
  local err=0
  for f in "$TEMPLATES_DIR"/*.jsonc; do
    [ -f "$f" ] || continue
    if node -e '
      const fs = require("fs");
      const content = fs.readFileSync(process.argv[1], "utf8").replace(/(^|[^\:])\/\/.*$/gm, "$1");
      JSON.parse(content);
    ' "$f" >/dev/null 2>&1; then
      echo "  [VÁLIDO] $(basename "$f")"
    else
      echo "  [ERRO] $(basename "$f") possui JSON inválido!"
      err=$((err + 1))
    fi
  done
  return $err
}

apply_profile() {
  local profile="${1:-}"
  local target="${2:-$OPENCODE_GLOBAL}"

  if [ -z "$profile" ]; then
    echo "Uso: $0 apply <web|backend|scraping|productivity|full> [caminho_opencode.json]"
    exit 1
  fi

  local profile_file=""
  case "$profile" in
    web) profile_file="$TEMPLATES_DIR/mcp-web.jsonc" ;;
    backend) profile_file="$TEMPLATES_DIR/mcp-backend.jsonc" ;;
    scraping) profile_file="$TEMPLATES_DIR/mcp-scraping.jsonc" ;;
    productivity) profile_file="$TEMPLATES_DIR/mcp-productivity.jsonc" ;;
    full) profile_file="$TEMPLATES_DIR/mcp-full.jsonc" ;;
    *)
      echo "Perfil desconhecido: '$profile'. Opções: web, backend, scraping, productivity, full."
      exit 1
      ;;
  esac

  if [ ! -f "$profile_file" ]; then
    echo "Erro: Arquivo do perfil $profile_file não encontrado!"
    exit 1
  fi

  if [ ! -s "$target" ]; then
    echo "Criando novo arquivo de configuração em $target..."
    mkdir -p "$(dirname "$target")"
    echo '{"$schema":"https://opencode.ai/config.json","mcp":{}}' > "$target"
  fi

  echo "==> Mesclando perfil '$profile' em $target..."
  local backup="$target.bak.$(date +%Y%m%d%H%M%S)"
  cp "$target" "$backup"

  # Mescla no nível do nó "mcp" preservando outras configurações do OpenCode
  node -e '
    const fs = require("fs");
    const targetPath = process.argv[1];
    const profilePath = process.argv[2];

    const cleanJson = (str) => str.replace(/(^|[^\:])\/\/.*$/gm, "$1");
    const target = JSON.parse(cleanJson(fs.readFileSync(targetPath, "utf8")));
    const profile = JSON.parse(cleanJson(fs.readFileSync(profilePath, "utf8")));

    target.mcp = target.mcp || {};
    Object.assign(target.mcp, profile.mcp || {});

    fs.writeFileSync(targetPath, JSON.stringify(target, null, 2) + "\n");
  ' "$target" "$profile_file"

  echo "  [SUCESSO] Perfil '$profile' aplicado com sucesso! Backup em $backup"
}

list_profiles() {
  echo "Perfis de MCP disponíveis:"
  echo "  - web: Ferramentas de frontend e browser (Chrome DevTools, Playwright, React, Proxyman, Netlify)"
  echo "  - backend: Bancos de dados e frameworks (Neon Postgres, MySQL, Laravel Codebase, Laravel Companion)"
  echo "  - scraping: Web crawling e buscas (Open Crawler, Google Search, HasData, Yahoo Finance)"
  echo "  - productivity: Tarefas, PRs e notas (GitHub, Notion, Todoist, Atlassian, Evernote, Obsidian, NotebookLM)"
  echo "  - full: Todos os servidores MCP catalogados"
}

case "${1:-status}" in
  check|deps)
    check_dependencies
    ;;
  check-syntax)
    check_syntax
    ;;
  init-env)
    init_env
    ;;
  profiles)
    list_profiles
    ;;
  apply)
    shift
    apply_profile "$@"
    ;;
  status)
    check_dependencies
    echo ""
    check_syntax
    echo ""
    init_env
    echo ""
    list_profiles
    echo ""
    echo "Para aplicar um perfil: $0 apply <nome_do_perfil>"
    ;;
  *)
    echo "Comando desconhecido: $1"
    echo "Uso: $0 [status|check|check-syntax|init-env|profiles|apply <perfil>]"
    exit 1
    ;;
esac
