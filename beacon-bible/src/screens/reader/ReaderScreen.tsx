import React, { useCallback, useRef, useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity, ActivityIndicator,
  StatusBar, AccessibilityInfo, Share, Platform,
} from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import type { NativeStackNavigationProp, RouteProp } from '@react-navigation/native-stack';
import * as Haptics from 'expo-haptics';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import { useBibleText } from '@/hooks/useBibleText';
import { useReaderStore } from '@/store/reader.store';
import { fontFamilies } from '@/constants/typography';
import { spacing } from '@/constants/spacing';
import { BOOK_NAMES, CHAPTER_COUNTS } from '@/constants/bible.constants';
import { upsertHighlight, removeHighlight, toggleBookmark } from '@/lib/db/queries/user.queries';
import { markTodayRead } from '@/lib/db/queries/user.queries';
import type { ReadStackParamList } from '@/types/navigation.types';
import type { BookCode } from '@/constants/bible.constants';

type Nav = NativeStackNavigationProp<ReadStackParamList, 'Reader'>;
type RouteP = RouteProp<ReadStackParamList, 'Reader'>;

const HIGHLIGHT_COLORS = [
  { color: '#FCD34D', label: 'Amber', accessible: 'Yellow highlight' },
  { color: '#93C5FD', label: 'Blue', accessible: 'Blue highlight' },
  { color: '#6EE7B7', label: 'Green', accessible: 'Green highlight' },
  { color: '#FCA5A5', label: 'Rose', accessible: 'Pink highlight' },
];

export default function ReaderScreen() {
  const nav = useNavigation<Nav>();
  const route = useRoute<RouteP>();
  const { bookCode, chapter } = route.params;

  const { theme, readerFont, readerFontSize, lineHeight, fontWeight,
    hapticsEnabled, isDark } = useAccessibilitySettings();
  const { translationId, showVerseNumbers, setPosition } = useReaderStore();

  const { data: verses, isLoading, error } = useBibleText(translationId, bookCode, chapter);

  const [selectedVerseId, setSelectedVerseId] = useState<number | null>(null);
  const [highlightedVerses, setHighlightedVerses] = useState<Record<number, string>>({});

  const scrollRef = useRef<ScrollView>(null);

  const bookName = BOOK_NAMES[bookCode];
  const totalChapters = CHAPTER_COUNTS[bookCode];
  const hasPrev = chapter > 1;
  const hasNext = chapter < totalChapters;

  // Mark reading session when chapter loads
  React.useEffect(() => {
    if (verses && verses.length > 0) {
      markTodayRead(1);
    }
  }, [verses?.length]);

  function handleVersePress(verseId: number, verseNumber: number) {
    if (hapticsEnabled) Haptics.selectionAsync();
    setSelectedVerseId(prev => prev === verseId ? null : verseId);
    AccessibilityInfo.announceForAccessibility(`Verse ${verseNumber} selected`);
  }

  async function handleHighlight(verseId: number, color: string) {
    if (hapticsEnabled) Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    if (highlightedVerses[verseId] === color) {
      await removeHighlight(verseId);
      setHighlightedVerses(prev => { const n = { ...prev }; delete n[verseId]; return n; });
    } else {
      await upsertHighlight(verseId, color);
      setHighlightedVerses(prev => ({ ...prev, [verseId]: color }));
    }
    setSelectedVerseId(null);
  }

  async function handleBookmark(verseId: number) {
    if (hapticsEnabled) Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    await toggleBookmark(verseId);
    setSelectedVerseId(null);
  }

  async function handleShare(text: string, verseRef: string) {
    try {
      await Share.share({ message: `"${text}" — ${verseRef}\n\nShared from Beacon Bible` });
    } catch {}
  }

  function navigate(dir: 'prev' | 'next') {
    const newChapter = dir === 'prev' ? chapter - 1 : chapter + 1;
    setPosition(bookCode, newChapter);
    nav.replace('Reader', { bookCode, chapter: newChapter });
    scrollRef.current?.scrollTo({ y: 0, animated: false });
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.readerBackground }]}>
      <StatusBar barStyle={isDark ? 'light-content' : 'dark-content'} />

      {/* Top navigation bar */}
      <View style={[styles.navbar, { borderBottomColor: theme.border, backgroundColor: theme.readerBackground }]}>
        <TouchableOpacity
          style={styles.navBtn}
          onPress={() => nav.goBack()}
          accessibilityRole="button"
          accessibilityLabel="Go back"
        >
          <Text style={[styles.navBtnText, { color: theme.accent }]}>‹</Text>
        </TouchableOpacity>

        <TouchableOpacity
          onPress={() => nav.navigate('BookPicker')}
          accessibilityRole="button"
          accessibilityLabel={`${bookName}, chapter ${chapter}. Tap to change book`}
        >
          <Text style={[styles.navTitle, { color: theme.chapterHeader, fontFamily: fontFamilies.sans.semiBold }]}>
            {bookName} {chapter}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.navBtn}
          accessibilityRole="button"
          accessibilityLabel="Reader settings"
        >
          <Text style={[styles.navBtnText, { color: theme.accent }]}>Aa</Text>
        </TouchableOpacity>
      </View>

      {/* Loading / error states */}
      {isLoading && (
        <View style={styles.centre}>
          <ActivityIndicator size="large" color={theme.accent} />
          <Text style={[styles.loadingText, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
            Loading {bookName} {chapter}…
          </Text>
        </View>
      )}

      {error && (
        <View style={styles.centre}>
          <Text style={[styles.errorText, { color: theme.error ?? '#EF4444', fontFamily: fontFamilies.sans.regular }]}>
            Couldn't load this chapter. Check your connection and try again.
          </Text>
        </View>
      )}

      {/* Verse list */}
      {!isLoading && verses && (
        <ScrollView
          ref={scrollRef}
          contentContainerStyle={[styles.verseList, { paddingHorizontal: 24 }]}
          showsVerticalScrollIndicator={false}
        >
          <Text style={[styles.chapterHeading, {
            color: theme.chapterHeader,
            fontFamily: fontFamilies.serif.bold,
          }]}
            accessibilityRole="header">
            {chapter}
          </Text>

          {verses.map((v) => {
            const isSelected = selectedVerseId === v.id;
            const highlight = highlightedVerses[v.id];

            return (
              <TouchableOpacity
                key={v.id}
                onPress={() => handleVersePress(v.id, v.verseNumber)}
                style={[
                  styles.verseRow,
                  highlight ? { backgroundColor: highlight + '44' } : null,
                  isSelected ? [styles.verseSelected, { borderColor: theme.accent }] : null,
                ]}
                accessibilityRole="text"
                accessibilityLabel={`Verse ${v.verseNumber}: ${v.textPlain}`}
                accessibilityHint="Double tap to highlight, bookmark, or share"
              >
                {showVerseNumbers && (
                  <Text style={[styles.verseNum, { color: theme.verseNumber, fontFamily: fontFamilies.sans.regular }]}>
                    {v.verseNumber}
                  </Text>
                )}
                <Text style={[styles.verseText, {
                  color: theme.verseText,
                  fontFamily: fontWeight === '700' ? readerFont.bold : readerFont.regular,
                  fontSize: readerFontSize,
                  lineHeight,
                }]}>
                  {v.textPlain}
                </Text>
              </TouchableOpacity>
            );
          })}

          {/* Chapter navigation */}
          <View style={styles.chapterNav}>
            <TouchableOpacity
              style={[styles.chapterNavBtn, !hasPrev && styles.chapterNavDisabled,
                { borderColor: theme.border }]}
              onPress={() => hasPrev && navigate('prev')}
              disabled={!hasPrev}
              accessibilityRole="button"
              accessibilityLabel={hasPrev ? `Previous chapter, ${bookName} ${chapter - 1}` : 'First chapter'}
            >
              <Text style={[styles.chapterNavText, { color: hasPrev ? theme.accent : theme.textTertiary,
                fontFamily: fontFamilies.sans.medium }]}>
                ‹ {hasPrev ? `${bookName} ${chapter - 1}` : 'Beginning'}
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.chapterNavBtn, !hasNext && styles.chapterNavDisabled,
                { borderColor: theme.border }]}
              onPress={() => hasNext && navigate('next')}
              disabled={!hasNext}
              accessibilityRole="button"
              accessibilityLabel={hasNext ? `Next chapter, ${bookName} ${chapter + 1}` : 'Last chapter'}
            >
              <Text style={[styles.chapterNavText, { color: hasNext ? theme.accent : theme.textTertiary,
                fontFamily: fontFamilies.sans.medium }]}>
                {hasNext ? `${bookName} ${chapter + 1}` : 'End'} ›
              </Text>
            </TouchableOpacity>
          </View>

          <View style={{ height: 64 }} />
        </ScrollView>
      )}

      {/* Verse action bar */}
      {selectedVerseId !== null && verses && (
        <View style={[styles.actionBar, { backgroundColor: theme.surface, borderTopColor: theme.border }]}>
          <View style={styles.colorPicker}>
            {HIGHLIGHT_COLORS.map(({ color, accessible }) => (
              <TouchableOpacity
                key={color}
                style={[styles.colorSwatch, { backgroundColor: color }]}
                onPress={() => handleHighlight(selectedVerseId, color)}
                accessibilityRole="button"
                accessibilityLabel={accessible}
              />
            ))}
          </View>
          <TouchableOpacity
            style={styles.actionBtn}
            onPress={() => handleBookmark(selectedVerseId)}
            accessibilityRole="button"
            accessibilityLabel="Bookmark this verse"
          >
            <Text style={{ fontSize: 22 }}>🔖</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.actionBtn}
            onPress={() => {
              const v = verses.find(v => v.id === selectedVerseId);
              if (v) handleShare(v.textPlain, `${bookName} ${chapter}:${v.verseNumber}`);
            }}
            accessibilityRole="button"
            accessibilityLabel="Share this verse"
          >
            <Text style={{ fontSize: 22 }}>↗</Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  navbar: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingTop: Platform.OS === 'ios' ? 56 : 16, paddingBottom: 12,
    paddingHorizontal: 16, borderBottomWidth: StyleSheet.hairlineWidth,
  },
  navBtn: { minWidth: 44, minHeight: 44, justifyContent: 'center', alignItems: 'center' },
  navBtnText: { fontSize: 22, fontWeight: '600' },
  navTitle: { fontSize: 17 },
  centre: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 32 },
  loadingText: { marginTop: 12, fontSize: 14, textAlign: 'center' },
  errorText: { fontSize: 15, textAlign: 'center', lineHeight: 22 },
  verseList: { paddingTop: 24, paddingBottom: 16 },
  chapterHeading: { fontSize: 56, textAlign: 'center', marginBottom: 24, opacity: 0.15 },
  verseRow: {
    flexDirection: 'row', paddingVertical: 4, paddingHorizontal: 8,
    borderRadius: 8, marginBottom: 2, gap: 8,
  },
  verseSelected: { borderWidth: 1.5, borderRadius: 10 },
  verseNum: { fontSize: 11, marginTop: 4, minWidth: 22, textAlign: 'right' },
  verseText: { flex: 1 },
  chapterNav: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 32, gap: 12 },
  chapterNavBtn: {
    flex: 1, height: 44, borderRadius: 12, borderWidth: StyleSheet.hairlineWidth,
    justifyContent: 'center', alignItems: 'center',
  },
  chapterNavDisabled: { opacity: 0.4 },
  chapterNavText: { fontSize: 14 },
  actionBar: {
    flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16,
    paddingVertical: 12, borderTopWidth: StyleSheet.hairlineWidth, gap: 8,
  },
  colorPicker: { flex: 1, flexDirection: 'row', gap: 10 },
  colorSwatch: { width: 32, height: 32, borderRadius: 16 },
  actionBtn: { width: 44, height: 44, justifyContent: 'center', alignItems: 'center' },
});
