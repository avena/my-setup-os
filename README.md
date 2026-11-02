# my-setup-os

## Overview
Este repositório contém a configuração personalizada para meu ambiente de trabalho **cross-platform**, suportando:
- **Windows** (Host)
- **WSL 2** (Windows Subsystem for Linux)
- **Linux Nativo** (Ubuntu, Fedora, etc.)

A estrutura é organizada de forma a separar configurações específicas de cada sistema operacional, enquanto mantém compartilhadas configurações que funcionam em todos os ambientes.

## Arquitetura Cross-Platform

A organização segue o conceito de **"terreno e veículos"**:
- **Sistema Operacional**: O "terreno" onde as configurações rodam
- **Configurações**: Os "veículos" que adaptam-se ao terreno
- **Shared**: A "carteira de motorista" que funciona em todos os sistemas

## Estrutura do Repositório

```text
my-setup-os/
├── README.md                          # Este arquivo - Introdução ao projeto
├── docs/                              # Documentation and references
│   ├── fonts.md                       # Instalação de fontes para editores e terminais
│   ├── top-clis.md                    # Catálogo de 26 CLIs de IA/Coding: instalação e uso
│   ├── entire.md                      # Entire CLI: checkpoints de sessões de agentes + brain
│   ├── qdrant.md                      # Qdrant + 9Router: busca semântica de código/memória (MCP)
│   ├── blender-mcp-setup.md           # Blender MCP: OpenCode (WSL) -> Blender (Windows)
│   ├── cad-gis-mcp-setup.md           # Blender+FreeCAD+QGIS MCP (por projeto): peças, casas, mapas
│   ├── mcp-catalog.md                 # Catálogo de servidores MCP disponíveis
│   ├── deploy-dreamhost.md            # Playbook de deploy incremental rsync/SSH para DreamHost
│   └── references/                    # Curated references for dotfiles management
│       └── README.md                  # Guide to dotfiles resources and best practices
├── shared/                            # Configurações cross-platform
│   ├── .gitconfig                     # Configuração do Git (válida para todos)
│   ├── README.md                      # Explicação das configurações compartilhadas
│   ├── instalar-skills-novo-projeto.sh# Configura EGM e Security Audit em novos projetos
│   ├── instalar-skills-mattpocock.sh  # Sincroniza skills entre os 9 coding CLIs
│   ├── inventario-instalado.md        # Inventário completo de ferramentas e skills
│   ├── reconstruir-ambiente.md        # Guia de restauração do setup
│   ├── setup-mcps.sh                  # Gerenciador de servidores MCP por perfil
│   ├── mcp/qdrant/                    # MCP server Qdrant+9Router (mcp-server.py, .env.example)
│   ├── templates/mcp/                 # Perfis de MCP prontos (mcp-web, mcp-backend, ...)
│   │   ├── mcp-web.jsonc              # Perfil web (Chrome DevTools, Playwright, React...)
│   │   ├── mcp-backend.jsonc          # Perfil backend (Neon, Supabase, ...)
│   │   ├── mcp-productivity.jsonc     # Perfil produtividade (GitHub, Notion, ...)
│   │   ├── mcp-scraping.jsonc         # Perfil scraping (Firecrawl, ...)
│   │   ├── mcp-full.jsonc             # Todos os servidores catalogados
│   │   ├── mcp-cad-gis-3d.jsonc       # Blender+FreeCAD+QGIS — SÓ POR PROJETO (enabled=false)
│   │   └── .env.mcp.example           # Variáveis de ambiente esperadas pelos MCPs
│   ├── templates/novo-projeto/        # Templates pré-configurados (skills-lock.json)
│   └── templates/deploy/              # Automações de deploy (deploy-dreamhost.sh)
│
├── scripts/                           # Health-checks das integrações WSL <-> Windows
│   ├── check-blender-mcp.sh           # Blender MCP + 9Router (handshake real)
│   ├── check-cad-gis-mcp.sh           # FreeCAD XML-RPC + bridge do QGIS + config do opencode
│   ├── add-cad-gis-mcp.sh             # Injeta o perfil cad-gis-3d no opencode.jsonc de um projeto
│   └── qgis_mcp_server.py             # Cliente MCP (stdio) que fala com o bridge no QGIS
│
├── windows/                           # Configurações específicas do Windows Host
│   ├── fonts/                         # Instalação de fontes para Windows
│   │   ├── install-fonts.ps1          # Instalação via Scoop
│   │   └── README.md                  # Explicação da instalação de fontes
│   ├── networking/                    # Scripts PowerShell para NAT e DHCP
│   │   ├── *.ps1                      # Scripts de configuração de rede
│   │   ├── simple-dhcp-server-qt.yml  # Configuração do DHCP Server
│   │   └── README.md                  # Explicação dos scripts de rede
│   ├── scoop/                         # Gerenciador de pacotes Scoop
│   │   ├── scoop-programs.json        # Lista de programas instalados
│   │   └── README.md                  # Instruções do Scoop e UnigetiUI
│   ├── cad-gis/                       # Ponte MCP dos apps CAD/GIS do Windows
│   │   ├── qgis_mcp_bridge.py         # Socket JSON dentro do QGIS (0.0.0.0:9874)
│   │   └── Allow-CadMcpFirewall.ps1   # Libera 9874/9875/9876 para o WSL
│   ├── Set-PowerShell7AsDefault.ps1   # Configura PowerShell 7 como padrão
│   └── README.md                      # Overview das configurações Windows
│
└── linux/                             # Configurações para Linux (WSL ou Nativo)
    ├── cli/                           # Top CLIs Installer (26 CLIs IA/Coding)
    │   ├── top-clis-installer.sh      # Bootstrap: gera ~/top-clis.sh e executa
    │   ├── top-clis.sh                # Script principal do catálogo interativo
    │   ├── install-entire.sh          # Instala Entire CLI + plugin brain (checkpoints de sessões)
    │   ├── install-qdrant-mcp.sh      # Registra o MCP "qdrant" (busca semântica) no OpenCode
    │   └── README.md                  # Documentação do Top CLIs
    ├── fonts/                         # Instalação de fontes para Linux/macOS
    │   ├── install-fonts.sh           # Instalação via apt/dnf/pacman/Homebrew
    │   └── README.md                  # Explicação da instalação de fontes
    ├── system/                        # Configurações de sistema
    │   ├── .bashrc                    # Configuração do shell Bash
    │   ├── .tmux.conf                 # Configuração do Tmux
    │   └── README.md                  # Explicação das configurações de sistema
    ├── containers/                    # Docker e containerização
    │   ├── install-docker-wsl*.sh     # Scripts de instalação do Docker
    │   └── README.md                  # Instruções do Docker
    └── packages/                      # Gerenciamento de pacotes
        └── README.md                  # Instruções de instalação de pacotes
```

## Deploy e Hospedagem

- **[Deploy DreamHost via Rsync](docs/deploy-dreamhost.md)**: Playbook de deploy incremental para hospedagem compartilhada (rsync sobre SSH, algoritmo delta, compressão em trânsito, dry-run e exclusões seguras).
- **[Template `deploy-dreamhost.sh`](shared/templates/deploy/deploy-dreamhost.sh)**: Script bash parametrizado e reutilizável para sincronizar builds locais (WSL/Linux) à DreamHost.

## CAD, GIS e Modelagem 3D/2D via MCP

O mesmo padrão do Blender (OpenCode no WSL controlando o app no Windows por TCP) atende os outros
dois softwares de engenharia da máquina. Guia completo: **[docs/cad-gis-mcp-setup.md](docs/cad-gis-mcp-setup.md)**.

> **Política: por projeto, nunca global.** Blender, FreeCAD e QGIS ficam **fora** de
> `~/.config/opencode/opencode.json`. Cada um abre processo local, disputa uma porta fixa e
> segura o boot do OpenCode com timeout quando o app não está aberto. Entram só no projeto que
> faz CAD/GIS/3D, via [`shared/templates/mcp/mcp-cad-gis-3d.jsonc`](shared/templates/mcp/mcp-cad-gis-3d.jsonc)
> (todos com `"enabled": false`; ligue só o que o projeto usa).

| MCP | App / porta | Para que serve na prática |
|---|---|---|
| **Blender** (`mcp-for-blender`) | Blender 5.2 · `9876` | Objetos 3D, vista explodida animada, materiais PBR, render de catálogo/manual |
| **FreeCAD** (`uvx freecad-mcp`) | FreeCAD · `9875` | Peça mecânica real em B-Rep: esboço cotado, Pad/Pocket, chapa dobrada, furo com tolerância, STEP/IGES, DXF para laser, FEM (CalculiX) |
| **QGIS** (`scripts/qgis_mcp_server.py` + `windows/cad-gis/qgis_mcp_bridge.py`) | QGIS 3.4x · `9874` | Editar mapa aberto via PyQGIS: buffer de APP, área em hectares, declividade, NDVI, layout de impressão, e **desenvolver plugins de geoprocessamento** rodando `processing.run()` |

O que isso destrava, em concreto:

- **Peças e conjuntos 3D (CAD paramétrico)** — o agente cria corpos no PartDesign com dimensões
  reais, aplica furos/chanfros, confere por `get_view` e exporta `.step` para fabricação.
- **Casas e construção** — paredes, aberturas e lajes a partir de um footprint; depois o STEP
  entra no Blender para a apresentação animada.
- **Mapas** — o agente lê as camadas do projeto aberto, roda algoritmos GDAL/GRASS/SAGA e
  devolve o mapa renderizado para conferência visual.
- **Tecnologia de geoprocessamento** — criar, testar e depurar plugin Processing (algoritmo,
  `metadata.txt`, testes via `qgis_execute`) sem sair do chat.

```bash
./scripts/add-cad-gis-mcp.sh ~/projetos/minha-peca        # ativa no projeto (troca o IP do WSL sozinho)
./scripts/check-cad-gis-mcp.sh ~/projetos/minha-peca/opencode.jsonc   # verifica global + projeto
./scripts/check-cad-gis-mcp.sh                            # só o global (deve estar limpo)
powershell -ExecutionPolicy Bypass -File windows\cad-gis\Allow-CadMcpFirewall.ps1   # admin
```

Status em 01/11/2026: Blender ok · **FreeCAD não instalado** · **QGIS com instalação quebrada**
(sobraram 3 arquivos-stub em `Program Files\QGIS 3.44.10`; o perfil em `AppData\Roaming\QGIS` está
intacto). Passo a passo de reinstalação no doc.

## Entire CLI — Checkpoints de Sessões e Brain por Repositório

O **Entire** é o git forge para colaboração agente-humano: guarda o *porquê* das mudanças (prompts,
tool calls e decisões das sessões dos coding agents) em **checkpoints** presos aos commits, e
transforma esse histórico em um **brain** consultável por repositório.

Guia completo: **[docs/entire.md](docs/entire.md)** · Instalador: [`linux/cli/install-entire.sh`](linux/cli/install-entire.sh)

```bash
bash linux/cli/install-entire.sh    # CLI + plugin brain
entire login                        # --device em SSH/container
entire enable                       # dentro de qualquer repo git
```

| Etapa | Comando | O que faz |
|---|---|---|
| 1. Instalar | `curl -fsSL https://entire.com/install.sh \| bash` | Instala o binário em `~/.local/bin` |
| 2. Login | `entire login` | Vincula a conta da CLI (device-code com `--device`) |
| 3. Habilitar | `entire enable` | Todo push passa a publicar checkpoints |
| 4. Codar/push | `git push` | O primeiro checkpoint aparece no painel |
| 5. Repo | `entire repo clone /et/<projeto>/<repo>` | Clone novo do forge Entire |
| 5b. Repo | `entire repo remote add origin --override /et/<projeto>/<repo>` | Aponta um clone existente |

> O caminho `/et/avena/calculos-agronomicos` usado no guia é apenas um **exemplo**; troque por
> `/et/<projeto>/<repo>` do seu time.
| 6. Brain | `entire plugin install brain` | Instala o plugin de memória contínua |
| 7. Brain | `entire brain setup` | Índice local + backfill + watcher em background |
| 8. Brain | `entire brain connect` | Sincroniza as memórias com o brain hospedado da equipe |

Checkpoints capturam as sessões dos agentes e as publicam no `git push`; o brain é **local por
padrão** e só sincroniza depois de `entire brain connect`. Segredos são detectados e redigidos antes
de qualquer armazenamento. Detalhes de flags, consultas (`brain query`, `brief`, `overview`) e
troubleshooting em [docs/entire.md](docs/entire.md).

## Características Principais

### 1. Compatibilidade Multiplataforma
- Configurações compartilhadas (`.gitconfig`) funcionam em todos os sistemas
- Scripts detectam automaticamente se estão rodando no WSL
- Arquitetura modular para fácil extensão

### 2. Eficiência
- Links simbólicos mantêm a configuração sincronizada
- Scripts de instalação automatizadas
- Gestão de pacotes centralizada

### 3. Manutenibilidade
- Estrutura clara e intuitiva
- Documentação detalhada em cada pasta
- Configurações versionadas com Git

### 4. Segurança
- Permissões mantidas no sistema Linux
- Scripts verificados e testados
- Arquivos de configuração seguros

## Skills para Coding Agents (AI Engineering)

O setup conta com um ecossistema completo de **Skills** compartilhadas entre todos os agentes de IA instalados (Antigravity, Claude Code, OpenCode, Codex, Kilo, Copilot, Gemini, Qwen, OpenClaw):

1. **Elephant-Goldfish Model (Google EGM)**:
   - Metodologia *"Design with an elephant. Review with a goldfish."*
   - O **Elephant** (contexto amplo) redige a especificação e o design.
   - O **Goldfish** (subagentes isolados com contexto zero) revisa sem viés para expor suposições e riscos.
   - Plugin oficial instalado no Antigravity (`agy plugin install https://github.com/google/elephant-goldfish-model`) e 7 skills integradas globalmente.

2. **Security Audit (Cloudflare)**:
   - Auditoria rigorosa de vulnerabilidades e segurança arquitetural com caçadores e verificadores adversariais.

---

### Como Acionar as Skills no seu Coding Agent

#### 1. Elephant-Goldfish Model (Google EGM)
> **Nota de Sintaxe:** No **Antigravity (agy CLI)** e **Claude Code**, use com o prefixo `/egm:`. No **Codex**, selecione a skill correspondente no menu de skills. No **OpenCode**, chame o comando diretamente.

- **Ideação e Brainstorm:**
  ```text
  /egm:egm-brainstorm Adicionar autenticação OAuth2 neste projeto
  ```
  *(Explora requisitos e trade-offs, desafia a proposta e consolida a direção acordada em `concepts_brief.md`)*

- **Redação da Especificação:**
  ```text
  /egm:egm-draft
  ```
  *(Transforma o brief em `design_draft.md`, pausando após cada seção para seu feedback e aprovação)*

- **Revisão Adversarial com Subagentes (Goldfish):**
  ```text
  /egm:egm-review design_draft.md
  ```
  *(Subagentes isolados sem histórico examinam clareza, riscos e acoplamento ao código)*

- **Resolução de apontamentos:**
  ```text
  /egm:egm-resolve
  ```
  *(Aplica conciliações e correções aprovadas no documento de design)*

- **Checagem de consistência docs vs código:**
  ```text
  /egm:egm-drift-report
  ```
  *(Compara os documentos de design aprovados com o código-fonte atual para detectar divergências)*

#### 2. Security Audit (Cloudflare)
- `security audit this codebase`
- `find security vulnerabilities in ./src`
- `do a security review, output to ~/audits/meu-projeto`

---

### Como Habilitar em um Novo Projeto

Para inicializar automaticamente o **EGM** e o **Security Audit** em qualquer novo repositório:
```bash
skills-novo-projeto
```
*(ou `bash /home/livre/my-setup-os/shared/instalar-skills-novo-projeto.sh`)*

Para incluir também o pacote completo de engenharia/produtividade do Matt Pocock:
```bash
skills-novo-projeto --all
```

---

## Guia Rápido

### Pré-requisitos
- Git instalado em todos os sistemas
- PowerShell 7+ (Windows) - recomendado (use `Set-PowerShell7AsDefault.ps1` para configurar)
- WSL 2 (se usar Windows)
- Bash/Zsh (Linux/WSL)

### Passo a Passo

1. **Clonar o Repositório**
   ```bash
   git clone https://github.com/avena/my-setup-os.git
   cd my-setup-os
   ```

2. **Configurar Links Simbólicos**
   ```bash
   # Linux/WSL
   ln -sf $(pwd)/shared/.gitconfig ~/.gitconfig
   ln -sf $(pwd)/linux/system/.bashrc ~/.bashrc
   ln -sf $(pwd)/linux/system/.tmux.conf ~/.tmux.conf
   ```

3. **Instalar Dependências**
   - **Windows**: Execute scripts PowerShell na pasta `windows/networking/`
   - **Linux/WSL**: Execute scripts na pasta `linux/containers/` e `linux/packages/`

4. **Verificar Configuração**
   ```bash
   # Verificar Git
   git config --list

   # Verificar Docker
   docker --version

   # Verificar Tmux
   tmux -V
   ```

## Instruções por Plataforma

### Windows Host
- **Scoop**: Gerenciador de pacotes (instalação via `windows/scoop/README.md`)
- **Rede**: Scripts PowerShell para NAT e DHCP (via `windows/networking/README.md`)
- **WSL**: Configuração do WSL 2 (via `linux/system/README.md`)
- **Fontes**: Instalação de fontes via `windows/fonts/install-fonts.ps1`
- **PowerShell 7**: Configuração como padrão via `windows/Set-PowerShell7AsDefault.ps1`

### WSL 2
- **Homebrew**: Gerenciador de pacotes adicional (via `linux/homebrew/README.md`)
- **apt/dnf**: Gerenciadores de pacotes do sistema (via `linux/packages/README.md`)
- **Docker**: Instalação via `linux/containers/install-docker-wsl.sh`
- **Shell**: Configuração Bash/Tmux via `linux/system/README.md`

### Linux Nativo
- **Homebrew**: Gerenciador de pacotes adicional (via `linux/homebrew/README.md`)
- **apt/dnf**: Gerenciadores de pacotes do sistema (via `linux/packages/README.md`)
- **Docker**: Instalação via `linux/containers/install-docker-wsl.sh` (adaptado)
- **Shell**: Configuração Bash/Tmux via `linux/system/README.md`

## Solução de Problemas

### 1. Links Simbólicos Não Funcionam
- **Windows**: Verifique permissões de administrador
- **Linux/WSL**: Verifique a existência do arquivo de origem

### 2. Scripts Não Executam
- **Windows**: Verifique a política de execução de scripts PowerShell
- **Linux/WSL**: Verifique permissões de execução (`chmod +x script.sh`)

### 3. WSL Não Detecta Configurações
Verifique se os links simbólicos estão corretos e o arquivo `.wslconfig` existe no Windows.

## Contribuição

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/sua-feature`)
3. Commit suas mudanças (`git commit -m 'Add some feature'`)
4. Push para a branch (`git push origin feature/sua-feature`)
5. Abra um Pull Request

## Licença

MIT License - Veja `LICENSE` para mais detalhes.

## Recursos e Referências

O diretório `docs/` contém documentação completa do projeto:

- **[top-clis.md](docs/top-clis.md)** - Catálogo de 26 CLIs de IA/Coding: instalação, uso e solução de problemas
- **[fonts.md](docs/fonts.md)** - Instalação de fontes para editores e terminais
- **[blender-mcp-setup.md](docs/blender-mcp-setup.md)** - Integração Blender (Windows) ↔ OpenCode (WSL) via MCP: setup, health-check e troubleshooting
- **[cad-gis-mcp-setup.md](docs/cad-gis-mcp-setup.md)** - Blender + FreeCAD (CAD paramétrico) + QGIS (SIG) via MCP no WSL, com portas 9876/9875/9874, check de conectividade e troubleshooting
- **[references/](docs/references/README.md)** - Coleção curada de referências e inspiração para gerenciamento de dotfiles, incluindo repositórios famosos, ferramentas e melhores práticas.

## Agradecimentos

- **Scoop**: Gerenciador de pacotes para Windows
- **Docker**: Plataforma de contêineres
- **Tmux**: Terminal multiplexer
- **WSL**: Windows Subsystem for Linux
