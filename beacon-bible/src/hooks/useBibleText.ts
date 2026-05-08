import { useQuery } from '@tanstack/react-query';
import type { BookCode } from '@/constants/bible.constants';
import { apiBibleService } from '@/lib/api/apiBible/apiBible.service';
import {
  getChapterVerses, saveChapterVerses, isChapterCached, type VerseRow,
} from '@/lib/db/queries/bible.queries';

export function useBibleText(
  translationId: string,
  bookCode: BookCode,
  chapter: number
) {
  return useQuery<VerseRow[]>({
    queryKey: ['bible', translationId, bookCode, chapter],
    queryFn: async () => {
      // Cache-first: check SQLite before hitting the network
      const cached = await getChapterVerses(translationId, bookCode, chapter);
      if (cached.length > 0) return cached;

      // Fetch from API.Bible
      const chapterId = `${bookCode}.${chapter}`;
      const data = await apiBibleService.getChapter(translationId, chapterId);

      // Parse content into verse rows
      const verses = parseChapterContent(data.content, chapter);
      await saveChapterVerses(translationId, bookCode, chapter, verses);

      return getChapterVerses(translationId, bookCode, chapter);
    },
    staleTime: Infinity,
    gcTime: Infinity,
    networkMode: 'offlineFirst',
    retry: 2,
  });
}

function parseChapterContent(
  content: string,
  chapter: number
): Array<{ verseNumber: number; text: string; textPlain: string }> {
  // API.Bible returns text with verse numbers in format: [1] verse text [2] next verse...
  const versePattern = /\[(\d+)\]\s*(.*?)(?=\[\d+\]|$)/gs;
  const verses: Array<{ verseNumber: number; text: string; textPlain: string }> = [];
  let match;

  while ((match = versePattern.exec(content)) !== null) {
    const verseNumber = parseInt(match[1], 10);
    const text = match[2].trim();
    const textPlain = text.replace(/<[^>]*>/g, '').trim();
    if (verseNumber && textPlain) {
      verses.push({ verseNumber, text, textPlain });
    }
  }

  // If pattern fails, treat entire content as verse 1
  if (verses.length === 0 && content.trim()) {
    const plain = content.replace(/<[^>]*>/g, '').trim();
    verses.push({ verseNumber: 1, text: content, textPlain: plain });
  }

  return verses;
}
