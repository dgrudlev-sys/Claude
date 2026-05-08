import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import { MMKV } from 'react-native-mmkv';
import type { BookCode } from '@/constants/bible.constants';

const storage = new MMKV({ id: 'reader' });
const mmkvStorage = {
  getItem: (key: string) => storage.getString(key) ?? null,
  setItem: (key: string, value: string) => storage.set(key, value),
  removeItem: (key: string) => storage.delete(key),
};

interface ReaderState {
  // Current position
  translationId: string;
  bookCode: BookCode;
  chapter: number;
  verse: number;
  scrollOffset: number;

  // UI state
  showVerseNumbers: boolean;
  showFootnotes: boolean;
  showCrossReferences: boolean;
  readerMode: 'normal' | 'zen'; // zen = no UI chrome

  // Actions
  setPosition: (bookCode: BookCode, chapter: number, verse?: number) => void;
  setTranslation: (translationId: string) => void;
  setScrollOffset: (offset: number) => void;
  setShowVerseNumbers: (show: boolean) => void;
  setShowFootnotes: (show: boolean) => void;
  setShowCrossReferences: (show: boolean) => void;
  setReaderMode: (mode: 'normal' | 'zen') => void;
}

export const useReaderStore = create<ReaderState>()(
  persist(
    (set) => ({
      translationId: 'de4e12af7f28f599-02', // WEB (World English Bible) — public domain default
      bookCode: 'JHN',
      chapter: 1,
      verse: 1,
      scrollOffset: 0,
      showVerseNumbers: true,
      showFootnotes: true,
      showCrossReferences: false,
      readerMode: 'normal',

      setPosition: (bookCode, chapter, verse = 1) =>
        set({ bookCode, chapter, verse, scrollOffset: 0 }),
      setTranslation: (translationId) => set({ translationId }),
      setScrollOffset: (scrollOffset) => set({ scrollOffset }),
      setShowVerseNumbers: (showVerseNumbers) => set({ showVerseNumbers }),
      setShowFootnotes: (showFootnotes) => set({ showFootnotes }),
      setShowCrossReferences: (showCrossReferences) => set({ showCrossReferences }),
      setReaderMode: (readerMode) => set({ readerMode }),
    }),
    {
      name: 'reader-position',
      storage: createJSONStorage(() => mmkvStorage),
    }
  )
);
