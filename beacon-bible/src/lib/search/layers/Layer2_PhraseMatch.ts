import levenshtein from 'fast-levenshtein';
import { ftsSearch } from '@/lib/db/queries/search.queries';

export interface PhraseResult {
  verseId: number;
  bookCode: string;
  chapter: number;
  verse: number;
  text: string;
  score: number;
  layer: 2;
  matchDistance: number;
}

export async function phraseMatch(
  query: string,
  translationId: string
): Promise<PhraseResult[]> {
  if (!query.trim()) return [];

  // Pass 1: exact phrase via FTS5
  const exactRows = await ftsSearch(translationId, `"${query}"`, 10).catch(() => []);

  if (exactRows.length > 0) {
    return exactRows.map(row => ({
      verseId: row.id,
      bookCode: row.bookCode,
      chapter: row.chapterNumber,
      verse: row.verseNumber,
      text: row.text,
      score: 85,
      layer: 2 as const,
      matchDistance: 0,
    }));
  }

  // Pass 2: loose FTS then Levenshtein re-rank
  const looseRows = await ftsSearch(translationId, query, 50).catch(() => []);
  const qNorm = query.toLowerCase();

  const scored = looseRows
    .map(row => {
      const textNorm = row.text.toLowerCase();
      // Find the substring window closest to query length
      const windowSize = qNorm.length;
      let minDist = Infinity;
      for (let i = 0; i <= textNorm.length - windowSize; i++) {
        const window = textNorm.slice(i, i + windowSize);
        const dist = levenshtein.get(qNorm, window);
        if (dist < minDist) minDist = dist;
      }
      const normalizedDist = minDist / windowSize;
      return { row, normalizedDist };
    })
    .filter(({ normalizedDist }) => normalizedDist < 0.4)
    .sort((a, b) => a.normalizedDist - b.normalizedDist)
    .slice(0, 15);

  return scored.map(({ row, normalizedDist }) => ({
    verseId: row.id,
    bookCode: row.bookCode,
    chapter: row.chapterNumber,
    verse: row.verseNumber,
    text: row.text,
    score: 80 * (1 - normalizedDist),
    layer: 2 as const,
    matchDistance: normalizedDist,
  }));
}
