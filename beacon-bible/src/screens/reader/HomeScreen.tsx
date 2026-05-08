import React from 'react';
import {
  View, Text, StyleSheet, TouchableOpacity, ScrollView, StatusBar,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import { useReaderStore } from '@/store/reader.store';
import { usePreferencesStore } from '@/store/preferences.store';
import { fontFamilies } from '@/constants/typography';
import { BOOK_NAMES } from '@/constants/bible.constants';
import type { ReadStackParamList } from '@/types/navigation.types';

type Nav = NativeStackNavigationProp<ReadStackParamList, 'Home'>;

const QUICK_START_PASSAGES = [
  { label: 'Psalm 23', bookCode: 'PSA' as const, chapter: 23, description: 'The Lord is my shepherd' },
  { label: 'John 3', bookCode: 'JHN' as const, chapter: 3, description: 'For God so loved the world' },
  { label: 'Romans 8', bookCode: 'ROM' as const, chapter: 8, description: 'More than conquerors' },
  { label: 'Isaiah 40', bookCode: 'ISA' as const, chapter: 40, description: 'Those who hope in the Lord' },
  { label: 'Matthew 5', bookCode: 'MAT' as const, chapter: 5, description: 'The Sermon on the Mount' },
  { label: 'Philippians 4', bookCode: 'PHP' as const, chapter: 4, description: 'I can do all things' },
];

export default function HomeScreen() {
  const nav = useNavigation<Nav>();
  const { theme, readerFont, readerFontSize } = useAccessibilitySettings();
  const { bookCode, chapter, translationId } = useReaderStore();
  const { streakCount, totalDaysRead } = usePreferencesStore();

  const greeting = getGreeting();

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <StatusBar barStyle={theme.background === '#FDFAF5' ? 'dark-content' : 'light-content'} />
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>

        {/* Header */}
        <View style={styles.header}>
          <Text style={[styles.greeting, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
            {greeting}
          </Text>
          <Text style={[styles.appTitle, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}
            accessibilityRole="header">
            Beacon Bible
          </Text>
        </View>

        {/* Streak card */}
        {streakCount > 0 && (
          <View style={[styles.streakCard, { backgroundColor: theme.accent + '18', borderColor: theme.accent + '40' }]}
            accessibilityLabel={`${streakCount} day reading streak`}>
            <Text style={[styles.streakNumber, { color: theme.accent, fontFamily: fontFamilies.serif.bold }]}>
              {streakCount}
            </Text>
            <View>
              <Text style={[styles.streakLabel, { color: theme.textPrimary, fontFamily: fontFamilies.sans.semiBold }]}>
                Day streak
              </Text>
              <Text style={[styles.streakSub, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
                {totalDaysRead} total days in Scripture
              </Text>
            </View>
            <Text style={{ fontSize: 28 }}>✦</Text>
          </View>
        )}

        {/* Continue reading */}
        <SectionHeader label="Continue reading" theme={theme} />
        <TouchableOpacity
          style={[styles.continueCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
          onPress={() => nav.navigate('Reader', { bookCode, chapter })}
          accessibilityRole="button"
          accessibilityLabel={`Continue reading ${BOOK_NAMES[bookCode]} chapter ${chapter}`}
        >
          <View style={[styles.continueIcon, { backgroundColor: theme.accent }]}>
            <Text style={{ color: '#FFF', fontSize: 20 }}>📖</Text>
          </View>
          <View style={styles.continueText}>
            <Text style={[styles.continueBook, { color: theme.textPrimary, fontFamily: fontFamilies.sans.semiBold }]}>
              {BOOK_NAMES[bookCode]} {chapter}
            </Text>
            <Text style={[styles.continueSub, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
              Pick up where you left off
            </Text>
          </View>
          <Text style={{ color: theme.textTertiary, fontSize: 18 }}>›</Text>
        </TouchableOpacity>

        {/* Quick access passages */}
        <SectionHeader label="Classic passages" theme={theme} />
        <View style={styles.passagesGrid}>
          {QUICK_START_PASSAGES.map((p) => (
            <TouchableOpacity
              key={p.label}
              style={[styles.passageCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
              onPress={() => nav.navigate('Reader', { bookCode: p.bookCode, chapter: p.chapter })}
              accessibilityRole="button"
              accessibilityLabel={`${p.label}: ${p.description}`}
            >
              <Text style={[styles.passageLabel, { color: theme.accent, fontFamily: fontFamilies.sans.semiBold }]}>
                {p.label}
              </Text>
              <Text style={[styles.passageDesc, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}
                numberOfLines={2}>
                {p.description}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Browse all */}
        <TouchableOpacity
          style={[styles.browseButton, { borderColor: theme.accent }]}
          onPress={() => nav.navigate('BookPicker')}
          accessibilityRole="button"
          accessibilityLabel="Browse all books of the Bible"
        >
          <Text style={[styles.browseText, { color: theme.accent, fontFamily: fontFamilies.sans.semiBold }]}>
            Browse all books
          </Text>
        </TouchableOpacity>

        <View style={{ height: 32 }} />
      </ScrollView>
    </View>
  );
}

function SectionHeader({ label, theme }: { label: string; theme: any }) {
  return (
    <Text style={[{
      fontSize: 11, fontFamily: fontFamilies.sans.semiBold,
      color: theme.textTertiary, letterSpacing: 1,
      textTransform: 'uppercase', marginTop: 24, marginBottom: 12,
      paddingHorizontal: 24,
    }]}>
      {label}
    </Text>
  );
}

function getGreeting(): string {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  scroll: { paddingTop: 64 },
  header: { paddingHorizontal: 24, marginBottom: 8 },
  greeting: { fontSize: 14, marginBottom: 2 },
  appTitle: { fontSize: 30, letterSpacing: -0.5 },
  streakCard: {
    marginHorizontal: 24, marginTop: 20, borderRadius: 16, borderWidth: 1,
    padding: 16, flexDirection: 'row', alignItems: 'center', gap: 16,
  },
  streakNumber: { fontSize: 40, lineHeight: 44 },
  streakLabel: { fontSize: 16, marginBottom: 2 },
  streakSub: { fontSize: 12 },
  continueCard: {
    marginHorizontal: 24, borderRadius: 16, borderWidth: StyleSheet.hairlineWidth,
    padding: 16, flexDirection: 'row', alignItems: 'center', gap: 14,
  },
  continueIcon: { width: 44, height: 44, borderRadius: 12, justifyContent: 'center', alignItems: 'center' },
  continueText: { flex: 1 },
  continueBook: { fontSize: 16, marginBottom: 2 },
  continueSub: { fontSize: 13 },
  passagesGrid: {
    paddingHorizontal: 24, flexDirection: 'row', flexWrap: 'wrap', gap: 12,
  },
  passageCard: {
    width: '47%', borderRadius: 14, borderWidth: StyleSheet.hairlineWidth,
    padding: 14,
  },
  passageLabel: { fontSize: 15, marginBottom: 4 },
  passageDesc: { fontSize: 12, lineHeight: 16 },
  browseButton: {
    marginHorizontal: 24, marginTop: 20, height: 48, borderRadius: 14,
    borderWidth: 1.5, justifyContent: 'center', alignItems: 'center',
  },
  browseText: { fontSize: 15 },
});
