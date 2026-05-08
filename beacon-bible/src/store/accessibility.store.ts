import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import { MMKV } from 'react-native-mmkv';
import type { ColorTheme, } from '@/constants/colors';
import type { FontFamily, ReaderFontSize } from '@/constants/typography';

const storage = new MMKV({ id: 'accessibility' });

const mmkvStorage = {
  getItem: (key: string) => storage.getString(key) ?? null,
  setItem: (key: string, value: string) => storage.set(key, value),
  removeItem: (key: string) => storage.delete(key),
};

export type ColourBlindMode = 'none' | 'deuteranopia' | 'protanopia' | 'tritanopia';

interface AccessibilityState {
  // Vision
  theme: ColorTheme;
  colourBlindMode: ColourBlindMode;
  readerFontSize: ReaderFontSize;
  fontFamily: FontFamily;
  boldText: boolean;
  lineSpacingMultiplier: number; // 1.0 - 2.0

  // Motion & interaction
  reduceMotion: boolean;
  hapticsEnabled: boolean;
  largeTouchTargets: boolean;

  // Audio
  screenReaderActive: boolean; // mirrors OS setting, updated on mount
  autoPlayAudio: boolean;

  // Actions
  setTheme: (theme: ColorTheme) => void;
  setColourBlindMode: (mode: ColourBlindMode) => void;
  setReaderFontSize: (size: ReaderFontSize) => void;
  setFontFamily: (family: FontFamily) => void;
  setBoldText: (bold: boolean) => void;
  setLineSpacing: (multiplier: number) => void;
  setReduceMotion: (reduce: boolean) => void;
  setHapticsEnabled: (enabled: boolean) => void;
  setLargeTouchTargets: (large: boolean) => void;
  setScreenReaderActive: (active: boolean) => void;
  setAutoPlayAudio: (auto: boolean) => void;
}

export const useAccessibilityStore = create<AccessibilityState>()(
  persist(
    (set) => ({
      theme: 'light',
      colourBlindMode: 'none',
      readerFontSize: 'default',
      fontFamily: 'serif',
      boldText: false,
      lineSpacingMultiplier: 1.5,
      reduceMotion: false,
      hapticsEnabled: true,
      largeTouchTargets: false,
      screenReaderActive: false,
      autoPlayAudio: false,

      setTheme: (theme) => set({ theme }),
      setColourBlindMode: (colourBlindMode) => set({ colourBlindMode }),
      setReaderFontSize: (readerFontSize) => set({ readerFontSize }),
      setFontFamily: (fontFamily) => set({ fontFamily }),
      setBoldText: (boldText) => set({ boldText }),
      setLineSpacing: (lineSpacingMultiplier) => set({ lineSpacingMultiplier }),
      setReduceMotion: (reduceMotion) => set({ reduceMotion }),
      setHapticsEnabled: (hapticsEnabled) => set({ hapticsEnabled }),
      setLargeTouchTargets: (largeTouchTargets) => set({ largeTouchTargets }),
      setScreenReaderActive: (screenReaderActive) => set({ screenReaderActive }),
      setAutoPlayAudio: (autoPlayAudio) => set({ autoPlayAudio }),
    }),
    {
      name: 'accessibility-settings',
      storage: createJSONStorage(() => mmkvStorage),
    }
  )
);
