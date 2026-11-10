# Catálogo Completo de Servidores MCP e Agent Skills para OpenCode

Este documento cataloga todos os servidores MCP e Skills mapeados no `my-setup-os`. Cada entrada contém o comando de execução, variáveis de ambiente necessárias e exemplos práticos de como pedir ao agente no OpenCode.

---

## Índice Rápido por Categoria

1. [Desenvolvimento Frontend & Navegadores](#1-desenvolvimento-frontend--navegadores)
   - Chrome DevTools, Playwright, React, Proxyman, Blender 3D
2. [Bancos de Dados & Frameworks Backend](#2-bancos-de-dados--frameworks-backend)
   - Neon Serverless Postgres, MySQL, Laravel Codebase, Laravel Companion
3. [Documentação, Código & Engenharia](#3-documentação-código--engenharia)
   - Context7, Docstar IO, OpenSpec, Better Code Review Graph, Parallel MCP, KB MCP
4. [Web Scraping & Busca](#4-web-scraping--busca)
   - Open Crawler, Google Search, HasData Scraping, Yahoo Finance
5. [CMS & Deploy](#5-cms--deploy)
   - WordPress REST, PowerWP AI, Netlify
6. [Produtividade, Tarefas & Anotações](#6-produtividade-tarefas--anotações)
   - GitHub, Atlassian (Jira/Confluence), Notion, Todoist, Evernote, Obsidian, Google Workspace, NotebookLM
7. [Segurança, Embeddings & Utilitários](#7-segurança-embeddings--utilitários)
   - Offense Research, Gemini Embedding, Boost MCP, Superpowers
8. [Skills & Agent Skills](#8-skills--agent-skills)
   - Bootstrap 5, Prompt Optimizer, Data Scraper Agent, NotebookLM Skill, Postgres Best Practices, Frontend Design

---

## 1. Desenvolvimento Frontend & Navegadores

### Chrome DevTools MCP
- **URL**: https://mcpservers.org/pt-BR/servers/chrome-devtools-mcp-server
- **Execução**:
  ```json
  "chrome-devtools": {
    "type": "local",
    "command": ["npx", "-y", "chrome-devtools-mcp@latest", "--browserUrl", "http://172.26.64.1:9222"],
    "enabled": true
  }
  ```
- **Variáveis**: Nenhuma (requer Chrome rodando com `--remote-debugging-port=9222`).
- **Como Usar**:
  > *"Abra a aba ativa no Chrome, tire um screenshot da tela de checkout e verifique se há erros no console JS."*
  > *"Inspecione o elemento com id `#main-header` e me informe o computed CSS dele."*

---

### Playwright MCP
- **URL**: https://mcpservers.org/pt-BR/servers/playwright-mcp-server
- **Execução**:
  ```json
  "playwright": {
    "type": "local",
    "command": ["npx", "-y", "@playwright/mcp@latest", "--browser", "chromium", "--headless"],
    "enabled": true
  }
  ```
- **Variáveis**: Nenhuma (ou `--cdp-endpoint` se conectar a navegador existente).
- **Como Usar**:
  > *"Acesse http://localhost:3000, clique no botão 'Cadastrar', preencha o formulário e confirme o envio."*
  > *"Tire um screenshot da página de login em resolução mobile (375x812) e avalie a responsividade."*

---

### React MCP
- **URL**: https://mcpmarket.com/server/react-1
- **Execução**:
  ```json
  "react": {
    "type": "local",
    "command": ["npx", "-y", "react-mcp@latest"],
    "enabled": true
  }
  ```
- **Variáveis**: Nenhuma.
- **Como Usar**:
  > *"Analise a árvore de componentes da tela atual e aponte re-renderizações desnecessárias."*
  > *"Verifique os hooks usados no componente `UserProfile` e sugira otimizações de `useMemo`/`useCallback`."*

---

### Proxyman MCP
- **URL**: https://mcpservers.org/pt-BR/servers/proxyman-mcp
- **Execução**:
  ```json
  "proxyman": {
    "type": "local",
    "command": ["npx", "-y", "proxyman-mcp@latest"],
    "enabled": true
  }
  ```
- **Variáveis**: `PROXYMAN_PORT` (opcional, padrão 9090).
- **Como Usar**:
  > *"Capture as requisições HTTP feitas pela aplicação nos últimos 60 segundos e me mostre as respostas 4xx e 5xx."*
  > *"Crie um mock para o endpoint `/api/v1/auth/session` retornando status 401."*

---

### Blender MCP
- **URL**: https://mcpservers.org/pt-BR/servers/blender-mcp
- **Execução** (perfil de **projeto**, `enabled: false` — ver [cad-gis-mcp-setup.md](cad-gis-mcp-setup.md)):
  ```json
  "blender": {
    "type": "local",
    "command": ["/home/livre/.local/bin/mcp-for-blender", "--host", "172.22.112.1", "--port", "9876"],
    "enabled": false,
    "timeout": 30000
  }
  ```
  Não vai em `~/.config/opencode/opencode.json`: ativar com
  `./scripts/add-cad-gis-mcp.sh <projeto>` ou pelo perfil `cad-gis-3d`.
- **Instalação**: `uv tool install --force "git+https://github.com/ahujasid/mcp-for-blender"` — o pacote do PyPI está defasado (protocolo 7) e não fala com o add-on v1.8 (protocolo 15).
- **Requisitos**: Add-on `MCP for Blender` v1.8 no Blender, com `host='0.0.0.0'` (patch no `blender_mcp.py`), `Allow Online Access` e regra de firewall na porta 9876. Desabilitar a extensão oficial da Blender Lab (conflito de porta).
- **Setup completo (WSL ↔ Windows)**: [blender-mcp-setup.md](blender-mcp-setup.md)
- **Como Usar**:
  > *"Analise a cena aberta no Blender e liste os objetos com maior contagem de polígonos que estejam fora do enquadramento da câmera."*
  > *"Renomeie os data-blocks de luzes da cena atual seguindo a convenção LGT-nome."*

---

## 2. Bancos de Dados & Frameworks Backend

### Neon MCP Server
- **URL**: https://mcpservers.org/pt-BR/servers/neondatabase/mcp-server-neon
- **Execução**:
  ```json
  "neon": {
    "type": "local",
    "command": ["npx", "-y", "@neondatabase/mcp-server-neon@latest"],
    "environment": {
      "NEON_API_KEY": "env:NEON_API_KEY"
    },
    "enabled": true
  }
  ```
- **Variáveis**: `NEON_API_KEY`.
- **Como Usar**:
  > *"Crie um branch isolado no Neon a partir da base de produção para testarmos a migração de schema."*
  > *"Liste todos os projetos Neon ativos e execute um `EXPLAIN ANALYZE` na query mais lenta da tabela pedidos."*

---

### MySQL MCP Server
- **URL**: https://mcpservers.org/pt-BR/servers/benborla/mcp-server-mysql
- **Execução**:
  ```json
  "mysql": {
    "type": "local",
    "command": ["npx", "-y", "@benborla/mcp-server-mysql@latest"],
    "environment": {
      "MYSQL_HOST": "127.0.0.1",
      "MYSQL_USER": "env:MYSQL_USER",
      "MYSQL_PASSWORD": "env:MYSQL_PASSWORD",
      "MYSQL_DATABASE": "env:MYSQL_DATABASE"
    },
    "enabled": true
  }
  ```
- **Variáveis**: `MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`.
- **Como Usar**:
  > *"Descreva o schema da tabela `pedidos` e me mostre os últimos 5 registros inseridos."*
  > *"Verifique os índices existentes na tabela `usuarios` e aponte se há queries gerando full table scan."*

---

### Laravel Codebase MCP
- **URL**: https://mcpservers.org/pt-BR/servers/Capevace/laravel-codebase-mcp
- **Execução**:
  ```json
  "laravel-codebase": {
    "type": "local",
    "command": ["npx", "-y", "laravel-codebase-mcp@latest"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Mapeie todas as rotas da API em `routes/api.php` e quais Controllers/FormRequests as atendem."*
  > *"Encontre todos os Models que usam o trait `SoftDeletes` e verifique suas migrations correspondentes."*

---

### Laravel MCP Companion
- **URL**: https://mcpservers.org/pt-BR/servers/brianirish/laravel-mcp-companion
- **Execução**:
  ```json
  "laravel-companion": {
    "type": "local",
    "command": ["npx", "-y", "laravel-mcp-companion@latest"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Execute o comando `php artisan route:list --path=api` e valide se faltam middlewares de autenticação."*
  > *"Crie uma migration para adicionar a coluna `status` indexada na tabela `faturas`."*

---

## 3. Documentação, Código & Engenharia

### Context7 MCP
- **URL**: https://mcpservers.org/pt-BR/servers/context7-mcp-server
- **Execução**:
  ```json
  "context7": {
    "type": "local",
    "command": ["npx", "-y", "context7-mcp@latest"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Consulte a documentação mais recente do TanStack Query v5 para prefetch de dados no Next.js App Router."*
  > *"Busque na API do Tailwind CSS v4 como funcionam as variáveis CSS nativas sem `tailwind.config.js`."*

---

### Docstar IO MCP
- **URL**: https://mcpservers.org/pt-BR/servers/docstar-io-mcp
- **Execução**:
  ```json
  "docstar": {
    "type": "local",
    "command": ["npx", "-y", "docstar-mcp@latest"],
    "environment": {
      "DOCSTAR_API_KEY": "env:DOCSTAR_API_KEY"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Indexe a pasta `/docs` do projeto e busque a convenção padrão para tratamento de exceções de banco."*

---

### OpenSpec MCP
- **URL**: https://mcpmarket.com/server/openspec
- **Execução**:
  ```json
  "openspec": {
    "type": "local",
    "command": ["npx", "-y", "openspec-mcp@latest"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Valide a especificação `openapi.yaml` e aponte violações de conformidade ou tipos ausentes."*
  > *"Gere os contratos de requisição TypeScript a partir do OpenAPI da rota `/api/v2/pagamentos`."*

---

### Better Code Review Graph
- **URL**: https://mcpservers.org/pt-BR/servers/n24q02m/better-code-review-graph
- **Execução**:
  ```json
  "better-code-review-graph": {
    "type": "local",
    "command": ["npx", "-y", "better-code-review-graph@latest"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Gere o grafo de impacto do commit HEAD~3 até HEAD e liste os módulos mais afetados para guiar o review."*

---

### Parallel MCP
- **URL**: https://mcpservers.org/pt-BR/servers/parallel-mcp
- **Execução**:
  ```json
  "parallel": {
    "type": "local",
    "command": ["npx", "-y", "parallel-mcp@latest"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Decomponha esta tarefa de migração em 4 subprocessos independentes e execute as verificações em paralelo."*

---

### KB MCP Server (Knowledge Base)
- **URL**: https://mcpservers.org/pt-BR/servers/Geeksfino/kb-mcp-server
- **Execução**:
  ```json
  "kb-server": {
    "type": "local",
    "command": ["uvx", "kb-mcp-server"],
    "environment": {
      "KB_STORAGE_PATH": "/home/livre/.kb-storage"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Consulte na minha base de conhecimento as regras arquiteturais decididas para o microserviço de autenticação."*

---

## 4. Web Scraping & Busca

### Open Crawler MCP
- **URL**: https://mcpservers.org/pt-BR/servers/elchika-inc/open-crawler-mcp-server
- **Execução**:
  ```json
  "open-crawler": {
    "type": "local",
    "command": ["npx", "-y", "open-crawler-mcp@latest"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Rastreie a documentação de https://exemplo.com/docs em até 2 níveis de profundidade e extraia os códigos de exemplo."*

---

### Google Search MCP
- **URL**: https://mcpservers.org/pt-BR/servers/crawlerdata/google-search-mcp-server
- **Execução**:
  ```json
  "google-search": {
    "type": "local",
    "command": ["npx", "-y", "@crawlerdata/google-search-mcp@latest"],
    "environment": {
      "SERP_API_KEY": "env:SERP_API_KEY"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Pesquise no Google os artigos mais recentes sobre 'Bun vs Node 22 benchmarks 2026' e sintetize as conclusões."*

---

### HasData Web Scraping MCP
- **URL**: https://mcpservers.org/pt-BR/servers/hasdata/web-scraping-mcp
- **Execução**:
  ```json
  "hasdata-scraping": {
    "type": "local",
    "command": ["npx", "-y", "@hasdata/mcp-server@latest"],
    "environment": {
      "HASDATA_API_KEY": "env:HASDATA_API_KEY"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Extraia a tabela de preços e os recursos da página https://concorrente.com/pricing utilizando proxy residencial para evitar bloqueio."*

---

### Yahoo Finance MCP
- **URL**: https://mcpservers.org/pt-BR/servers/yahoo-finance-mcp
- **Execução**:
  ```json
  "yahoo-finance": {
    "type": "local",
    "command": ["uvx", "mcp-server-yahoo-finance"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Consulte a cotação atual, P/E ratio e variação dos últimos 30 dias das ações da PETR4.SA e VALE3.SA."*

---

## 5. CMS & Deploy

### WordPress MCP & PowerWP AI
- **URLs**: https://mcpmarket.com/server/wordpress-3 e https://mcpservers.org/pt-BR/servers/powerwp-ai
- **Execução**:
  ```json
  "wordpress": {
    "type": "local",
    "command": ["npx", "-y", "@automattic/wordpress-mcp@latest"],
    "environment": {
      "WORDPRESS_URL": "env:WORDPRESS_URL",
      "WORDPRESS_USERNAME": "env:WORDPRESS_USERNAME",
      "WORDPRESS_APP_PASSWORD": "env:WORDPRESS_APP_PASSWORD"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Crie um rascunho de post no blog intitulado 'Novidades na Versão 2.0' com as tags 'changelog' e 'releases'."*
  > *"Liste as 10 páginas mais acessadas e atualize o meta-description da página inicial."*

---

### Netlify MCP
- **URL**: https://mcpservers.org/pt-BR/servers/netlify/netlify-mcp
- **Execução**:
  ```json
  "netlify": {
    "type": "local",
    "command": ["npx", "-y", "@netlify/mcp@latest"],
    "environment": {
      "NETLIFY_AUTH_TOKEN": "env:NETLIFY_AUTH_TOKEN"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Verifique o status do último deploy do site `meu-app.netlify.app` e mostre as últimas 20 linhas de build log caso tenha falhado."*
  > *"Configure a variável de ambiente `API_ENV=production` no projeto do Netlify."*

---

## 6. Produtividade, Tarefas & Anotações

### GitHub MCP
- **URL**: https://mcpservers.org/pt-BR/servers/github-mcp-server
- **Execução**:
  ```json
  "github": {
    "type": "local",
    "command": ["npx", "-y", "@modelcontextprotocol/server-github@latest"],
    "environment": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "env:GITHUB_TOKEN"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Crie um PR com base na branch atual para a main com o resumo das alterações de MCP configuradas."*
  > *"Liste todas as issues abertas com o label 'bug' atribuídas a mim no repositório."*

---

### Notion MCP
- **URL**: https://mcpservers.org/pt-BR/servers/notion-mcp-server
- **Execução**:
  ```json
  "notion": {
    "type": "local",
    "command": ["npx", "-y", "@modelcontextprotocol/server-notion@latest"],
    "environment": {
      "NOTION_API_KEY": "env:NOTION_API_KEY"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Consulte meu banco de dados de Roadmap no Notion e liste as tarefas em andamento para este sprint."*
  > *"Crie uma nova página em 'Anotações de Reunião' com o resumo do que discutimos hoje."*

---

### Todoist MCP
- **URL**: https://mcpservers.org/pt-BR/servers/Doist/todoist-mcp
- **Execução**:
  ```json
  "todoist": {
    "type": "local",
    "command": ["npx", "-y", "@doist/todoist-mcp@latest"],
    "environment": {
      "TODOIST_API_TOKEN": "env:TODOIST_API_TOKEN"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Adicione uma tarefa no Todoist: 'Revisar PR de configuração MCP' com vencimento para amanhã às 14:00."*

---

### Atlassian MCP (Jira / Confluence)
- **URL**: https://mcpservers.org/pt-BR/servers/atlassian-mcp-server
- **Execução**:
  ```json
  "atlassian": {
    "type": "local",
    "command": ["npx", "-y", "@atlassian/mcp-server@latest"],
    "environment": {
      "ATLASSIAN_HOST": "env:ATLASSIAN_HOST",
      "ATLASSIAN_EMAIL": "env:ATLASSIAN_EMAIL",
      "ATLASSIAN_API_TOKEN": "env:ATLASSIAN_API_TOKEN"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Mova a issue PROJ-104 no Jira para o status 'In Review' e adicione um comentário com o hash do commit."*

---

### Evernote MCP
- **URL**: https://mcpservers.org/pt-BR/servers/brentmid/evernote-mcp-server
- **Execução**:
  ```json
  "evernote": {
    "type": "local",
    "command": ["npx", "-y", "evernote-mcp@latest"],
    "environment": {
      "EVERNOTE_ACCESS_TOKEN": "env:EVERNOTE_ACCESS_TOKEN"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Busque nas minhas notas do Evernote qualquer menção ao contrato do cliente Alpha."*

---

### Obsidian Regulatory MCP
- **URL**: https://mcpservers.org/pt-BR/servers/obsidian-regulatory-mcp
- **Execução**:
  ```json
  "obsidian": {
    "type": "local",
    "command": ["npx", "-y", "obsidian-regulatory-mcp@latest"],
    "environment": {
      "OBSIDIAN_VAULT_PATH": "/home/livre/Documents/ObsidianVault"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Verifique as notas regulatórias no meu vault e aponte se faltam links de conformidade ISO 27001 no documento de infraestrutura."*

---

### NotebookLM MCP & Google Workspace MCP
- **URLs**: https://mcpservers.org/pt-BR/servers/pleaseprompto/notebooklm-mcp e https://mcpservers.org/pt-BR/servers/google/mcp
- **Execução**:
  ```json
  "notebooklm": {
    "type": "local",
    "command": ["uvx", "notebooklm-mcp"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Pergunte ao NotebookLM: qual a síntese do documento de especificação técnica que enviei no caderno de arquitetura?"*

---

## 7. Segurança, Embeddings & Utilitários

### Offense Research MCP
- **URL**: https://mcpservers.org/pt-BR/servers/offense-research/offense
- **Execução**:
  ```json
  "offense-research": {
    "type": "local",
    "command": ["uvx", "offense-mcp"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Audite a superfície de ataque deste endpoint de webhook e verifique se há vulnerabilidade a replay attacks ou SSRF."*

---

### Gemini Embedding MCP
- **URL**: https://mcpservers.org/pt-BR/servers/alaeddinemessadi/gemini-embedding-2-mcp-server
- **Execução**:
  ```json
  "gemini-embedding": {
    "type": "local",
    "command": ["uvx", "gemini-embedding-mcp"],
    "environment": {
      "GEMINI_API_KEY": "env:GEMINI_API_KEY"
    },
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Gere os vetores de embedding para a lista de termos técnicos e armazene no Qdrant para busca semântica."*

---

### Boost MCP & Superpowers
- **URLs**: https://mcpservers.org/pt-BR/servers/boost e https://mcpmarket.com/server/superpowers
- **Execução**:
  ```json
  "superpowers": {
    "type": "local",
    "command": ["npx", "-y", "@modelcontextprotocol/server-superpowers@latest"],
    "enabled": true
  }
  ```
- **Como Usar**:
  > *"Otimize o fluxo de execução deste script identificando gargalos de I/O em tempo de execução."*

---

## 8. Skills & Agent Skills

### Bootstrap 5 Overview
- **URL**: https://mcpmarket.com/tools/skills/bootstrap-5-overview
- **Instalação**: Diretório `~/.config/opencode/skills/bootstrap-5-overview/`
- **Como Usar**:
  > *"Monte a estrutura HTML responsiva de uma landing page usando Bootstrap 5.3 com container flex, grid de 3 colunas e tema dark automático."*

---

### Prompt Optimizer
- **URL**: https://mcpmarket.com/tools/skills/prompt-optimizer-1787987586910
- **Instalação**: Diretório `~/.config/opencode/skills/prompt-optimizer/`
- **Como Usar**:
  > *"Otimize meu prompt: 'preciso criar uma tela de upload em react com preview' transformando-o em instruções de nível sênior com tratamento de erros e limites de arquivo."*

---

### Data Scraper Agent
- **URL**: https://mcpmarket.com/tools/skills/data-scraper-agent-1787987361184
- **Instalação**: Diretório `~/.config/opencode/skills/data-scraper-agent/`
- **Como Usar**:
  > *"Crie um pipeline de raspagem resiliente usando Playwright e BeautifulSoup com sanitização contra prompt injection e fallback de LLM."*

---

### NotebookLM Research Assistant Skill
- **URL**: https://mcpservers.org/pt-BR/agent-skills/pleaseprompto/notebooklm-skill
- **Instalação**: Diretório `~/.config/opencode/skills/notebooklm-skill/`
- **Como Usar**:
  > *"Consulte o caderno do NotebookLM no link `https://notebooklm.google.com/notebook/XYZ` e extraia os pontos de divergência entre a proposta e a implementação."*

---

### Supabase Postgres Best Practices
- **URL**: https://mcpservers.org/pt-BR/agent-skills/supabase/postgres-best-practices
- **Instalação**: Diretório `~/.config/opencode/skills/postgres-best-practices/`
- **Como Usar**:
  > *"Revise esta migration e estas políticas de Row-Level Security (RLS) seguindo as regras de performance e índices parciais da Supabase."*

---

### Anthropic Frontend Design
- **URL**: https://mcpservers.org/pt-BR/agent-skills/anthropic/frontend-design
- **Instalação**: Diretório `~/.config/opencode/skills/frontend-design/`
- **Como Usar**:
  > *"Crie uma interface web deliberada e profissional para um painel de inteligência de dados, evitando estéticas genéricas de IA (sem degradês padrão, fontes sem personalidade ou cartões idênticos)."*
