import { classifyIntent } from './layers/Layer0_IntentClassifier';
import { parseReference } from './layers/Layer1_ReferenceParser';
import { phraseMatch } from './layers/Layer2_PhraseMatch';
import { searchByTopic } from './layers/Layer3_TopicSearch';
import { fullTextSearch } from './layers/Layer4_FullTextSearch';
import { detectMisquote, type MisquoteResult } from './MisquoteDetector';
import { entitySearch } from '@/lib/db/queries/search.queries';
import type { BookCode } from '@/constants/bible.constants';

export type SearchResultLayer = 1 | 2 | 3 | 4 | 5 | 6 | 7;

export interface VerseSearchResult {
  type: 'verse';
  verseId?: number;
  bookCode: BookCode;
  chapter: number;
  verse: number;
  text?: string;
  score: number;
  layer: SearchResultLayer;
}

export interface MisquoteSearchResult {
  type: 'misquote';
  misquoteData: MisquoteResult;
  score: 95;
  layer: 0;
}

export interface ReferenceSearchResult {
  type: 'reference';
  bookCode: BookCode;
  chapter: number;
  verse?: number;
  score: 100;
  layer: 1;
}

export type AnySearchResult =
  | ReferenceSearchResult
  | MisquoteSearchResult
  | VerseSearchResult;

export async function search(
  rawQuery: string,
  translationId: string
): Promise<AnySearchResult[]> {
  const query = rawQuery.trim();
  if (!query) return [];

  const intent = classifyIntent(query);

  // Layer 1 — Reference parse: highest confidence, return immediately
  if (intent.type === 'reference') {
    const refs = parseReference(query);
    if (refs.length > 0) {
      return refs.map(ref => ({
        type: 'reference' as const,
        bookCode: ref.bookCode,
        chapter: ref.chapter,
        verse: ref.verseStart,
        score: 100 as const,
        layer: 1 as const,
      }));
    }
  }

  // Misquote detection — runs in parallel with phrase search
  const [misquote, phraseResults] = await Promise.all([
    Promise.resolve(detectMisquote(query)),
    phraseMatch(query, translationId),
  ]);

  if (misquote) {
    return [{
      type: 'misquote' as const,
      misquoteData: misquote,
      score: 95 as const,
      layer: 0 as const,
    }];
  }

  if (phraseResults.length >= 3) {
    return phraseResults.map(r => ({
      type: 'verse' as const,
      verseId: r.verseId,
      bookCode: r.bookCode as BookCode,
      chapter: r.chapter,
      verse: r.verse,
      text: r.text,
      score: r.score,
      layer: r.layer,
    }));
  }

  // Layer 3 — Topic/thematic
  if (intent.type === 'emotional' || intent.type === 'thematic' || intent.type === 'question') {
    if (intent.topicSlug) {
      const topicResults = await searchByTopic(intent.topicSlug, translationId);
      if (topicResults.length > 0) {
        return topicResults.map(r => ({
          type: 'verse' as const,
          verseId: r.verseId,
          bookCode: r.bookCode as BookCode,
          chapter: r.chapter,
          verse: r.verse,
          text: r.text,
          score: r.score,
          layer: r.layer,
        }));
      }
    }
  }

  // Layer 4 — Full text search (broad fallback)
  const ftsResults = await fullTextSearch(query, translationId, 30);

  // Layer 6 — Entity search in parallel
  const entityRows = intent.type === 'entity'
    ? await entitySearch(query, translationId, 10).catch(() => [])
    : [];

  // Merge and deduplicate by verseId
  const all: VerseSearchResult[] = [
    ...phraseResults.map(r => ({
      type: 'verse' as const,
      verseId: r.verseId,
      bookCode: r.bookCode as BookCode,
      chapter: r.chapter,
      verse: r.verse,
      text: r.text,
      score: r.score,
      layer: r.layer,
    })),
    ...ftsResults.map(r => ({
      type: 'verse' as const,
      verseId: r.verseId,
      bookCode: r.bookCode as BookCode,
      chapter: r.chapter,
      verse: r.verse,
      text: r.text,
      score: r.score,
      layer: r.layer,
    })),
  ];

  const seen = new Set<number>();
  const deduped = all.filter(r => {
    if (r.verseId === undefined) return true;
    if (seen.has(r.verseId)) return false;
    seen.add(r.verseId);
    return true;
  });

  return deduped.sort((a, b) => b.score - a.score).slice(0, 30);
}
