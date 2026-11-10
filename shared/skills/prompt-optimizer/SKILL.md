---
name: prompt-optimizer
description: Analisa prompts brutos de desenvolvedores, identifica lacunas de contexto, critérios de aceitação e limites, gerando prompts de alta precisão prontos para execução em agentes de IA.
---

# Prompt Optimizer Skill

Transforma intenções ou prompts vagos em especificações acionáveis de nível sênior para agentes de código.

## Quando Usar

- Quando o usuário disser "otimize meu prompt", "melhore este prompt", ou pedir ajuda para instruir uma IA.
- Ao estruturar tarefas arquiteturais complexas antes de despachar para agentes executores.

## Pipeline de Otimização em 5 Etapas

1. **Extração de Intenção**: Qual é o objetivo de negócio e o resultado esperado?
2. **Contexto & Stack**: Mapear linguagens, frameworks, bibliotecas existentes e diretórios envolvidos.
3. **Limites & Restrições (Boundaries)**: O que NÃO deve ser alterado? Quais dependências não podem ser adicionadas?
4. **Critérios de Aceite (Definition of Done)**: Assertivas claras, testes automatizados e validações.
5. **Formato de Saída**: Como a resposta deve ser entregue (código mínimo, diff limpo, sem prolixidade).

## Template de Prompt Otimizado Gerado

```markdown
### Objetivo
[O que deve ser construído ou refatorado em 1 frase direta]

### Contexto & Arquivos
- Arquivos alvo: `caminho/do/arquivo.ts`
- Stack: [Tecnologias existentes]

### Requisitos Técnicos
1. [Requisito 1]
2. [Requisito 2]
3. Tratamento de erros robusto sem vazamento de stacktrace para o usuário.

### Restrições
- Não adicionar novas dependências externas.
- Manter compatibilidade com a versão X.

### Validação
- Incluir 1 teste/assert simples verificando o comportamento.
```
