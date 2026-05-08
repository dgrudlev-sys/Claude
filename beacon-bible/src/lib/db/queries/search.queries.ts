import { getDatabase } from '../index';
import type { BookCode } from '@/constants/bible.constants';

export interface SearchVerseRow {
  id: number;
  bookCode: BookCode;
  bookName: string;
  chapterNumber: number;
  verseNumber: number;
  text: string;
  score: number;
}

export interface TopicVerseRow {
  id: number;
  bookCode: BookCode;
  chapterNumber: number;
  verseNumber: number;
  text: string;
  relevanceScore: number;
}

export interface CrossReferenceRow {
  targetBook: BookCode;
  targetChapter: number;
  targetVerse: number;
  refType: string;
  strength: number;
}

// Full-text search (Layer 4)
export async function ftsSearch(
  translationId: string,
  query: string,
  limit = 30
): Promise<SearchVerseRow[]> {
  const db = await getDatabase();
  // Convert query to FTS5 simple syntax: AND all terms, prefix last
  const terms = query.trim().split(/\s+/).filter(Boolean);
  if (terms.length === 0) return [];
  const ftsQuery = terms.map((t, i) =>
    i === terms.length - 1 ? `"${t}"*` : `"${t}"`
  ).join(' ');

  return db.getAllAsync<SearchVerseRow>(
    `SELECT v.id, b.book_code as bookCode, b.name as bookName,
            c.chapter_number as chapterNumber, v.verse_number as verseNumber,
            v.text_plain as text, bm25(verses_fts) * -1 as score
     FROM verses_fts
     JOIN verses v ON v.id = verses_fts.rowid
     JOIN chapters c ON c.id = v.chapter_id
     JOIN books b ON b.id = c.book_id
     WHERE verses_fts MATCH ?
       AND b.translation_id = ?
     ORDER BY score DESC
     LIMIT ?`,
    [ftsQuery, translationId, limit]
  );
}

// Topic search (Layer 3)
export async function topicSearch(
  topicSlug: string,
  translationId: string,
  limit = 25
): Promise<TopicVerseRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<TopicVerseRow>(
    `SELECT v.id, b.book_code as bookCode, c.chapter_number as chapterNumber,
            v.verse_number as verseNumber, v.text_plain as text,
            tv.relevance_score as relevanceScore
     FROM topic_verses tv
     JOIN topic_categories tc ON tc.id = tv.topic_id
     JOIN verses v ON v.id = tv.verse_id
     JOIN chapters c ON c.id = v.chapter_id
     JOIN books b ON b.id = c.book_id
     WHERE tc.slug = ? AND b.translation_id = ?
     ORDER BY tv.relevance_score DESC
     LIMIT ?`,
    [topicSlug, translationId, limit]
  );
}

// Cross-references (Layer 7)
export async function getCrossReferences(
  bookCode: BookCode,
  chapter: number,
  verse: number
): Promise<CrossReferenceRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<CrossReferenceRow>(
    `SELECT target_verse_book as targetBook,
            target_verse_chapter as targetChapter,
            target_verse_number as targetVerse,
            ref_type as refType, strength
     FROM cross_references
     WHERE source_verse_book = ?
       AND source_verse_chapter = ?
       AND source_verse_number = ?
     ORDER BY strength DESC
     LIMIT 20`,
    [bookCode, chapter, verse]
  );
}

// Entity search (Layer 6)
export async function entitySearch(query: string, translationId: string, limit = 15) {
  const db = await getDatabase();
  return db.getAllAsync(
    `SELECT e.id as entityId, e.name, e.entity_type as entityType, e.description,
            v.id as verseId, b.book_code as bookCode, c.chapter_number as chapterNumber,
            v.verse_number as verseNumber, v.text_plain as text
     FROM entities e
     JOIN entity_verses ev ON ev.entity_id = e.id
     JOIN verses v ON v.id = ev.verse_id
     JOIN chapters c ON c.id = v.chapter_id
     JOIN books b ON b.id = c.book_id
     WHERE (e.name LIKE ? OR e.name LIKE ?)
       AND b.translation_id = ?
     ORDER BY e.entity_type, e.name
     LIMIT ?`,
    [`${query}%`, `% ${query}%`, translationId, limit]
  );
}

// Misquote lookup
export async function getMisquote(normalizedText: string) {
  const db = await getDatabase();
  return db.getFirstAsync(
    `SELECT misquoted_text as misquotedText, actual_text as actualText, explanation
     FROM misquotes WHERE misquoted_text_normalized = ?`,
    [normalizedText]
  );
}
