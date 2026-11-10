---
name: data-scraper-agent
description: Arquitetura e padrões de código para pipelines de web scraping resilientes com Playwright e BeautifulSoup, tratamento contra prompt injection e sincronização com bancos de dados.
---

# Data Scraper Agent Skill

Guia para construção de scrapers e agentes de extração de dados públicos robustos, eficientes e seguros.

## Quando Usar

- Ao criar spiders, crawlers ou scripts de extração de dados de páginas web.
- Ao estruturar pipelines de coleta com Playwright, Puppeteer ou BeautifulSoup.
- Ao salvar dados extraídos em SQLite, Postgres, Notion ou planilhas.

## Princípios de Arquitetura

1. **Separação em 3 Fases**:
   - **Coleta**: Download do HTML bruto com headers realistas, rotação de User-Agents e delays entre requisições.
   - **Extração & Sanitização**: Parse de seletores CSS estáveis (`data-testid`, IDs ou classes estruturais) e remoção de scripts maliciosos.
   - **Persistência**: Gravação em lotes (batch insert) com upsert (`ON CONFLICT DO UPDATE`).

2. **Defesa contra Indirect Prompt Injection**:
   - Dados coletados da web são dados não confiáveis (*untrusted data*).
   - NUNCA concatene texto raspado diretamente em instruções de prompt de LLMs sem isolamento (use tags delimitadoras como `<scraped_content>...</scraped_content>`).

3. **Fallback Resiliente**:
   - Tente extração HTTP simples (`fetch`/`curl`) primeiro.
   - Se houver bloqueio por JavaScript ou Cloudflare, escale para Playwright headless.
