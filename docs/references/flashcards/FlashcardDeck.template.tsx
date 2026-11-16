import React, { useState, useEffect, useMemo, useCallback } from 'react';

// ponytail: sem FSRS complexo nem backend; adicione ts-fsrs + Drizzle/Postgres se precisar de repetição agendada real
export type FlashcardLevel = 'L1' | 'L2' | 'L3';
export type ReviewRating = 'again' | 'hard' | 'good' | 'easy';

export interface FlashcardItem {
  id: string;
  topic: string;
  level: FlashcardLevel;
  question: string;
  answer: string;
  extraNote?: string;
}

interface FlashcardDeckProps {
  cards: FlashcardItem[];
  storageKey?: string;
}

const RATINGS: { key: ReviewRating; label: string; shortcut: string; color: string }[] = [
  { key: 'again', label: 'Again', shortcut: '1', color: 'hover:border-red-500 hover:text-red-500' },
  { key: 'hard', label: 'Hard', shortcut: '2', color: 'hover:border-amber-500 hover:text-amber-500' },
  { key: 'good', label: 'Good', shortcut: '3', color: 'hover:border-blue-500 hover:text-blue-500' },
  { key: 'easy', label: 'Easy', shortcut: '4', color: 'hover:border-emerald-500 hover:text-emerald-500' },
];

export const FlashcardDeck: React.FC<FlashcardDeckProps> = ({
  cards,
  storageKey = 'flashcard-deck-reviews',
}) => {
  const [levelFilter, setLevelFilter] = useState<string>('ALL');
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isFlipped, setIsFlipped] = useState(false);
  const [reviews, setReviews] = useState<Record<string, ReviewRating>>(() => {
    if (typeof window === 'undefined') return {};
    try {
      const saved = localStorage.getItem(storageKey);
      return saved ? JSON.parse(saved) : {};
    } catch {
      return {};
    }
  });

  const filteredCards = useMemo(() => {
    if (levelFilter === 'ALL') return cards;
    return cards.filter((c) => c.level === levelFilter);
  }, [cards, levelFilter]);

  const currentCard = filteredCards[currentIndex];

  const handleNext = useCallback(() => {
    setIsFlipped(false);
    setCurrentIndex((prev) => (prev + 1 < filteredCards.length ? prev + 1 : 0));
  }, [filteredCards.length]);

  const handlePrev = useCallback(() => {
    setIsFlipped(false);
    setCurrentIndex((prev) => (prev - 1 >= 0 ? prev - 1 : filteredCards.length - 1));
  }, [filteredCards.length]);

  const handleFlip = useCallback(() => {
    setIsFlipped((prev) => !prev);
  }, []);

  const handleRate = useCallback(
    (rating: ReviewRating) => {
      if (!currentCard) return;
      setReviews((prev) => {
        const next = { ...prev, [currentCard.id]: rating };
        try {
          localStorage.setItem(storageKey, JSON.stringify(next));
        } catch {
          // storage quota ou modo privado
        }
        return next;
      });
      handleNext();
    },
    [currentCard, handleNext, storageKey]
  );

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      if (target && ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName)) return;

      if (e.code === 'Space' || e.key === 'Enter') {
        e.preventDefault();
        handleFlip();
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        handleNext();
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        handlePrev();
      } else if (isFlipped && ['1', '2', '3', '4'].includes(e.key)) {
        e.preventDefault();
        const map: Record<string, ReviewRating> = { '1': 'again', '2': 'hard', '3': 'good', '4': 'easy' };
        handleRate(map[e.key]);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleFlip, handleNext, handlePrev, handleRate, isFlipped]);

  if (!filteredCards.length) {
    return (
      <div className="flex flex-col items-center justify-center p-8 text-center text-slate-500">
        <p>Nenhum cartão encontrado para este filtro.</p>
        <button
          onClick={() => setLevelFilter('ALL')}
          className="mt-4 px-3 py-1.5 text-sm font-medium bg-slate-100 rounded hover:bg-slate-200 dark:bg-slate-800"
        >
          Limpar Filtro
        </button>
      </div>
    );
  }

  const reviewedCount = Object.keys(reviews).filter((id) =>
    filteredCards.some((c) => c.id === id)
  ).length;

  return (
    <div className="w-full max-w-2xl mx-auto flex flex-col items-center gap-4 p-4 select-none">
      {/* Top Bar: Filtros e Progresso */}
      <div className="w-full flex items-center justify-between text-xs text-slate-500">
        <div className="flex gap-1.5">
          {['ALL', 'L1', 'L2', 'L3'].map((lvl) => (
            <button
              key={lvl}
              onClick={() => {
                setLevelFilter(lvl);
                setCurrentIndex(0);
                setIsFlipped(false);
              }}
              className={`px-2.5 py-1 rounded border transition-colors ${
                levelFilter === lvl
                  ? 'border-indigo-600 bg-indigo-50 text-indigo-700 font-semibold dark:bg-indigo-950/40 dark:text-indigo-300'
                  : 'border-slate-200 hover:border-slate-300 dark:border-slate-800'
              }`}
            >
              {lvl === 'ALL' ? 'Todos' : lvl}
            </button>
          ))}
        </div>
        <div className="font-mono">
          {currentIndex + 1} / {filteredCards.length} (Revistos: {reviewedCount})
        </div>
      </div>

      {/* Barra de Progresso */}
      <div className="w-full bg-slate-100 dark:bg-slate-800 h-1.5 rounded-full overflow-hidden">
        <div
          className="bg-indigo-600 h-full transition-all duration-300"
          style={{ width: `${((currentIndex + 1) / filteredCards.length) * 100}%` }}
        />
      </div>

      {/* Cartão 3D Flip */}
      <div
        className="w-full h-80 flashcard-perspective cursor-pointer"
        onClick={handleFlip}
      >
        <div className={`flashcard-inner ${isFlipped ? 'flipped' : ''}`}>
          {/* Frente */}
          <div className="flashcard-face flex flex-col justify-between p-6 rounded-xl border border-slate-200 bg-white shadow-sm dark:bg-slate-900 dark:border-slate-800">
            <div className="flex justify-between items-center text-xs text-slate-400 uppercase tracking-wider font-semibold">
              <span>{currentCard.topic}</span>
              <span className="px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                {currentCard.level}
              </span>
            </div>
            <div className="text-center text-lg md:text-xl font-medium text-slate-800 dark:text-slate-100 px-4">
              {currentCard.question}
            </div>
            <div className="text-center text-xs text-slate-400">Clique ou aperte Espaço para virar</div>
          </div>

          {/* Verso */}
          <div className="flashcard-face flashcard-back flex flex-col justify-between p-6 rounded-xl border border-slate-200 bg-slate-50 shadow-sm dark:bg-slate-900/90 dark:border-slate-800">
            <div className="flex justify-between items-center text-xs text-slate-400 uppercase tracking-wider font-semibold">
              <span>Resposta</span>
              <span className="px-2 py-0.5 rounded bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                {currentCard.level}
              </span>
            </div>
            <div className="text-center space-y-2 px-4">
              <div className="text-base md:text-lg font-normal text-slate-700 dark:text-slate-200">
                {currentCard.answer}
              </div>
              {currentCard.extraNote && (
                <div className="text-xs text-slate-500 italic mt-2 border-t pt-2 border-slate-200 dark:border-slate-800">
                  {currentCard.extraNote}
                </div>
              )}
            </div>
            <div className="text-center text-xs text-slate-400">Classifique para avançar</div>
          </div>
        </div>
      </div>

      {/* Ações de Avaliação (quando virado) */}
      <div className={`w-full grid grid-cols-4 gap-2 transition-opacity duration-200 ${isFlipped ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
        {RATINGS.map((r) => (
          <button
            key={r.key}
            onClick={(e) => {
              e.stopPropagation();
              handleRate(r.key);
            }}
            className={`flex flex-col items-center justify-center p-2 rounded-lg border border-slate-200 bg-white text-xs font-medium text-slate-700 dark:bg-slate-900 dark:border-slate-800 dark:text-slate-200 transition-colors ${r.color}`}
          >
            <span>{r.label}</span>
            <kbd className="mt-1 text-[10px] text-slate-400 px-1 py-0.5 bg-slate-100 dark:bg-slate-800 rounded">
              {r.shortcut}
            </kbd>
          </button>
        ))}
      </div>

      {/* Rodapé / Atalhos */}
      <div className="flex items-center gap-4 text-xs text-slate-400 mt-2">
        <button onClick={handlePrev} className="hover:text-slate-600 dark:hover:text-slate-200">
          ← Anterior
        </button>
        <span className="flex items-center gap-1">
          <kbd className="px-1.5 py-0.5 bg-slate-100 dark:bg-slate-800 border rounded text-[10px]">Espaço</kbd> Virar
        </span>
        <span className="flex items-center gap-1">
          <kbd className="px-1 py-0.5 bg-slate-100 dark:bg-slate-800 border rounded text-[10px]">←</kbd>
          <kbd className="px-1 py-0.5 bg-slate-100 dark:bg-slate-800 border rounded text-[10px]">→</kbd> Navegar
        </span>
        <button onClick={handleNext} className="hover:text-slate-600 dark:hover:text-slate-200">
          Próximo →
        </button>
      </div>
    </div>
  );
};
