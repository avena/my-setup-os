# Catálogo de Projetos e Ferramentas Avaliadas (AI & Dev Tools)

Avaliação técnica, formato de execução e diretrizes de instalação para projetos open-source do ecossistema de desenvolvimento e agentes de IA.

---

## Índice Rápido de Veredito

| Projeto | Categoria | Formato | Recomendação |
| :--- | :--- | :--- | :--- |
| **[fabro-sh/fabro](#1-fabro-fabro-shfabro)** | Software Factory / Grafos de Agentes | Binário Rust / Docker | **Instalar CLI / Avaliar** |
| **[Waishnav/devspace](#2-devspace-waishnavdevspace)** | Harness MCP Multi-Agente | CLI npm / Local | **Instalar CLI** |
| **[devdotfast/whiteboard](#3-whiteboard-devdotfastwhiteboard)** | Canvas de Arquitetura & AST Diff | App Desktop (Code OSS) | **Apenas Registrar** |
| **[vercel/eve](#4-eve-verceleve)** | Framework de Agentes Filesystem-First | Biblioteca npm / SDK | **Apenas Registrar** |
| **[iAmCorey/Wake](#5-wake-iamcoreywake)** | Gerenciador de Sessões de Agentes | App Desktop Rust / GPUI | **Instalar Desktop** |
| **[nyblnet/bento](#6-bento-nyblnetbento)** | Suíte Office em Arquivo Único | SPA HTML / TypeScript | **Apenas Registrar** |
| **[yoanbernabeu/grepai](#7-grepai-yoanbernabeugrepai)** | Busca Semântica & Call Graph Local | CLI C/Go / MCP Server | **Instalar MCP / CLI** |
| **[builderz-labs/mission-control](#8-mission-control-builderz-labsmission-control)** | Control Plane de Agentes & Custos | Docker Container / Next.js | **Rodar em Container** |
| **[crawlseo/crawlseo](#9-crawlseo-crawlseocrawlseo)** | Auditoria e Automação SEO | Docker Container / Next.js | **Rodar em Container** |
| **[inukaasith/twindesk](#10-twindesk-inukaasithtwindesk)** | Desk Compartilhado Multi-Dispositivo | App Desktop (Electron/Rust) | **Instalar Desktop** |
| **[shaongitbd/doory](#11-doory-shaongitbddoory)** | Editor Gráfico (Alternativa ao Canva) | Web App / MCP Server | **Apenas Registrar** |
| **[presenton/presenton](#12-presenton-presentonpresenton)** | Gerador de Apresentações com IA | Docker Container / Next.js | **Rodar em Container** |
| **[getopenpost/openpost](#13-openpost-getopenpostopenpost)** | Agendador de Mídias Sociais | Docker Container / SvelteKit | **Apenas Registrar** |
| **[lfnovo/open-notebook](#14-open-notebook-lfnovoopen-notebook)** | NotebookLM Open-Source com LLM Local | Docker Container / Next.js | **Rodar em Container** |
| **[KnifeLemon/Filee](#15-filee-knifelemonfilee)** | Conversor Offline de 263 Formatos | App Desktop .NET (Avalonia) | **Instalar Desktop** |
| **[DylanFriday/flashcard-ai-generator](#16-flashcard-ai-generator-dylanfridayflashcard-ai-generator)** | UI 3D Flip de Flashcards | Template / Componente | **Apenas Registrar** |

---

## Detalhamento dos Projetos

### 1. Fabro (`fabro-sh/fabro`)
- **URL:** [https://github.com/fabro-sh/fabro](https://github.com/fabro-sh/fabro)
- **O que é:** "Dark software factory" para automação de tarefas de desenvolvimento com agentes de IA. Modela pipelines usando grafos em sintaxe Graphviz DOT com branching, loops, human-in-the-loop e checkpoints automáticos no Git.
- **Tecnologia:** Binário único em Rust (sem dependências externas de runtime).
- **Veredito:** **Instalar CLI / Avaliar**. Alinha-se diretamente com fluxos como Claude Code e OpenCode para orquestrar etapas de planejamento e implementação em grafos previsíveis.
- **Como Instalar/Rodar:**
  ```bash
  curl -fsSL https://fabro.sh/install.sh | bash
  fabro server start
  ```

---

### 2. DevSpace (`Waishnav/devspace`)
- **URL:** [https://github.com/Waishnav/devspace](https://github.com/Waishnav/devspace)
- **O que é:** Camada minimalista de orquestração sobre MCP. Permite que interfaces como ChatGPT, Claude Web ou bots externos acessem seu computador local com segurança, e permite delegar tarefas entre agentes de terminal (Codex, Claude Code, OpenCode) usando worktrees Git isolados.
- **Tecnologia:** TypeScript / Node.js.
- **Veredito:** **Instalar CLI**. Muito útil para conectar clientes MCP aos seus agentes locais sem abrir portas inseguras.
- **Como Instalar/Rodar:**
  ```bash
  curl -fsSL https://devspace.run/install | sh
  # ou via npm:
  npm install -g @waishnav/devspace
  devspace init
  ```

---

### 3. Whiteboard (`devdotfast/whiteboard`)
- **URL:** [https://github.com/devdotfast/whiteboard](https://github.com/devdotfast/whiteboard)
- **O que é:** Canvas interativo para arquitetura de software desenhado por humanos e agentes de IA. Fork do Code OSS que exibe diagramas de sequência, grafos de chamadas e visualizador semântico de diffs em Rust (AST-aware).
- **Tecnologia:** App Desktop (Electron / Code OSS).
- **Veredito:** **Apenas Registrar**. Por ser um app desktop completo derivado do VS Code, não convém manter instalado se você já usa o VS Code padrão com extensões. Baixe diretamente do site quando for desenhar arquiteturas complexas com agentes.

---

### 4. Eve (`vercel/eve`)
- **URL:** [https://github.com/vercel/eve](https://github.com/vercel/eve)
- **O que é:** Framework filesystem-first da Vercel para criação de agentes de IA duráveis. Cada ferramenta, skill e instrução vive em uma pasta padronizada (`agent/tools`, `agent/skills`, `agent/channels`).
- **Tecnologia:** TypeScript / Node.js SDK.
- **Veredito:** **Apenas Registrar**. É uma biblioteca de desenvolvimento para criar novos agentes, e não um serviço ou executável de uso direto.
- **Como Usar:**
  ```bash
  npx eve@latest init meu-novo-agente
  ```

---

### 5. Wake (`iAmCorey/Wake`)
- **URL:** [https://github.com/iAmCorey/Wake](https://github.com/iAmCorey/Wake)
- **O que é:** Gerenciador centralizado de sessões de coding agents (Claude Code, OpenCode, Codex, etc.). Permite buscar histórico, inspecionar prompts e retomar sessões interrompidas.
- **Tecnologia:** Rust + GPUI (a mesma engine nativa de alto desempenho do editor Zed).
- **Veredito:** **Instalar Desktop no Windows/Linux**. Levíssimo por não usar Electron, ideal para quem roda múltiplos agentes em terminal e perde o histórico de sessões anteriores.

---

### 6. Bento (`nyblnet/bento`)
- **URL:** [https://github.com/nyblnet/bento](https://github.com/nyblnet/bento)
- **O que é:** Suíte de escritório (documentos e slides) que cabe inteira dentro de um único arquivo HTML. Funciona offline no navegador sem dependências.
- **Tecnologia:** Single Page App em TypeScript.
- **Veredito:** **Apenas Registrar**. Excelente alternativa zero-instalação para gerar slides e notas portáteis que podem ser enviados para terceiros.

---

### 7. GrepAI (`yoanbernabeu/grepai`)
- **URL:** [https://github.com/yoanbernabeu/grepai](https://github.com/yoanbernabeu/grepai)
- **O que é:** Busca semântica e grafos de chamadas 100% locais para agentes de IA (Claude Code, Cursor, OpenCode). Gera embeddings e permite que o agente entenda o contexto sem ler arquivos desnecessários.
- **Tecnologia:** C e Go com suporte a servidor MCP.
- **Veredito:** **Instalar MCP / CLI**. Complementa perfeitamente o Qdrant e o ecossistema de MCPs já configurados no projeto.

---

### 8. Mission Control (`builderz-labs/mission-control`)
- **URL:** [https://github.com/builderz-labs/mission-control](https://github.com/builderz-labs/mission-control)
- **O que é:** Control plane self-hosted para monitorar execuções de agentes, custos em tokens, logs, tarefas em fila e quality gate Aegis, persistido em SQLite WAL.
- **Tecnologia:** Next.js 16 + SQLite.
- **Veredito:** **Rodar em Container**. Já preparado no repositório em `projetos/mission-control/` (porta `3001`).

---

### 9. CrawlSEO (`crawlseo/crawlseo`)
- **URL:** [https://github.com/crawlseo/crawlseo](https://github.com/crawlseo/crawlseo)
- **O que é:** Painel open-source de auditoria e automação SEO integrado com a Google Search Console API.
- **Tecnologia:** Next.js + PostgreSQL + Worker.
- **Veredito:** **Rodar em Container**. Já preparado no repositório em `projetos/crawlseo/` (porta `3000`).

---

### 10. TwinDesk (`inukaasith/twindesk`)
- **URL:** [https://github.com/inukaasith/twindesk](https://github.com/inukaasith/twindesk)
- **O que é:** Compartilhador de tela, mouse, teclado, área de transferência, arquivos e notificações entre computadores (Windows, Linux, Mac) e smartphones (Android, iOS) sem necessidade de nuvem ou conta (alternativa FOSS ao Synergy e Apple Sidecar).
- **Tecnologia:** Electron / Rust.
- **Veredito:** **Instalar Desktop no Windows/Linux**. Ideal para uso com múltiplos monitores ou entre notebook e desktop de trabalho.

---

### 11. Doory (`shaongitbd/doory`)
- **URL:** [https://github.com/shaongitbd/doory](https://github.com/shaongitbd/doory)
- **O que é:** Editor de design gráfico colaborativo open-source (alternativa ao Canva) com suporte a MCP Server para manipulação por IA.
- **Tecnologia:** React + Fabric.js + Django.
- **Veredito:** **Apenas Registrar**. Vale criar automação em container apenas se você tiver demanda frequente de criação gráfica via IA local.

---

### 12. Presenton (`presenton/presenton`)
- **URL:** [https://github.com/presenton/presenton](https://github.com/presenton/presenton)
- **O que é:** Gerador open-source de apresentações via IA (alternativa a Gamma, Decktopus e Beautiful.ai) com API REST e exportação para PowerPoint/PDF. Mais de 11.9k stars.
- **Tecnologia:** TypeScript / Next.js / Docker.
- **Veredito:** **Rodar em Container**. Excelente para criar baralhos de slides profissionais a partir de documentos ou prompts de IA.

---

### 13. OpenPost (`getopenpost/openpost`)
- **URL:** [https://github.com/getopenpost/openpost](https://github.com/getopenpost/openpost)
- **O que é:** Plataforma self-hosted para criação, agendamento e análise de postagens em redes sociais com suporte a automações via MCP.
- **Tecnologia:** SvelteKit + Go.
- **Veredito:** **Apenas Registrar**. Muito útil para times de marketing e gestão de canais sociais.

---

### 14. Open-Notebook (`lfnovo/open-notebook`)
- **URL:** [https://github.com/lfnovo/open-notebook](https://github.com/lfnovo/open-notebook)
- **O que é:** Implementação open-source do Google NotebookLM com suporte a múltiplos provedores e LLMs locais via Ollama/9Router. Mais de 41.9k stars no GitHub.
- **Tecnologia:** TypeScript / Python / Docker.
- **Veredito:** **Rodar em Container (Altamente Recomendado)**. Encaixa-se perfeitamente com a `notebooklm-skill` e o gateway local `9router` já presentes no repositório.

---

### 15. Filee (`KnifeLemon/Filee`)
- **URL:** [https://github.com/KnifeLemon/Filee](https://github.com/KnifeLemon/Filee)
- **O que é:** Conversor de arquivos 100% offline via drag & drop. Suporta 263 formatos (PDF, Word, Excel, PowerPoint, imagens, áudio, vídeo, e-books e arquivos compactados) sem enviar dados para a internet e sem precisar do Microsoft Office instalado. Mais de 27k stars.
- **Tecnologia:** C# / .NET com interface Avalonia.
- **Veredito:** **Instalar Desktop no Windows/Linux**. É o melhor utilitário local para converter mídias e documentos com privacidade total.

---

### 16. Flashcard AI Generator (`DylanFriday/flashcard-ai-generator`)
- **URL:** [https://github.com/DylanFriday/flashcard-ai-generator](https://github.com/DylanFriday/flashcard-ai-generator)
- **O que é:** Interface interativa de flashcards com animação de flip 3D em CSS puro e repetição espaçada no padrão Anki.
- **Tecnologia:** Next.js / React / CSS 3D.
- **Veredito:** **Apenas Registrar**. Já catalogado como template de frontend e regras de taxonomia L1/L2/L3 em `docs/references/flashcards/README.md`.
