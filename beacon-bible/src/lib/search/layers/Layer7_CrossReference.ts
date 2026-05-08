import { getCrossReferences, type CrossReferenceRow } from '@/lib/db/queries/search.queries';
import type { BookCode } from '@/constants/bible.constants';

export interface CrossRefResult {
  targetBook: BookCode;
  targetChapter: number;
  targetVerse: number;
  refType: string;
  strength: number;
  layer: 7;
}

export async function getVerseXRefs(
  bookCode: BookCode,
  chapter: number,
  verse: number
): Promise<CrossRefResult[]> {
  try {
    const rows = await getCrossReferences(bookCode, chapter, verse);
    return rows.map(row => ({
      targetBook: row.targetBook,
      targetChapter: row.targetChapter,
      targetVerse: row.targetVerse,
      refType: row.refType,
      strength: row.strength,
      layer: 7 as const,
    }));
  } catch {
    return [];
  }
}
