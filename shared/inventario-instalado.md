# Inventário do Sistema - Instalações e Skills (Atualizado)

Gerado em: 2026-10-23

## 1. CLIs Principais no PATH

| CLI | Localização | Versão/Status |
|-----|-------------|---------------|
| **kilo** | ~/.kilo/bin/kilo | 159 MB, Mar 4 2026 |
| **opencode** | /home/linuxbrew/.linuxbrew/bin/opencode | via linuxbrew |
| **copilot** | ~/.local/bin/copilot | 142 MB, Mar 26 2026 |
| **agy (Antigravity)** | ~/.local/bin/agy | 224 MB, Oct 22 2026 |
| **kiro-cli** | ~/.local/bin/kiro-cli | Jul 27 2026 |
| **qodercli** | ~/.qoder/bin/qodercli |  |
| **vibe / vibe-acp** | via uv tools | mistral-vibe |
| **kimi / kimi-cli** | via uv tools |  |
| **omni / omnigent** | via uv tools |  |

---

## 2. Pacotes NPM Global (~/.npm-global/bin)

- @google/gemini-cli@0.34.0 (stale - Gemini CLI antigo)
- @qwen-code/qwen-code@0.12.5
- cline@latest
- vibe-cli
- npm-check-updates
- typescript (tsc, tsserver)

---

## 3. Pasta Shared do Projeto

**Localização**: `/home/livre/my-setup-os/shared/`

Conteúdo atual:
- .gitconfig
- .gitconfig.template  
- .gitignore_global
- README.md
- inventario-instalado.md (atualizado)
- reconstruir-ambiente.md (atualizado)
- instalar-skills-mattpocock.sh (novo)

---

## 4. Skills GSD (em ~/.config/opencode/skills/)

Total: ~31 skills

- gsd-add-tests
- gsd-ai-integration-phase
- gsd-audit-fix
- gsd-audit-milestone
- gsd-audit-uat
- gsd-autonomous
- gsd-capture
- gsd-cleanup
- gsd-code-review
- gsd-complete-milestone
- gsd-config
- gsd-debug
- gsd-discuss-phase
- gsd-docs-update
- gsd-eval-review
- gsd-execute-phase
- gsd-explore
- gsd-extract-learnings
- gsd-fast
- gsd-forensics
- gsd-graphify
- gsd-health
- gsd-help
- gsd-import
- gsd-inbox
- gsd-ingest-docs
- gsd-manager
- gsd-map-codebase
- gsd-mempalace-capture
- gsd-mempalace-recall
- gsd-milestone-summary
- gsd-mvp-phase
- gsd-new-milestone
- gsd-new-project
- gsd-next
- gsd-ns-context
- gsd-ns-ideate
- gsd-ns-manage
- gsd-ns-project
- gsd-ns-review
- gsd-ns-workflow
- gsd-onboard
- gsd-pause-work
- gsd-phase
- gsd-plan-phase
- gsd-plan-review-convergence
- gsd-pr-branch
- gsd-profile-user
- gsd-progress
- gsd-quick-batch
- gsd-quick
- gsd-resume-work
- gsd-review-backlog
- gsd-review
- gsd-secure-phase
- gsd-settings
- gsd-ship
- gsd-sketch
- gsd-spec-phase
- gsd-spike
- gsd-stats
- gsd-surface
- gsd-thread
- gsd-ui-phase
- gsd-ui-review
- gsd-ultraplan-phase
- gsd-undo
- gsd-update
- gsd-validate-phase
- gsd-verify-work
- gsd-workspace
- gsd-workstreams

---

## 5. Skills Matt Pocock (instaladas em ~/.opencode/skills/)

Copiadas de: https://github.com/mattpocock/skills

### engineering/
- ask-matt
- code-review
- codebase-design
- diagnosing-bugs
- domain-modeling
- grill-with-docs
- implement
- implement-spec
- improve-codebase-architecture
- pr
- prototype
- research
- retro
- setup-matt-pocock-skills
- to-spec
- to-tickets
- triage
- tdd
- wayfinder
- wizard

### productivity/
- grilling
- grill-me
- handoff
- teach
- to-questionnaire
- wait-what
- writing-for-agents

### misc/
- git-guardrails-claude-code
- migrate-to-shoehorn
- scaffold-exercises
- setup-pre-commit

### find-skills
- Aponta para ~/.agents/skills/find-skills (link simbólico)

---

## 6. Skills Novos (do system-update - OpenCode)

- code-review
- codebase-design
- diagnosing-bugs
- domain-modeling
- git-guardrails-claude-code
- grilling
- migrate-to-shoehorn
- pr
- prototype
- research
- scaffold-exercises
- setup-pre-commit
- tdd
- wizard
- writing-for-agents

---

## 7. Pastas de Configuração Principais

| Pasta | Descrição |
|-------|-----------|
| ~/.opencode/ | Config OpenCode (só tem plan/ agora com skills) |
| ~/.gemini/ | Config Gemini (tem antigravity-cli backup) |
| ~/.gemini/antigravity-cli/ | Antigravity/AGY IDE server |
| ~/.gsd/ | Config GSD (defaults.json) |
| ~/.openclaw/ | OpenClaw skills (original) |
| ~/.config/opencode/ | OpenCode config completo com skills/plugins |
| ~/.local/bin/ | Binários instalados pelo usuário |
| ~/.kilo/bin/ | Kilo Code |
| ~/.npm-global/bin/ | NPM global packages |
| ~/.qoder/ | Qoder CLI |

---

## 8. O que NÃO está instalado / Pendente

- [ ] `/srv/shared` - não pode criar sem sudo/root
- [ ] Skills Matt Pocock: `in-progress/` e `deprecated/` (não copiados ainda)
- [ ] Atualizações de versão: kilo, opencode, agy
- [ ] Reinstalação do @google/gemini-cli (versão atual é antiga)

---

## 9. Histórico de Instalações (de pacotes-instalados.log)

- Sistema base: Ubuntu 24.04 (WSL2)
- Node.js via nvm: v24.14.0
- Bun, uv, rust/cargo disponíveis
- Docker instalado
- WSL utilities (wslu, wsl-pro-service)

---

*Este arquivo pode ser usado para reconstruir o ambiente em novas instalações/WSL/containers*