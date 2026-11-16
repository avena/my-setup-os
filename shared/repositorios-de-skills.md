# Repositórios de Skills — Referência

Fontes usadas para descobrir e instalar agent skills. Consultar antes de escrever uma skill do zero.

## 1. EverMe SkillHub

- **URL**: https://evermind.ai/skillhub
- **Docs de instalação (para agentes)**: https://everme.evermind.ai/skills/SKILL.md
- **CLI**: `evercli` (npm: `@everme/cli`)
- **Instalação**: `npm install -g @everme/cli`
- **Uso**: `evercli skill install <owner>/<repo>/<skill> --yes --format json`
- **Listar instaladas**: `evercli skill list --format json`
- **Onde instala**: `~/.agents/skills/<nome>` + link em `~/.claude/skills/` (agentes: `claude-code`, `universal`)
- **Score exibido**: Skillbench score (usability / robustness / safety) + stars do repo + licença
- **Observação**: o endpoint `/skills/SKILL.md` é um "meta-skill" — instrui o agente a instalar a skill nomeada na mensagem do usuário. Não requer login.

### Skills instaladas de lá

| Skill | ID | Origem | Repo | Licença |
|---|---|---|---|---|
| `md-to-docx` | `openclaw/skills/md-to-docx` | SkillHub | github.com/openclaw/skills | MIT |
| `word-documents` | `agent0ai/agent-zero/word-documents` | SkillHub | github.com/agent0ai/agent-zero | MIT |

## 2. OpxSkills

- **URL**: https://www.opxskills.com/
- **Catálogo de skills**: https://www.opxskills.com/skills
- **OpxScore**: nota provisória de documentação/detalhe prático/evidência de fonte — **não** é taxa de sucesso medida nem certificação de segurança.
- **Instalação**: cada página de skill traz instruções por CLI (Claude Code, Claude Desktop, outro agente) ou download da pasta.
- **Plugin oficial Anthropic** (usado pela página do `docx`):
  ```bash
  /plugin marketplace add anthropics/skills
  /plugin install document-skills@anthropic-agent-skills
  ```
- **Manual (o que foi feito aqui)**: clone esparso do repo oficial
  ```bash
  git clone --depth 1 --filter=blob:none --sparse https://github.com/anthropics/skills.git
  cd skills && git sparse-checkout set skills/docx
  cp -r skills/docx ~/.agents/skills/docx
  ```

### Skills instaladas de lá

| Skill | Origem | Conteúdo |
|---|---|---|
| `docx` | github.com/anthropics/skills → `skills/docx` | SKILL.md + 61 arquivos (scripts de validação XSD, comentários, tracked changes, templates, schemas OOXML) |

## 3. Skills relacionadas (mesmo diretório OpxSkills)

Ainda **não** instaladas — instalar quando o fluxo pedir:

| Skill | Para quê |
|---|---|
| `pdf` | Ler, preencher, extrair e gerar PDF |
| `pptx` | Gerar/editar apresentações PowerPoint |
| `xlsx` | Criar e analisar planilhas Excel |

Instalação: mesmo plugin (`document-skills@anthropic-agent-skills`) já cobre as quatro.

## 4. Skills de documento instaladas neste sistema

Todas em `~/.agents/skills/` com symlink em cada CLI.

| Skill | Papel no fluxo | Precisa de |
|---|---|---|
| `docx` (Anthropic) | Criar .docx com `docx` (npm); editar .docx via unpack→XML→zip; ler via `pandoc`; tracked changes; comentários; validação XSD | `docx` (npm, global), `pandoc`, `soffice`, `pdftoppm` |
| `md-to-docx` (openclaw) | Converter `.md` → `.docx` com detecção de template; Mermaid → PNG; tipografia chinesa por padrão | `python-docx`, `mmdc` (opcional), Chrome (opcional) |
| `word-documents` (agent-zero) | Fluxo ODT/Writer; ferramentas `document_artifact:create/read/edit` | — (depende de tools do Agent Zero; no nosso fluxo serve como referência de estrutura de conteúdo) |

## 5. Fluxo pretendido (visita técnica → relatório)

```
visita em campo (voz/texto)
  → agente escreve relatório em Markdown  (fonte de verdade, versionável)
  → md-to-docx converte .md → .docx       (ou docx-js da skill docx p/ layout fino)
  → validação: pandoc -t markdown + inspeção visual
```

Regra: **Markdown é o artefato de trabalho**; `.docx` é a saída de entrega. Nunca editar o `.docx` como fonte.

---

*Registrado em 2026-11-16*
