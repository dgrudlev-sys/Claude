import { getDatabase } from '../index';
import type { BookCode } from '@/constants/bible.constants';

export interface VerseRow {
  id: number;
  verseNumber: number;
  text: string;
  textPlain: string;
  hasFootnote: number;
  footnoteText: string | null;
}

export interface ChapterResult {
  verses: VerseRow[];
  bookCode: BookCode;
  chapterNumber: number;
  translationId: string;
}

export async function getChapterVerses(
  translationId: string,
  bookCode: BookCode,
  chapterNumber: number
): Promise<VerseRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<VerseRow>(
    `SELECT v.id, v.verse_number as verseNumber, v.text, v.text_plain as textPlain,
            v.has_footnote as hasFootnote, v.footnote_text as footnoteText
     FROM verses v
     JOIN chapters c ON c.id = v.chapter_id
     JOIN books b ON b.id = c.book_id
     WHERE b.translation_id = ? AND b.book_code = ? AND c.chapter_number = ?
     ORDER BY v.verse_number`,
    [translationId, bookCode, chapterNumber]
  );
}

export async function saveChapterVerses(
  translationId: string,
  bookCode: BookCode,
  chapterNumber: number,
  verses: Array<{ verseNumber: number; text: string; textPlain: string }>
): Promise<void> {
  const db = await getDatabase();

  await db.withTransactionAsync(async () => {
    // Ensure book row exists
    await db.runAsync(
      `INSERT OR IGNORE INTO books(translation_id, book_code, book_number, name, short_name, chapter_count)
       VALUES (?, ?, 0, ?, ?, 0)`,
      [translationId, bookCode, bookCode, bookCode]
    );

    const bookRow = await db.getFirstAsync<{ id: number }>(
      'SELECT id FROM books WHERE translation_id = ? AND book_code = ?',
      [translationId, bookCode]
    );
    if (!bookRow) return;

    // Ensure chapter row exists
    await db.runAsync(
      `INSERT OR IGNORE INTO chapters(book_id, chapter_number, verse_count) VALUES (?, ?, ?)`,
      [bookRow.id, chapterNumber, verses.length]
    );

    const chapterRow = await db.getFirstAsync<{ id: number }>(
      'SELECT id FROM chapters WHERE book_id = ? AND chapter_number = ?',
      [bookRow.id, chapterNumber]
    );
    if (!chapterRow) return;

    for (const v of verses) {
      await db.runAsync(
        `INSERT OR IGNORE INTO verses(chapter_id, verse_number, text, text_plain)
         VALUES (?, ?, ?, ?)`,
        [chapterRow.id, v.verseNumber, v.text, v.textPlain]
      );
    }
  });
}

export async function isChapterCached(
  translationId: string,
  bookCode: BookCode,
  chapterNumber: number
): Promise<boolean> {
  const db = await getDatabase();
  const row = await db.getFirstAsync<{ count: number }>(
    `SELECT COUNT(*) as count FROM verses v
     JOIN chapters c ON c.id = v.chapter_id
     JOIN books b ON b.id = c.book_id
     WHERE b.translation_id = ? AND b.book_code = ? AND c.chapter_number = ?`,
    [translationId, bookCode, chapterNumber]
  );
  return (row?.count ?? 0) > 0;
}

export async function getVerseById(verseId: number): Promise<VerseRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<VerseRow>(
    `SELECT id, verse_number as verseNumber, text, text_plain as textPlain,
            has_footnote as hasFootnote, footnote_text as footnoteText
     FROM verses WHERE id = ?`,
    [verseId]
  );
}
