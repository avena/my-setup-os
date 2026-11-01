---
name: postgres-best-practices
description: Otimização de performance e melhores práticas de PostgreSQL e Supabase. Use ao escrever, revisar ou otimizar consultas SQL, migrations, índices e políticas de Row-Level Security (RLS).
---

# Supabase Postgres Best Practices Skill

Guia de otimização de alta performance e segurança para PostgreSQL e Supabase.

## Quando Usar

- Ao escrever consultas SQL ou desenhar schemas relacionais.
- Ao criar ou otimizar índices (índices parciais, compostos, B-Tree, GIN).
- Ao revisar políticas de segurança em nível de linha (RLS).
- Ao analisar relatórios de lentidão (`EXPLAIN ANALYZE`).

## Regras Críticas por Prioridade

### 1. Performance de Queries & Índices
- **Chaves Estrangeiras Indexadas**: Crie sempre índice em colunas de chave estrangeira (`REFERENCES`) para evitar sequential scans em joins e deletes em cascata.
- **Índices Parciais**: Se uma query filtra comumente um subconjunto de linhas (ex: `WHERE status = 'ativo'`), use `CREATE INDEX idx_pedidos_ativos ON pedidos (cliente_id) WHERE status = 'ativo'`.
- **Evite SELECT \***: Retorne apenas as colunas estritamente necessárias para economizar I/O e permitir *Index-Only Scans*.

### 2. Row-Level Security (RLS)
- Sempre garanta que as colunas avaliadas nas cláusulas de política RLS possuam índices adequados.
- Evite subconsultas complexas dentro de políticas RLS executadas para cada linha (*per-row subqueries*); prefira funções `STABLE` ou `SECURITY DEFINER` cacheadas na sessão.

### 3. Migrations Seguras
- Ao adicionar novas colunas com valores default em tabelas volumosas, use sintaxe que não force lock exclusivo da tabela inteira.
- Adicione índices em produção sempre com `CREATE INDEX CONCURRENTLY`.
