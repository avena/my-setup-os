#!/bin/bash
# top-clis.sh - simples, rapido, texto puro, com sudo quando precisar
# TOP 26 CLIs IA/CODING 2026
# Comunitarios (nao oficiais): #23 OpenClaude, #24 ZAI CLI, #26 Top100CLIs

declare -A N=([1]="Claude Code" [2]="Kilo Code" [3]="Aider" [4]="Gemini CLI" [5]="Codex CLI" [6]="OpenCode" [7]="Qwen Code" [8]="Crush CLI" [9]="Plandex" [10]="Goose" [11]="Amazon Q CLI" [12]="Vibe CLI" [13]="Cline" [14]="Bolt CLI" [15]="PyGPT" [16]="AIChat" [17]="Droid" [18]="Replit Agent" [19]="Tabby CLI" [20]="Kimi Code" [21]="Roo Code" [22]="OpenClaw" [23]="nanocode" [24]="OpenClaude" [25]="ZAI CLI" [26]="Top100CLIs")
declare -A B=([1]="claude-code" [2]="kilo" [3]="aider" [4]="gemini" [5]="codex" [6]="opencode" [7]="qwen" [8]="crush" [9]="plandex" [10]="goose" [11]="amazon-q-cli" [12]="vibe-cli" [13]="cline" [14]="bolt-new" [15]="pygpt" [16]="aichat" [17]="droid-cli" [18]="replit" [19]="tabby" [20]="kimi" [21]="roo-cline" [22]="openclaw" [23]="nanocode" [24]="openclaude" [25]="zai" [26]="top100clis")
declare -A D=([1]="npm" [2]="curl" [3]="pip3" [4]="npm" [5]="npm" [6]="curl" [7]="npm" [8]="apt" [9]="curl" [10]="curl" [11]="pip3" [12]="npm" [13]="npm" [14]="npm" [15]="pip3" [16]="npm" [17]="cargo" [18]="npm" [19]="docker" [20]="curl" [21]="npm" [22]="curl" [23]="pip3" [24]="npm" [25]="npm" [26]="curl")
declare -A C=(
  [1]='npm i -g claude-code'
  [2]='mkdir -p ~/.kilo/bin && curl -sSfL https://github.com/Kilo-Org/kilocode/releases/latest/download/kilo-linux-amd64 -o ~/.kilo/bin/kilo && chmod +x ~/.kilo/bin/kilo && grep -q ".kilo/bin" ~/.bashrc || echo "export PATH=\$HOME/.kilo/bin:\$PATH" >> ~/.bashrc'
  [3]='pip3 install --user aider-chat'
  [4]='npm i -g @google/gemini-cli'
  [5]='npm i -g @openai/codex'
  [6]='mkdir -p ~/.opencode/bin && curl -sSfL https://github.com/sst/opencode/releases/latest/download/opencode-linux-x64 -o ~/.opencode/bin/opencode && chmod +x ~/.opencode/bin/opencode && grep -q ".opencode/bin" ~/.bashrc || echo "export PATH=\$HOME/.opencode/bin:\$PATH" >> ~/.bashrc'
  [7]='npm i -g @qwen-code/qwen-code'
  [8]='sudo mkdir -p /etc/apt/keyrings && curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg && echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list && sudo apt update -q && sudo apt install -y crush'
  [9]='echo y | curl -sL https://plandex.ai/install.sh | bash'
  [10]='sudo apt install -y bzip2 && curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash'
  [11]='pip3 install --user amazon-q-cli'
  [12]='npm i -g vibe-cli'
  [13]='npm i -g cline@latest'
  [14]='npm i -g bolt-new'
  [15]='pip3 install --user pygpt-net'
  [16]='npm i -g aichat'
  [17]='curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && source ~/.cargo/env && cargo install droid-cli'
  [18]='npm i -g @replit/agent'
  [19]='docker pull tabbyml/tabby && docker run -d -p 8080:8080 --name tabby tabbyml/tabby'
  [20]='curl -L code.kimi.com/install.sh | bash'
  [21]='npm i -g roo-cline'
  [22]='curl -fsSL https://openclaw.dev/install.sh | bash'
  [23]='pip3 install --user nanocode'
  [24]='npm i -g @gitlawb/openclaude'
  [25]='npm i -g @guizmo-ai/zai-cli'
  [26]='curl -sSfL https://github.com/jaymeg/top100clis/releases/latest/download/top100clis -o /tmp/top100clis && sudo mv /tmp/top100clis /usr/local/bin/top100clis && sudo chmod +x /usr/local/bin/top100clis'
)
# Tipo: oficial ou comunitario (nao oficial)
declare -A T=([1]="oficial" [2]="oficial" [3]="oficial" [4]="oficial" [5]="oficial" [6]="oficial" [7]="oficial" [8]="oficial" [9]="oficial" [10]="oficial" [11]="oficial" [12]="oficial" [13]="oficial" [14]="oficial" [15]="oficial" [16]="oficial" [17]="oficial" [18]="oficial" [19]="oficial" [20]="oficial" [21]="oficial" [22]="oficial" [23]="oficial" [24]="comunitario" [25]="comunitario" [26]="comunitario")

echo_sudo_notice() {
  echo "este script pode pedir sudo para apt, docker e alteracoes no sistema."
}

setup_npm_user() {
  command -v npm >/dev/null 2>&1 || return 0
  npm config set prefix ~/.npm-global >/dev/null 2>&1
  mkdir -p ~/.npm-global/bin
  grep -q '.npm-global/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
}

reload_path() {
  export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.kilo/bin:$HOME/.opencode/bin:$HOME/.cargo/bin:/usr/local/bin:$PATH"
  if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" 2>/dev/null
  fi
  hash -r 2>/dev/null
}

check_dep() {
  case "$1" in
    npm)
      if ! command -v npm >/dev/null 2>&1; then
        echo ">> precisa de node/npm. vai pedir sudo."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs || return 1
      fi
      setup_npm_user
      reload_path
      ;;
    pip3)
      if ! command -v pip3 >/dev/null 2>&1; then
        echo ">> precisa de pip3. vai pedir sudo."
        sudo apt install -y python3-pip || return 1
      fi
      ;;
    cargo)
      if ! command -v cargo >/dev/null 2>&1; then
        echo ">> precisa de rust/cargo. sem sudo."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || return 1
        [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      fi
      reload_path
      ;;
    docker)
      if ! command -v docker >/dev/null 2>&1; then
        echo ">> precisa de docker. vai pedir sudo."
        curl -fsSL https://get.docker.com | sudo sh || return 1
      fi
      ;;
    curl)
      command -v curl >/dev/null 2>&1 || { echo ">> precisa de curl. vai pedir sudo."; sudo apt install -y curl || return 1; }
      ;;
    apt)
      command -v apt >/dev/null 2>&1 || { echo "ERR: apt nao disponivel"; return 1; }
      ;;
  esac
}

check_status() {
  reload_path
  echo ""
  echo "TOP 26 CLIs IA/CODING 2026"
  ok=0
  for i in {1..26}; do
    if command -v "${B[$i]}" >/dev/null 2>&1; then
      VER=$("${B[$i]}" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
      printf "[OK] %2d. %-16s v%s\n" "$i" "${N[$i]}" "${VER:-?}"
      ok=$((ok+1))
    elif [ "${B[$i]}" = "tabby" ] && docker ps -a 2>/dev/null | grep -qi tabby; then
      printf "[OK] %2d. %-16s Docker\n" "$i" "${N[$i]}"
      ok=$((ok+1))
    else
      printf "[--] %2d. %-16s\n" "$i" "${N[$i]}"
    fi
  done
  echo "Instalados: $ok / 26"
  echo ""
}

setup_cli() {
  num="$1"
  tipo="${T[$num]:-oficial}"
  echo ""
  echo ">> #$num ${N[$num]} (dep: ${D[$num]}) [$tipo]"
  check_dep "${D[$num]}" || { echo "FAIL dep: ${N[$num]}"; return 1; }
  if eval "${C[$num]}"; then
    reload_path
    if command -v "${B[$num]}" >/dev/null 2>&1; then
      VER=$("${B[$num]}" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
      echo "OK: ${N[$num]} v${VER:-?}"
      # Notas pos-instalacao
      case "$num" in
        20) echo "  -> Execute 'kimi' e depois '/login' para autenticar. Use '/help' para ajuda." ;;
        24) echo "  -> [COMUNITARIO] OpenClaude usa provider OpenAI-compatible. Configure com '/provider'." ; command -v rg >/dev/null 2>&1 || echo "  -> Dica: instale 'ripgrep' (rg) para melhor experiencia." ;;
        25) echo "  -> [COMUNITARIO] ZAI CLI requer API key. Configure em ~/.zai/user-settings.json" ;;
        26) echo "  -> [COMUNITARIO] Top100CLIs e uma ferramenta comunitaria de listagem." ;;
      esac
    else
      echo "OK cmd mas bin nao no PATH ainda"
      echo "rode: source ~/.bashrc && ${B[$num]} --version"
    fi
  else
    echo "FAIL: ${N[$num]}"
  fi
}

echo_sudo_notice
reload_path
check_status
echo "uso: numeros por virgula (ex: 3,4,20) | todos | scan | sair"
echo "comunitarios: #24 OpenClaude, #25 ZAI CLI, #26 Top100CLIs"
echo ""

while true; do
  printf "escolha: "
  read -r INPUT
  case "$INPUT" in
    sair|q|exit)
      echo "ate logo!"
      exit 0
      ;;
    scan|s)
      check_status
      ;;
    todos|t)
      for i in {1..26}; do
        reload_path
        if command -v "${B[$i]}" >/dev/null 2>&1; then
          echo "skip #$i ${N[$i]}"
        else
          setup_cli "$i"
        fi
      done
      check_status
      ;;
    *)
      IFS=',' read -ra NUMS <<< "$INPUT"
      algum=0
      for num in "${NUMS[@]}"; do
        num=$(echo "$num" | tr -d ' ')
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le 26 ]; then
          algum=1
          setup_cli "$num"
        else
          echo "invalido: $num (use 1-26)"
        fi
      done
      [ "$algum" -eq 1 ] && check_status
      ;;
  esac
done
