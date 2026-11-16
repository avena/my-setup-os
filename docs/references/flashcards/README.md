# Flashcards: Guia de Arquitetura & Templates Reutilizáveis

Base de conhecimento arquitetural e modelos agnósticos para implementar módulos de estudo ativo e flashcards em qualquer projeto web (Next.js, React puro, Astro, Vite).

---

## 1. As 6 URLs de Referência

| Repositório | Papel Principal | O que Extrair / Reutilizar |
| :--- | :--- | :--- |
| [DylanFriday/flashcard-ai-generator](https://github.com/DylanFriday/flashcard-ai-generator) | **Frontend & UI Base (Vencedor Visual)** | Flip 3D em CSS puro (`preserve-3d`), barra de progresso, tags `<kbd>` e botões de repetição espaçada (`Again`, `Hard`, `Good`, `Easy`). Descartar Postgres/Drizzle para casos leves. |
| [SYuan03/Skill-Anything](https://github.com/SYuan03/Skill-Anything) | **Pipeline Multimodal** | Pipeline de conversão de PDFs, vídeos (transcrições) e áudios para baralhos estruturados e páginas HTML autônomas. |
| [jalliet/flashcards](https://github.com/jalliet/flashcards) | **Pedagogia Cognitiva (L1/L2/L3)** | Estruturação de perguntas em 3 níveis: L1 (Definição), L2 (Compreensão Prática), L3 (Armadilhas e Casos Limite). |
| [maaarcooo/agent-skills](https://github.com/maaarcooo/agent-skills) | **Prompts de Atomicidade** | Regras de uma ideia por cartão, perguntas concisas e foco em retenção sem sobrecarga cognitiva. |
| [vishnujayvel/flashcard-skill](https://github.com/vishnujayvel/flashcard-skill) | **Extração Web Tabular** | Scraping e parsing de páginas de documentação técnica para pares Pergunta/Resposta. |
| [OneWave-AI/claude-skills](https://github.com/OneWave-AI/claude-skills) | **Catálogo de Skills** | Padrões de engenharia de prompt para orquestração de agentes. |

---

## 2. Metodologia Pedagógica (Taxonomia L1 / L2 / L3)

Ao gerar cartões de qualquer domínio, aplique a distribuição:

* **L1 - Recordação / Definição (~40%):** "O que é X?" Fatos diretos, sintaxe, termos técnicos e fórmulas.
* **L2 - Compreensão / Intuição (~40%):** "Por que X acontece?" ou "Como funciona na prática?" Relações de causa/efeito e decisão técnica.
* **L3 - Limites / Armadilhas (~20%):** "Quando X falha ou não deve ser usado?" Edge cases, pegadinhas comuns e trade-offs.

---

## 3. Checklist de Implementação em Projeto Novo

1. **CSS 3D:** Copie o conteúdo de [`flashcard-3d-flip.css`](./flashcard-3d-flip.css) para o seu CSS global (`src/app/globals.css` ou `src/index.css`).
2. **Componente:** Copie [`FlashcardDeck.template.tsx`](./FlashcardDeck.template.tsx) para `components/FlashcardDeck.tsx`.
3. **Dados:** Crie um arquivo `cards.ts` exportando `FlashcardItem[]`.
4. **Geração via IA:** Rode o prompt abaixo para popular os cartões do tema desejado.

---

## 4. Prompt-Mestre para Gerar Decks (Qualquer Tema)

Copie e envie para a IA geradora de conteúdo:

```markdown
Você é um especialista em pedagogia e repetição espaçada. Gere um conjunto de flashcards em formato TypeScript para o tema: [INSERIR TEMA / TECNOLOGIA / ASSUNTO].

Regras obrigatórias:
1. Respeite a distribuição cognitiva:
   - 40% Nível L1 (Fatos, definições diretas, termos fundamentais)
   - 40% Nível L2 (Causa e efeito, intuição de funcionamento, exemplos práticos)
   - 20% Nível L3 (Armadilhas comuns, limitações, quando NÃO usar)
2. Atomicidade: 1 pergunta e 1 resposta objetiva por cartão (máximo 2 a 3 frases por resposta).
3. Saída estritamente em TypeScript seguindo a interface:

```typescript
export interface FlashcardItem {
  id: string;
  topic: string;
  level: 'L1' | 'L2' | 'L3';
  question: string;
  answer: string;
  extraNote?: string;
}

export const FLASHCARDS_DATA: FlashcardItem[] = [
  // preencha aqui os cartões gerados
];
```
```

---

## 5. Inspeção Sob Demanda

Para inspecionar os arquivos originais dos repositórios de referência sem cloná-los no projeto:

```bash
# Baixa arquivos principais em /tmp/flashcard-refs:
./docs/references/flashcards/fetch-upstream-refs.sh

# Ou clona em /tmp com --depth 1 para leitura profunda:
./docs/references/flashcards/fetch-upstream-refs.sh --clone
```
