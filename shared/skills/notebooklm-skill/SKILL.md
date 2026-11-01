---
name: notebooklm-skill
description: Integração e consulta assistida a cadernos do Google NotebookLM. Use para pesquisar documentações e obter respostas fundamentadas estritamente nas fontes dos cadernos.
---

# NotebookLM Skill

Permite consultar cadernos do Google NotebookLM para obter respostas fundamentadas e validadas em documentos técnicos.

## Quando Usar

- Quando o usuário mencionar NotebookLM ou fornecer uma URL do tipo `https://notebooklm.google.com/notebook/...`.
- Para extrair sínteses fundamentadas exclusivamente nos arquivos do caderno.

## Fluxo de Operação

1. **Descoberta Inteligente**:
   - Se o caderno não possui metadados descritos, consulte o objetivo geral do caderno:
     *"Qual é o resumo e tópicos cobertos por este caderno?"*
2. **Execução de Consultas**:
   - Submeta a pergunta ao script ou cliente MCP integrado ao NotebookLM.
3. **Mecanismo de Follow-Up Obrigatório**:
   - Verifique a resposta obtida contra o objetivo do usuário.
   - Identifique lacunas e elabore perguntas de aprofundamento antes de finalizar.
   - Entregue a síntese final com referências às fontes.
