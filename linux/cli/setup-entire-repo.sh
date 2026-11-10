#!/usr/bin/env bash
# setup-entire-repo.sh - liga um clone git existente ao Entire (idempotente)
#
# Faz o que o `entire enable` sozinho nao faz e o que o `.entire/settings.local.json`
# (ignorado pelo git) perde em clones novos:
#   1. cria (opcional) o repositorio nativo no forge Entire
#   2. adiciona o remote "entire" SEM tocar no "origin" (GitHub continua intacto)
#   3. habilita checkpoints apontando para esse remote
#   4. constroi o brain local sem backfill/daemon (opcional)
#   5. verifica o resultado
#
# Uso:
#   bash linux/cli/setup-entire-repo.sh --project avena --repo my-setup-os [opcoes]
#   bash linux/cli/setup-entire-repo.sh --project avena --repo my-setup-os --create
#   bash linux/cli/setup-entire-repo.sh --dir ~/outro-repo        # usa o remote entire existente
#
# Opcoes:
#   --project <proj>    projeto no forge Entire (ex.: avena)
#   --repo <repo>       nome do repositorio (ex.: my-setup-os)
#   --dir <caminho>     clone a configurar (padrao: diretorio atual)
#   --remote <nome>     nome do remote do Entire (padrao: entire)
#   --agent <nome>      agente a habilitar (padrao: opencode)
#   --create            cria o repositorio no forge antes de configurar
#   --visibility <v>    private|public para --create (padrao: private)
#   --skip-brain        nao roda 'entire brain setup'
#   --no-backfill       nao gasta tokens no brain setup (padrao: ligado)
#   --dry-run           mostra os comandos sem executar
#   -h, --help          mostra esta ajuda
#
# Detalhes: docs/entire.md

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

PROJECT=""; REPO_NAME=""; DIR="$PWD"; REMOTE="entire"; AGENT="opencode"
CREATE=0; VISIBILITY="private"; SKIP_BRAIN=0; NO_BACKFILL=1; DRY_RUN=0

usage() { sed -n '2,34p' "$0" | sed 's/^# \{0,1\}//'; }
die()   { echo -e "${RED}[ERRO] $*${NC}" >&2; exit 1; }
info()  { echo -e "${CYAN}>> $*${NC}"; }
ok()    { echo -e "${GREEN}[OK] $*${NC}"; }
warn()  { echo -e "${YELLOW}[WARN] $*${NC}"; }

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "   [dry-run] $*"
  else
    "$@"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)     PROJECT="${2:-}"; shift 2 ;;
    --repo)        REPO_NAME="${2:-}"; shift 2 ;;
    --dir)         DIR="${2:-}"; shift 2 ;;
    --remote)      REMOTE="${2:-}"; shift 2 ;;
    --agent)       AGENT="${2:-}"; shift 2 ;;
    --create)      CREATE=1; shift ;;
    --visibility)  VISIBILITY="${2:-}"; shift 2 ;;
    --skip-brain)  SKIP_BRAIN=1; shift ;;
    --no-backfill) NO_BACKFILL=1; shift ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *)             die "opcao desconhecida: $1 (use --help)" ;;
  esac
done

export PATH="$HOME/.local/bin:$PATH"
hash -r 2>/dev/null || true

# ── Pre-checks ──────────────────────────────────────────────────────────────
command -v entire >/dev/null 2>&1 || die "Entire CLI nao encontrado. Rode: bash linux/cli/install-entire.sh"
command -v git    >/dev/null 2>&1 || die "git nao encontrado"
[[ -d "$DIR/.git" ]] || die "'$DIR' nao e um repositorio git (ou e um worktree sem .git)"

if ! entire auth status >/dev/null 2>&1; then
  warn "CLI nao autenticada. Rode 'entire login' (ou 'entire login --device' em SSH) e repita."
  exit 1
fi

cd "$DIR"

# ── 1. Remote do Entire (nunca sobrescreve o origin) ────────────────────────
EXISTING_URL="$(git remote get-url "$REMOTE" 2>/dev/null || true)"

if [[ -n "$EXISTING_URL" ]]; then
  ok "Remote '$REMOTE' ja existe: $EXISTING_URL"
else
  [[ -n "$PROJECT" && -n "$REPO_NAME" ]] || \
    die "sem remote '$REMOTE': informe --project e --repo (ou crie o remote manualmente)"

  if [[ "$CREATE" -eq 1 ]]; then
    info "Criando repositorio no forge Entire: /et/$PROJECT/$REPO_NAME ($VISIBILITY)"
    run entire repo create "$REPO_NAME" --project "$PROJECT" --visibility "$VISIBILITY"
  fi

  info "Adicionando remote '$REMOTE' -> /et/$PROJECT/$REPO_NAME"
  run entire repo remote add "$REMOTE" "/et/$PROJECT/$REPO_NAME"
fi

# ── 2. Habilitar checkpoints apontando para o remote do Entire ──────────────
info "Habilitando checkpoints (agent=$AGENT, push para '$REMOTE')"
run entire enable -y --agent "$AGENT" --checkpoint-push-remote "$REMOTE"

# ── 3. Brain local (sem tokens) ─────────────────────────────────────────────
if [[ "$SKIP_BRAIN" -eq 0 ]]; then
  if entire plugin list 2>/dev/null | grep -qE '^[[:space:]]*brain[[:space:]]'; then
    info "Construindo brain local (sem backfill, sem daemon)"
    run entire brain setup --no-backfill --no-daemon
  else
    warn "Plugin brain ausente. Rode 'entire plugin install brain' e depois 'entire brain setup'."
  fi
fi

# ── 4. Verificacao ──────────────────────────────────────────────────────────
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo
  warn "dry-run: nada foi alterado."
  exit 0
fi

echo
echo "=== remotes ==="
git remote -v
echo "=== entire status ==="
entire status 2>&1 | head -6

if entire status 2>&1 | grep -q "Checkpoints sync to: $REMOTE"; then
  ok "Checkpoints sincronizando em '$REMOTE'."
else
  warn "Nao confirmei o destino dos checkpoints. Confira 'entire status'."
fi

if [[ -n "$(git status --porcelain)" ]]; then
  warn "Worktree sujo: o seed do brain falha com mudancas nao commitadas."
  echo "     Commit/stash ou liste os caminhos em .brainignore e rode 'entire brain refresh --agent none'."
fi

echo
echo "Proximo passo: git push $REMOTE $(git rev-parse --abbrev-ref HEAD)"
