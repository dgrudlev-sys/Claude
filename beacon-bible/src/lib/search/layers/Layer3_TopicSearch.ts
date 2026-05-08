import { topicSearch } from '@/lib/db/queries/search.queries';

export interface TopicResult {
  verseId: number;
  bookCode: string;
  chapter: number;
  verse: number;
  text: string;
  score: number;
  layer: 3;
  topicSlug: string;
}

export async function searchByTopic(
  topicSlug: string,
  translationId: string
): Promise<TopicResult[]> {
  if (!topicSlug) return [];
  try {
    const rows = await topicSearch(topicSlug, translationId);
    return rows.map(row => ({
      verseId: row.id,
      bookCode: row.bookCode,
      chapter: row.chapterNumber,
      verse: row.verseNumber,
      text: row.text,
      score: row.relevanceScore * 70,
      layer: 3 as const,
      topicSlug,
    }));
  } catch {
    return [];
  }
}
