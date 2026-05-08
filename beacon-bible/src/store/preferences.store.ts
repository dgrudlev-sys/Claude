import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import { MMKV } from 'react-native-mmkv';

const storage = new MMKV({ id: 'preferences' });
const mmkvStorage = {
  getItem: (key: string) => storage.getString(key) ?? null,
  setItem: (key: string, value: string) => storage.set(key, value),
  removeItem: (key: string) => storage.delete(key),
};

export type OnboardingIntent =
  | 'going_through_something'
  | 'build_habit'
  | 'study_deeper'
  | 'exploring_faith'
  | 'church_group'
  | null;

interface PreferencesState {
  hasCompletedOnboarding: boolean;
  onboardingIntent: OnboardingIntent;
  preferredLanguageCode: string;
  preferredTranslationId: string;
  notificationsEnabled: boolean;
  dailyReminderTime: string; // "08:00"
  streakCount: number;
  totalDaysRead: number;
  lastReadDate: string | null; // ISO "YYYY-MM-DD"
  donationPromptShownAt: number | null;

  setOnboardingComplete: (intent: OnboardingIntent) => void;
  setLanguage: (code: string) => void;
  setTranslation: (id: string) => void;
  setNotifications: (enabled: boolean, time?: string) => void;
  incrementStreak: () => void;
  resetStreak: () => void;
  markDayRead: (date: string) => void;
  setDonationPromptShown: () => void;
}

export const usePreferencesStore = create<PreferencesState>()(
  persist(
    (set, get) => ({
      hasCompletedOnboarding: false,
      onboardingIntent: null,
      preferredLanguageCode: 'en',
      preferredTranslationId: 'de4e12af7f28f599-02',
      notificationsEnabled: false,
      dailyReminderTime: '08:00',
      streakCount: 0,
      totalDaysRead: 0,
      lastReadDate: null,
      donationPromptShownAt: null,

      setOnboardingComplete: (intent) =>
        set({ hasCompletedOnboarding: true, onboardingIntent: intent }),

      setLanguage: (preferredLanguageCode) => set({ preferredLanguageCode }),
      setTranslation: (preferredTranslationId) => set({ preferredTranslationId }),

      setNotifications: (enabled, time) =>
        set({
          notificationsEnabled: enabled,
          ...(time ? { dailyReminderTime: time } : {}),
        }),

      incrementStreak: () =>
        set((s) => ({ streakCount: s.streakCount + 1 })),

      resetStreak: () => set({ streakCount: 0 }),

      markDayRead: (date) => {
        const { lastReadDate, streakCount, totalDaysRead } = get();
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayStr = yesterday.toISOString().split('T')[0];

        const isConsecutive = lastReadDate === yesterdayStr;
        set({
          lastReadDate: date,
          totalDaysRead: totalDaysRead + 1,
          streakCount: isConsecutive ? streakCount + 1 : 1,
        });
      },

      setDonationPromptShown: () =>
        set({ donationPromptShownAt: Date.now() }),
    }),
    {
      name: 'user-preferences',
      storage: createJSONStorage(() => mmkvStorage),
    }
  )
);
