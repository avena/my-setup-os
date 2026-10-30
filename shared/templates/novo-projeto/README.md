# Template de Novo Projeto - Configuração de Skills

Este template contém a configuração padrão de skills para novos projetos, incluindo:
1. **security-audit** (Cloudflare) - Auditoria rigorosa de segurança e caça a vulnerabilidades com verificação adversarial.
2. **Elephant-Goldfish Model / EGM** (Google) - Brainstorm, especificação e revisão adversarial (Elephant projeta, Goldfish examina sem contexto prévio).

---

## Como usar em um novo projeto

### Opção 1: Usando o script automatizado (Recomendado)
No diretório do seu novo projeto, execute:
```bash
skills-novo-projeto
```
Ou com o caminho completo do script:
```bash
bash /home/livre/my-setup-os/shared/instalar-skills-novo-projeto.sh
```
Para incluir também as skills de engenharia/produtividade do Matt Pocock:
```bash
skills-novo-projeto --all
```

### Opção 2: Restaurando a partir do skills-lock.json
Copie os arquivos `skills-lock.json` e `opencode.jsonc` deste template para a raiz do seu novo projeto e execute:
```bash
npx skills experimental_install
```

### Opção 3: Via Skills CLI diretamente
```bash
# Security Audit (Cloudflare)
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit

# Elephant-Goldfish Model (Google)
npx skills add https://github.com/google/elephant-goldfish-model --skill '*'
```

---

## Como ativar as skills no seu agente de IA

### 1. Security Audit (Cloudflare)
- `security audit this codebase`
- `find security vulnerabilities in ./src`
- `do a security review, output to ~/audits/meu-projeto`

### 2. Elephant-Goldfish Model (Google EGM)
No Antigravity e Claude Code use com prefixo `/egm:`, ou execute diretamente no seu coding agent:
- `/egm:egm-brainstorm` ou `egm-brainstorm <ideia>` — Explora a ideia, faz perguntas de alinhamento e gera `concepts_brief.md`.
- `/egm:egm-draft` — Transforma o brief em `design_draft.md` seção por seção com sua aprovação.
- `/egm:egm-review design_draft.md` — Subagentes 'goldfish' examinam o rascunho sem viés histórico e reportam lacunas.
- `/egm:egm-resolve` — Aplica resoluções e correções automáticas aprovadas.
- `/egm:egm-drift-report` — Detecta divergências entre documentação e código fonte.
