# CrawlSEO - Setup em Container

Painel de auditoria e automação SEO com Next.js, Worker e PostgreSQL.

## Portas e Serviços
- **Aplicação Web:** `http://localhost:3000`
- **PostgreSQL:** `localhost:5432`

## Pontos Críticos
1. **Google OAuth Obrigatório:** Crie as credenciais no Google Cloud Console com URI de redirecionamento `http://localhost:3000/api/auth/callback/google` e preencha `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` no arquivo `.env`.
2. **NEXTAUTH_SECRET:** Usado para criptografar chaves no banco. O script gera um valor aleatório automaticamente. Não altere após o primeiro uso para não invalidar tokens salvos.
3. **Filesystem WSL Nativo:** O clone reside em `~/projetos/crawlseo` (ext4) para garantir performance do banco e evitar erros de permissão de disco.

## Logs
- Logs de setup: `logs/setup-*.log`
- Ver logs dos containers em execução:
  ```bash
  docker compose logs -f app
  docker compose logs -f db
  ```
