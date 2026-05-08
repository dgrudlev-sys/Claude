import { getDatabase } from '../index';

export interface HighlightRow {
  id: number;
  verseId: number;
  color: string;
  createdAt: number;
}

export interface BookmarkRow {
  id: number;
  verseId: number;
  label: string | null;
  createdAt: number;
}

export interface NoteRow {
  id: number;
  verseId: number;
  body: string;
  createdAt: number;
  updatedAt: number;
}

// Highlights
export async function getHighlightsForChapter(chapterVerseIds: number[]): Promise<HighlightRow[]> {
  if (chapterVerseIds.length === 0) return [];
  const db = await getDatabase();
  const placeholders = chapterVerseIds.map(() => '?').join(',');
  return db.getAllAsync<HighlightRow>(
    `SELECT id, verse_id as verseId, color, created_at as createdAt
     FROM highlights WHERE verse_id IN (${placeholders})`,
    chapterVerseIds
  );
}

export async function upsertHighlight(verseId: number, color: string): Promise<void> {
  const db = await getDatabase();
  await db.runAsync(
    `INSERT INTO highlights(verse_id, color) VALUES (?, ?)
     ON CONFLICT(verse_id) DO UPDATE SET color = excluded.color, updated_at = strftime('%s','now')`,
    [verseId, color]
  );
}

export async function removeHighlight(verseId: number): Promise<void> {
  const db = await getDatabase();
  await db.runAsync('DELETE FROM highlights WHERE verse_id = ?', [verseId]);
}

// Bookmarks
export async function isVerseBookmarked(verseId: number): Promise<boolean> {
  const db = await getDatabase();
  const row = await db.getFirstAsync<{ id: number }>(
    'SELECT id FROM bookmarks WHERE verse_id = ?', [verseId]
  );
  return row !== null;
}

export async function toggleBookmark(verseId: number, label?: string): Promise<boolean> {
  const db = await getDatabase();
  const existing = await db.getFirstAsync<{ id: number }>(
    'SELECT id FROM bookmarks WHERE verse_id = ?', [verseId]
  );
  if (existing) {
    await db.runAsync('DELETE FROM bookmarks WHERE verse_id = ?', [verseId]);
    return false;
  } else {
    await db.runAsync(
      'INSERT INTO bookmarks(verse_id, label) VALUES (?, ?)',
      [verseId, label ?? null]
    );
    return true;
  }
}

export async function getAllBookmarks(): Promise<BookmarkRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<BookmarkRow>(
    `SELECT id, verse_id as verseId, label, created_at as createdAt
     FROM bookmarks ORDER BY created_at DESC`
  );
}

// Notes
export async function getNoteForVerse(verseId: number): Promise<NoteRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<NoteRow>(
    `SELECT id, verse_id as verseId, body, created_at as createdAt, updated_at as updatedAt
     FROM notes WHERE verse_id = ?`,
    [verseId]
  );
}

export async function upsertNote(verseId: number, body: string): Promise<void> {
  const db = await getDatabase();
  await db.runAsync(
    `INSERT INTO notes(verse_id, body) VALUES (?, ?)
     ON CONFLICT(verse_id) DO UPDATE SET body = excluded.body, updated_at = strftime('%s','now')`,
    [verseId, body]
  );
}

export async function getAllNotes(): Promise<NoteRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<NoteRow>(
    `SELECT id, verse_id as verseId, body, created_at as createdAt, updated_at as updatedAt
     FROM notes ORDER BY updated_at DESC`
  );
}

// Reading sessions + streaks
export async function markTodayRead(chaptersRead = 1): Promise<void> {
  const db = await getDatabase();
  const today = new Date().toISOString().split('T')[0];
  await db.runAsync(
    `INSERT INTO reading_sessions(date, chapters_read, minutes_spent) VALUES (?, ?, 0)
     ON CONFLICT(date) DO UPDATE SET chapters_read = chapters_read + ?`,
    [today, chaptersRead, chaptersRead]
  );
}

export async function getStreakCount(): Promise<number> {
  const db = await getDatabase();
  const rows = await db.getAllAsync<{ date: string }>(
    'SELECT date FROM reading_sessions ORDER BY date DESC LIMIT 365'
  );
  if (rows.length === 0) return 0;

  let streak = 0;
  const today = new Date();
  for (let i = 0; i < rows.length; i++) {
    const expected = new Date(today);
    expected.setDate(today.getDate() - i);
    const expectedStr = expected.toISOString().split('T')[0];
    if (rows[i]?.date === expectedStr) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
