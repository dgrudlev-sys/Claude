import { ftsSearch, type SearchVerseRow } from '@/lib/db/queries/search.queries';

export interface FTSResult {
  verseId: number;
  bookCode: string;
  bookName: string;
  chapter: number;
  verse: number;
  text: string;
  score: number;
  layer: 4;
}

export async function fullTextSearch(
  query: string,
  translationId: string,
  limit = 30
): Promise<FTSResult[]> {
  if (!query.trim()) return [];

  try {
    const rows = await ftsSearch(translationId, query, limit);
    return rows.map(row => ({
      verseId: row.id,
      bookCode: row.bookCode,
      bookName: row.bookName,
      chapter: row.chapterNumber,
      verse: row.verseNumber,
      text: row.text,
      score: row.score,
      layer: 4 as const,
    }));
  } catch {
    // FTS table may not be populated yet — graceful degradation
    return [];
  }
}
