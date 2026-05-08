import { BOOK_ABBREVIATIONS, BOOK_CODES, type BookCode } from '@/constants/bible.constants';

export interface ParsedReference {
  bookCode: BookCode;
  chapter: number;
  verseStart?: number;
  verseEnd?: number;
  raw: string;
}

// All common reference notation forms
const PATTERNS = [
  // "John 3:16-18", "1 Cor 13:4-7"
  /^(\d?\s?[a-zA-Z]+)\s+(\d+):(\d+)-(\d+)$/,
  // "John 3:16", "Ps 23:1"
  /^(\d?\s?[a-zA-Z]+)\s+(\d+):(\d+)$/,
  // "John 3" (whole chapter)
  /^(\d?\s?[a-zA-Z]+)\s+(\d+)$/,
  // Compact: "jn3:16", "rom8"
  /^(\d?[a-zA-Z]+)(\d+):(\d+)$/,
  /^(\d?[a-zA-Z]+)(\d+)$/,
];

function normalizeBookName(raw: string): BookCode | null {
  const normalized = raw.toLowerCase().replace(/\s+/g, '');
  return BOOK_ABBREVIATIONS[normalized] ?? null;
}

export function parseReference(query: string): ParsedReference[] {
  const q = query.trim();
  const results: ParsedReference[] = [];

  for (const pattern of PATTERNS) {
    const match = q.match(pattern);
    if (!match) continue;

    const bookRaw = match[1].trim();
    const bookCode = normalizeBookName(bookRaw);
    if (!bookCode) continue;

    const chapter = parseInt(match[2], 10);
    const verseStart = match[3] ? parseInt(match[3], 10) : undefined;
    const verseEnd = match[4] ? parseInt(match[4], 10) : undefined;

    if (isNaN(chapter) || chapter < 1) continue;

    results.push({ bookCode, chapter, verseStart, verseEnd, raw: q });
    break; // first successful parse wins
  }

  return results;
}

// Build API.Bible chapter ID from reference
export function toChapterId(bookCode: BookCode, chapter: number): string {
  return `${bookCode}.${chapter}`;
}

// Build API.Bible verse ID
export function toVerseId(bookCode: BookCode, chapter: number, verse: number): string {
  return `${bookCode}.${chapter}.${verse}`;
}
