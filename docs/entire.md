# Entire CLI — Checkpoints de Sessões + Brain por Repositório

## Visão Geral

O **Entire** é um git forge para colaboração entre humanos e agentes: ele guarda o *porquê* das mudanças
(prompts, chamadas de ferramentas e decisões das sessões dos agentes) junto ao código, em **checkpoints**
vinculados aos commits. O **brain** transforma esse histórico em memória consultável por repositório.

Neste setup, o Entire é instalado pela CLI oficial e integrado ao fluxo normal de Git:

| Recurso | Para que serve |
|---|---|
| **Checkpoints** | Publica as sessões dos agentes junto com cada `git push` |
| **Brain** | Índice local (código + sessões + docs + histórico) que agentes consultam |
| **Repo clone/remote** | Clona ou aponta um clone para `/et/<projeto>/<repo>` |
| **Brain connect** | Sincroniza a memória local com o brain hospedado da equipe |

- Instalador deste repositório: [`linux/cli/install-entire.sh`](../linux/cli/install-entire.sh)
- Documentação oficial: <https://docs.entire.io/overview>
- Site: <https://entire.com>

## Instalação

### Opção 1 — Script deste repositório

```bash
bash linux/cli/install-entire.sh
```

O script instala a CLI e o plugin `brain`, e imprime os próximos passos. Opções:

| Flag | Efeito |
|---|---|
| `--skip-brain` | Não instala o plugin `brain` |
| `--force` | Reinstala a CLI mesmo se já presente |
| `--enable [REPO]` | Roda `entire enable -y` no `REPO` (padrão: diretório atual) |
| `-h`, `--help` | Mostra a ajuda |

### Opção 2 — Manual

```bash
# 1. Baixe e inspecione o instalador antes de executar
curl -fsSL https://entire.com/install.sh -o /tmp/entire-install.sh
bash /tmp/entire-install.sh

# 2. Garanta ~/.local/bin no PATH (o instalador coloca o binário lá)
export PATH="$HOME/.local/bin:$PATH"
hash -r

# 3. Confira a versão
entire version
```

> **Aviso de segurança:** o instalador oficial usa o padrão `curl | bash`. Em máquinas sensíveis,
> baixe o script, inspecione e só então execute (como acima). O binário é publicado com checksum
> verificado em `https://install.entire.com`.

## Fluxo de Uso

### 1. Login

```bash
entire login           # abre o navegador
entire login --device  # fluxo device-code: mostra um código para digitar no navegador
```

Use `--device` em SSH, containers ou ambientes sem navegador. Confira com `entire auth status`.

### 2. Habilitar checkpoints (em qualquer repositório Git)

```bash
cd /caminho/do/repositorio
entire enable
```

O `enable` configura o repositório para capturar sessões dos agentes. Variações úteis:

| Comando | Efeito |
|---|---|
| `entire enable -y` | Não interativo: aceita os padrões |
| `entire enable --agent opencode` | Habilita hooks só para o agente indicado |
| `entire enable --agent-help-skill entire agent-help` | Instala a skill estável de ajuda do Entire |
| `entire enable --import-history` | Importa os últimos 30 dias de sessões existentes |
| `entire enable --skip-push-sessions` | Não envia logs de sessão no `git push` |
| `entire enable --telemetry=false` | Desliga analytics anônimos (padrão: ligado) |
| `entire enable --local` | Grava em `.entire/settings.local.json` em vez de `.entire/settings.json` |

O que é criado no repositório:

```text
.entire/
├── settings.json          # configuração versionável (enabled, telemetry, backend)
├── settings.local.json    # configuração local (ignorada pelo .entire/.gitignore)
└── .gitignore             # ignora tmp/, logs/, metadata/, redactors/local/
```

Hooks de Git existentes são preservados: cada um é movido para `<hook>.pre-entire` e roda depois do
hook do Entire. Para ver o estado: `entire status`. Para desfazer: `entire disable`.
Para diagnosticar: `entire doctor`.

### 3. Codar e push

Trabalhe com o coding agent normalmente. No `git push`, o Entire publica os checkpoints das sessões
capturadas. O primeiro checkpoint aparece no painel do Entire após o primeiro push.

### 4. Registrar um repositório no Entire (sem `gh`)

`entire repo create` é o equivalente ao `gh repo create`: cria o repositório nativo no forge
Entire, em `/et/<projeto>/<repo>`.

```bash
# 1. Criar o repositório privado no projeto (3-32 chars, minúsculas)
entire repo create my-setup-os --project avena --visibility private

# 2. Adicionar um remote separado — NÃO sobrescreva o origin (GitHub)
entire repo remote add entire /et/avena/my-setup-os

# 3. Habilitar checkpoints apontando para esse remote
entire enable -y --agent opencode --checkpoint-push-remote entire

# 4. Publicar
git push entire main
```

Resultado: `origin` continua no GitHub (CI/pushes normais) e `entire` recebe os checkpoints.
Para ver o destino eleito: `entire status` → `Checkpoints sync to: entire`.

> `entire repo remote add origin ... --override` repointa o `origin` e é a única forma de perder
> a URL anterior — evite se já existe um remote de código. `checkpoint_push_remote` fica em
> `.entire/settings.local.json` (local, não versionado).

### 5. As duas configurações possíveis

Há dois jeitos de ligar um repositório ao Entire — escolha um por repositório:

| Configuração | Quando usar | Comandos | Onde ficam os pushes |
|---|---|---|---|
| **A. Espelho do GitHub** (recomendada quando o GitHub é a fonte da verdade) | Repo já vive no GitHub e você quer sessões + busca sem mudar o fluxo | `entire repo mirror add` → `entire repo remote add entire` | `origin` = GitHub; `entire` = espelho |
| **B. Repositório nativo Entire** | Projeto novo ou repo privado sem GitHub | `entire repo create` → `entire repo remote add entire` | `origin`/`entire` = `/et/<projeto>/<repo>` |

**A. Espelho** (GitHub continua upstream; Entire serve o clone e envia os pushes de volta):

```bash
entire login
entire repo mirror add          # escolha repo + região
entire repo remote add entire   # cria o remote entire://
git fetch entire && git push entire
```

**B. Nativo** — ver a seção anterior (`entire repo create ... --visibility private`).

Em ambos os casos, se o dia a dia deve passar pelo Entire sem nomear remote, aponte o `origin`
para ele com `--override` — mas isso **substitui** a URL anterior do `origin` e o print do comando
é o único registro dela. Para manter GitHub + Entire convivendo, prefira o remote `entire` separado
e `entire enable ... --checkpoint-push-remote entire`.

Sessões e checkpoints no painel: <https://entire.com> → projeto → repositório → Sessions.
Referência da CLI: <https://docs.entire.com/cli-reference/activity>.

### 6. Clonar ou apontar um repositório Entire

```bash
# Clone novo, direto do forge Entire
entire repo clone /et/<projeto>/<repo> [diretório]

# Ou aponte um clone já existente (sobrescreve o remote origin)
entire repo remote add origin /et/<projeto>/<repo> --override
```

Exemplo do onboarding (caminho ilustrativo — troque por `/et/<projeto>/<repo>` do seu time):

```bash
entire repo clone /et/avena/calculos-agronomicos
# ou, dentro de um clone existente:
entire repo remote add origin /et/avena/calculos-agronomicos --override
```

Referências de repositório: `/et/<projeto>/<repo>` para repositórios nativos do Entire e
`/gh/<owner>/<repo>` para espelhos do GitHub. `--override` só repointa o remote local; nada é
alterado no servidor. Use `--cluster <host>` quando o repositório estiver em mais de um cluster.

### 7. Sincronizar a memória (brain)

```bash
# Plugin de brain (uma vez por máquina)
entire plugin install brain

# Construir o brain local e iniciar a atualização em background
entire brain setup

# Vincular o repositório ao brain hospedado e sincronizar
entire brain connect
```

O `brain setup` roda três fases: **instant** (índice de código, sessões, docs e histórico — não gasta
tokens), **backfill** (destila sessões antigas em memórias duráveis, gasta tokens) e **daemon**
(watcher machine-wide que mantém o brain fresco). Para uma execução sem custo de tokens:

```bash
entire brain setup --no-backfill --no-daemon
```

O `brain connect` é a **única** forma de o repositório começar a sincronizar com o brain hospedado;
memórias ficam locais por padrão. Para desfazer: `entire brain disconnect`.

Comandos de consulta:

| Comando | Uso |
|---|---|
| `entire brain query "..."` | Busca no brain (ranking lexical BM25) |
| `entire brain brief <tarefa>` | Junta contexto relevante para uma tarefa |
| `entire brain overview` | Resume projeto, estrutura e decisões |
| `entire brain status` | Cobertura, frescor e estado do workspace |
| `entire brain memories` | Revisa, promove e limpa memórias duráveis |
| `entire brain dash` | Dashboard interativo no terminal |

## Tabela de Comandos

| Comando | Descrição |
|---|---|
| `entire login [--device]` | Autentica a CLI (navegador ou device-code) |
| `entire auth status` | Mostra o estado da autenticação |
| `entire enable [-y] [--agent NOME]` | Habilita checkpoints no repositório atual |
| `entire disable` | Desabilita o Entire no repositório atual |
| `entire status` | Mostra o estado do Entire no repositório |
| `entire doctor` | Diagnostica e corrige problemas de sessão/hooks |
| `entire project create <proj> --owner <org>` | Cria um projeto (agrupador de repositórios) |
| `entire repo create <repo> --project <proj>` | Cria repositório nativo no forge Entire |
| `entire repo mirror add` | Espelha um repositório do GitHub no Entire |
| `entire repo remote add entire /et/<p>/<r>` | Adiciona remote separado (preserva o `origin`) |
| `entire repo clone /et/<p>/<r>` | Clona um repositório do forge Entire |
| `entire repo remote add origin /et/<p>/<r> --override` | Repointa o `origin` existente (sobrescreve a URL) |
| `entire checkpoint list` | Lista os checkpoints do repositório |
| `entire plugin install brain` | Instala o plugin de brain |
| `entire brain setup` | Constrói o brain local + backfill + daemon |
| `entire brain connect` | Vincula ao brain hospedado e sincroniza |
| `entire brain query "..."` | Consulta o brain |
| `entire agent list` | Lista agentes e hooks instalados |
| `entire agent add <nome>` | Instala hooks de um agente específico |

## Segurança e Privacidade

- O Entire **detecta e redige segredos** antes de armazenar qualquer coisa.
- O brain é **local por padrão**; o `connect` (envio para o servidor hospedado) é opt-in.
- Checkpoints são enviados no `git push`; desative com `entire enable --skip-push-sessions`.
- Telemetria anônima vem ligada; desligue com `entire enable --telemetry=false`.
- O instalador oficial verifica checksum do binário baixado.

## Solução de Problemas

| Sintoma | Correção |
|---|---|
| `entire: command not found` | `source ~/.bashrc` ou adicione `~/.local/bin` ao `PATH` |
| `plugin "brain" already installed` | Normal; use `entire plugin install brain --force` para substituir |
| Login falha em SSH/container | Use `entire login --device` |
| Hooks do Codex pedem aprovação | Abra `/hooks` no Codex e aprove; depois `entire doctor` |
| Brain sem terminal não gasta tokens | Comportamento esperado; use `--yes` para consentir o backfill |
| Sessões não aparecem no push | Confira `entire status` e se `--skip-push-sessions` não foi usado |

## Referências

- [Entire — visão geral](https://docs.entire.io/overview)
- [Entire CLI](https://entire.com/features/cli)
- [Entire — Continuous Memory](https://entire.com/#continuous-memory)
