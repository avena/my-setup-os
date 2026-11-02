# Reconstrução de Ambiente - WSL/Container

Este arquivo permite recriar o ambiente em uma nova instalação.

## Scripts de instalação existentes no projeto
- `/home/livre/top-clis.sh` - instala os 23 CLIs principais (npm, curl, pip3, apt)
- `/home/livre/pacotes-instalados.log` - log de pacotes DEB instalados
- `/home/livre/minhas-top20-clis.log` - lista de top CLIs

## Onde está cada coisa

### NPM Global (~/.npm-global/bin)
```
npm i -g @google/gemini-cli@latest
npm i -g @qwen-code/qwen-code
npm i -g cline@latest
npm i -g vibe-cli
```

### Binários diretos (~/.local/bin)
- agy (Antigravity) - baixado direto
- copilot
- kiro-cli (3 binários)

### Via Linuxbrew
- opencode

### Via ~/.kilo/bin
- kilo

### Via uv tools
- kimi, omnigent, vibe

### Skills GSD (~/.config/opencode/skills/)
Todos os 31 skills gsd-* já instalados.

### Skills Matt Pocock (~/.openclaw/skills/)
```
git clone https://github.com/mattpocock/skills.git
cp -r skills/engineering ~/.openclaw/skills/
cp -r skills/productivity ~/.openclaw/skills/
cp -r skills/misc ~/.openclaw/skills/
```

### Skill Security Audit - Cloudflare (~/.agents/skills/security-audit)
Instalar globalmente para todos os CLIs:
```bash
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global -y
bash /home/livre/my-setup-os/shared/instalar-skills-mattpocock.sh
```

### Skills Elephant-Goldfish Model / EGM - Google (~/.agents/skills/egm-*)
Instalar plugin no Antigravity e globalmente para todos os CLIs:
```bash
# Plugin para Antigravity
agy plugin install https://github.com/google/elephant-goldfish-model

# Skills globais para todos os CLIs
npx skills add https://github.com/google/elephant-goldfish-model --skill '*' --global -y
bash /home/livre/my-setup-os/shared/instalar-skills-mattpocock.sh
```

### Instalar todas as skills em um novo projeto:
```bash
# Na raiz do novo projeto:
bash /home/livre/my-setup-os/shared/instalar-skills-novo-projeto.sh
# ou via alias:
skills-novo-projeto
```

### Pasta Shared do Projeto
`/home/livre/my-setup-os/shared/` - use para armazenar configs compartilhadas

### Entire CLI (checkpoints de sessões + brain)
Instalar pelo script do projeto (CLI + plugin brain) e depois rodar o fluxo interativo:
```bash
bash /home/livre/my-setup-os/linux/cli/install-entire.sh

entire login            # use --device em SSH/container
entire enable           # dentro de qualquer repositório git
entire plugin install brain
entire brain setup      # índice local + backfill + daemon
entire brain connect    # sincroniza com o brain hospedado da equipe
```

Duas formas de ligar o repositório ao Entire (troque `/et/<projeto>/<repo>` pelo seu):
```bash
# A) Espelho do GitHub — origin continua no GitHub, Entire recebe os checkpoints
entire repo mirror add && entire repo remote add entire

# B) Repositório nativo Entire (equivalente ao gh repo create)
entire repo create <repo> --project <projeto> --visibility private
entire repo remote add entire /et/<projeto>/<repo>

# depois, em ambos:
entire enable -y --agent opencode --checkpoint-push-remote entire
git push entire main
```

Evite `entire repo remote add origin ... --override` se o `origin` já aponta para o GitHub: ele
sobrescreve a URL. Detalhes: [docs/entire.md](../docs/entire.md).

### Qdrant MCP (busca semântica de código)
O Qdrant guarda vetores; quem gera o embedding é o 9Router (`/v1/embeddings`).
```bash
# 1. chaves em ~/.config/opencode/.env.mcp (modelo: shared/mcp/qdrant/.env.example)
# 2. registrar o MCP no opencode.json
bash /home/livre/my-setup-os/linux/cli/install-qdrant-mcp.sh
# 3. reiniciar o OpenCode e testar qdrant-info
```

Qdrant local opcional: `docker run -d -p 6333:6333 qdrant/qdrant`.
Detalhes (REST/Python, indexação em massa): [docs/qdrant.md](../docs/qdrant.md).

## O que não pôde ser feito (sem root)
- `/srv/shared` - requer sudo para criar em /srv
- Instalar pacotes via apt com sudo

## Checklist de verificação
- [ ] opencode funciona
- [ ] kilo funciona
- [ ] agy funciona
- [ ] npm global packages listados
- [ ] skills gsd carregam
- [ ] skills mattpocock carregam
- [ ] skill security-audit carrega (global e por projeto)
- [ ] skills EGM (egm-*) carregam (global, plugin agy e por projeto)
- [ ] `entire version` funciona e `entire auth status` está autenticado
- [ ] `entire status` mostra checkpoints sincronizando no remote `entire`
- [ ] MCP `qdrant` responde `qdrant-info` (collection `codebase`, 3072 dims)
