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

### Pasta Shared do Projeto
`/home/livre/my-setup-os/shared/` - use para armazenar configs compartilhadas

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
