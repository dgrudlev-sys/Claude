import type { BookCode } from '@/constants/bible.constants';

export type RootStackParamList = {
  Onboarding: undefined;
  Main: undefined;
};

export type OnboardingStackParamList = {
  Welcome: undefined;
  Intent: undefined;
  AccessibilitySetup: undefined;
  LanguagePicker: undefined;
  TranslationPicker: { languageCode: string };
  OnboardingComplete: undefined;
};

export type MainTabParamList = {
  ReadTab: undefined;
  SearchTab: undefined;
  PlansTab: undefined;
  ProfileTab: undefined;
};

export type ReadStackParamList = {
  Home: undefined;
  BookPicker: undefined;
  ChapterPicker: { bookCode: BookCode };
  Reader: { bookCode: BookCode; chapter: number; verse?: number };
};

export type SearchStackParamList = {
  Search: { initialQuery?: string };
  TopicBrowser: undefined;
  SearchResults: { query: string };
  EntityDetail: { entityId: number; name: string };
  CrossReference: { bookCode: BookCode; chapter: number; verse: number };
};

export type PlansStackParamList = {
  PlansHome: undefined;
  PlanDetail: { planId: number };
  PlanDay: { planId: number; dayNumber: number };
  CreatePlan: undefined;
};

export type ProfileStackParamList = {
  Profile: undefined;
  Highlights: undefined;
  Bookmarks: undefined;
  Notes: undefined;
  Downloads: undefined;
  Settings: undefined;
  AccessibilitySettings: undefined;
  AppearanceSettings: undefined;
  NotificationSettings: undefined;
  DonationPrompt: undefined;
  DonationOptions: undefined;
  DonationConfirm: undefined;
};
