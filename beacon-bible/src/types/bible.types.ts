import type { BookCode } from '@/constants/bible.constants';

export interface Translation {
  id: string;
  abbreviation: string;
  name: string;
  languageCode: string;
  languageName: string;
  isDownloaded: boolean;
  downloadSizeBytes?: number;
  downloadedAt?: number;
  apiSource: 'api_bible' | 'bible_brain';
  copyright?: string;
}

export interface Book {
  id: number;
  translationId: string;
  bookCode: BookCode;
  bookNumber: number;
  name: string;
  shortName: string;
  chapterCount: number;
}

export interface Chapter {
  id: number;
  bookId: number;
  chapterNumber: number;
  verseCount: number;
}

export interface Verse {
  id: number;
  chapterId: number;
  verseNumber: number;
  text: string;
  textPlain: string;
  hasFootnote: boolean;
  footnoteText?: string;
}

export interface BibleReference {
  bookCode: BookCode;
  chapter: number;
  verseStart?: number;
  verseEnd?: number;
}

export interface Highlight {
  id: number;
  verseId: number;
  color: string;
  createdAt: number;
  updatedAt: number;
}

export interface Bookmark {
  id: number;
  verseId: number;
  label?: string;
  createdAt: number;
}

export interface Note {
  id: number;
  verseId: number;
  body: string;
  createdAt: number;
  updatedAt: number;
}

export interface ReadingPlan {
  id: number;
  externalId?: string;
  title: string;
  description?: string;
  durationDays: number;
  author?: string;
  isCurated: boolean;
  isUserCreated: boolean;
  tags: string[];
  createdAt: number;
}

export interface PlanDay {
  id: number;
  planId: number;
  dayNumber: number;
  title?: string;
  readings: PlanReading[];
  reflectionPrompt?: string;
}

export interface PlanReading {
  bookCode: BookCode;
  chapter: number;
  verses?: string; // e.g. "1-10" or "1,3,5"
}

export interface UserPlanProgress {
  planId: number;
  dayNumber: number;
  completedAt?: number;
}

export interface ReadingSession {
  id: number;
  date: string; // ISO "YYYY-MM-DD"
  chaptersRead: number;
  minutesSpent: number;
}
