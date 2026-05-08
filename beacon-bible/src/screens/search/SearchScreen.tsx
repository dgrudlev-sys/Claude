import React, { useState, useCallback, useRef } from 'react';
import {
  View, Text, StyleSheet, TextInput, TouchableOpacity, FlatList,
  ActivityIndicator, Keyboard, Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import { useReaderStore } from '@/store/reader.store';
import { fontFamilies } from '@/constants/typography';
import { BOOK_NAMES } from '@/constants/bible.constants';
import { search, type AnySearchResult } from '@/lib/search/SearchOrchestrator';
import type { SearchStackParamList, ReadStackParamList } from '@/types/navigation.types';
import type { BookCode } from '@/constants/bible.constants';

type Nav = NativeStackNavigationProp<SearchStackParamList, 'Search'>;

const SUGGESTED_SEARCHES = [
  "peace that passes understanding",
  "love your enemies",
  "I can do all things",
  "do not be afraid",
  "anxiety",
  "forgiveness",
  "Psalm 23",
  "John 3:16",
];

export default function SearchScreen() {
  const nav = useNavigation<Nav>();
  const { theme, isDark } = useAccessibilitySettings();
  const { translationId } = useReaderStore();

  const [query, setQuery] = useState('');
  const [results, setResults] = useState<AnySearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);
  const inputRef = useRef<TextInput>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const runSearch = useCallback(async (q: string) => {
    if (!q.trim()) {
      setResults([]);
      setHasSearched(false);
      return;
    }
    setIsSearching(true);
    setHasSearched(true);
    try {
      const r = await search(q, translationId);
      setResults(r);
    } finally {
      setIsSearching(false);
    }
  }, [translationId]);

  function handleQueryChange(text: string) {
    setQuery(text);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => runSearch(text), 400);
  }

  function handleSubmit() {
    Keyboard.dismiss();
    runSearch(query);
  }

  function openVerse(bookCode: BookCode, chapter: number, verse?: number) {
    // Navigate to reader — use the parent stack
    const parentNav = nav.getParent();
    parentNav?.navigate('ReadTab', {
      screen: 'Reader',
      params: { bookCode, chapter, verse },
    });
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>

      {/* Search bar */}
      <View style={[styles.searchHeader, { backgroundColor: theme.background }]}>
        <View style={[styles.searchBar, { backgroundColor: theme.surfaceSecondary, borderColor: theme.border }]}>
          <Text style={styles.searchIcon}>🔍</Text>
          <TextInput
            ref={inputRef}
            style={[styles.searchInput, { color: theme.textPrimary, fontFamily: fontFamilies.sans.regular }]}
            placeholder="Search Scripture…"
            placeholderTextColor={theme.textTertiary}
            value={query}
            onChangeText={handleQueryChange}
            onSubmitEditing={handleSubmit}
            returnKeyType="search"
            autoCorrect={false}
            autoCapitalize="none"
            accessibilityLabel="Search the Bible"
            accessibilityHint="Type a phrase, topic, reference, or question"
          />
          {query.length > 0 && (
            <TouchableOpacity
              onPress={() => { setQuery(''); setResults([]); setHasSearched(false); }}
              accessibilityRole="button" accessibilityLabel="Clear search">
              <Text style={[styles.clearBtn, { color: theme.textTertiary }]}>✕</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>

      {/* Suggestions when empty */}
      {!hasSearched && (
        <View style={styles.suggestions}>
          <Text style={[styles.suggestionsLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
            TRY SEARCHING FOR
          </Text>
          <View style={styles.pillsWrap}>
            {SUGGESTED_SEARCHES.map(s => (
              <TouchableOpacity
                key={s}
                style={[styles.pill, { backgroundColor: theme.surfaceSecondary, borderColor: theme.border }]}
                onPress={() => { setQuery(s); runSearch(s); }}
                accessibilityRole="button"
                accessibilityLabel={`Search for ${s}`}
              >
                <Text style={[styles.pillText, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
                  {s}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>
      )}

      {/* Loading */}
      {isSearching && (
        <View style={styles.centre}>
          <ActivityIndicator color={theme.accent} />
        </View>
      )}

      {/* Results */}
      {!isSearching && hasSearched && (
        <FlatList
          data={results}
          keyExtractor={(_, i) => String(i)}
          contentContainerStyle={styles.resultsList}
          ListEmptyComponent={() => (
            <View style={styles.empty}>
              <Text style={[styles.emptyTitle, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}>
                No results found
              </Text>
              <Text style={[styles.emptyBody, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
                Try different words, or check the spelling of a verse reference like "John 3:16".
              </Text>
            </View>
          )}
          renderItem={({ item }) => {
            if (item.type === 'misquote') {
              return (
                <View style={[styles.misquoteCard, { backgroundColor: theme.accent + '14', borderColor: theme.accent + '44' }]}>
                  <Text style={[styles.misquoteTitle, { color: theme.accent, fontFamily: fontFamilies.sans.semiBold }]}>
                    Not in the Bible
                  </Text>
                  <Text style={[styles.misquoteExpl, { color: theme.textPrimary, fontFamily: fontFamilies.sans.regular }]}>
                    {item.misquoteData.explanation}
                  </Text>
                  {item.misquoteData.actualVerses.map(v => (
                    <TouchableOpacity
                      key={v.reference}
                      style={[styles.misquoteVerse, { borderColor: theme.border }]}
                      onPress={() => openVerse(v.bookCode as BookCode, v.chapter, v.verse)}
                      accessibilityRole="button"
                      accessibilityLabel={`${v.reference}: ${v.text}`}
                    >
                      <Text style={[styles.misquoteRef, { color: theme.accent, fontFamily: fontFamilies.sans.semiBold }]}>
                        {v.reference}
                      </Text>
                      <Text style={[styles.misquoteText, { color: theme.textPrimary, fontFamily: fontFamilies.serif.regular }]}>
                        {v.text}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              );
            }

            if (item.type === 'reference') {
              return (
                <TouchableOpacity
                  style={[styles.resultCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
                  onPress={() => openVerse(item.bookCode, item.chapter, item.verse)}
                  accessibilityRole="button"
                  accessibilityLabel={`Go to ${BOOK_NAMES[item.bookCode]} ${item.chapter}${item.verse ? ':' + item.verse : ''}`}
                >
                  <View style={[styles.refBadge, { backgroundColor: theme.accent }]}>
                    <Text style={[styles.refBadgeText, { fontFamily: fontFamilies.sans.bold }]}>→</Text>
                  </View>
                  <View style={styles.resultText}>
                    <Text style={[styles.resultRef, { color: theme.accent, fontFamily: fontFamilies.sans.semiBold }]}>
                      {BOOK_NAMES[item.bookCode]} {item.chapter}{item.verse ? `:${item.verse}` : ''}
                    </Text>
                    <Text style={[styles.resultSub, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
                      Tap to open
                    </Text>
                  </View>
                </TouchableOpacity>
              );
            }

            // Verse result
            if (item.type === 'verse') {
              return (
                <TouchableOpacity
                  style={[styles.resultCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
                  onPress={() => openVerse(item.bookCode, item.chapter, item.verse)}
                  accessibilityRole="button"
                  accessibilityLabel={`${BOOK_NAMES[item.bookCode]} ${item.chapter}:${item.verse} — ${item.text}`}
                >
                  <View style={styles.resultText}>
                    <Text style={[styles.resultRef, { color: theme.accent, fontFamily: fontFamilies.sans.semiBold }]}>
                      {BOOK_NAMES[item.bookCode]} {item.chapter}:{item.verse}
                    </Text>
                    {item.text && (
                      <Text style={[styles.resultVerse, { color: theme.textPrimary, fontFamily: fontFamilies.serif.regular }]}
                        numberOfLines={3}>
                        {item.text}
                      </Text>
                    )}
                  </View>
                </TouchableOpacity>
              );
            }
            return null;
          }}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  searchHeader: {
    paddingTop: Platform.OS === 'ios' ? 60 : 20,
    paddingHorizontal: 16, paddingBottom: 12,
  },
  searchBar: {
    flexDirection: 'row', alignItems: 'center', height: 48,
    borderRadius: 14, paddingHorizontal: 12, borderWidth: StyleSheet.hairlineWidth, gap: 8,
  },
  searchIcon: { fontSize: 16 },
  searchInput: { flex: 1, fontSize: 16, height: '100%' },
  clearBtn: { fontSize: 16, paddingHorizontal: 4 },
  suggestions: { padding: 24 },
  suggestionsLabel: { fontSize: 11, letterSpacing: 0.8, marginBottom: 12 },
  pillsWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  pill: {
    paddingHorizontal: 14, paddingVertical: 8,
    borderRadius: 20, borderWidth: StyleSheet.hairlineWidth,
  },
  pillText: { fontSize: 14 },
  centre: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  resultsList: { padding: 16, gap: 10 },
  resultCard: {
    flexDirection: 'row', borderRadius: 14, borderWidth: StyleSheet.hairlineWidth,
    padding: 14, gap: 12, alignItems: 'flex-start',
  },
  refBadge: {
    width: 32, height: 32, borderRadius: 8,
    justifyContent: 'center', alignItems: 'center',
  },
  refBadgeText: { color: '#FFF', fontSize: 16 },
  resultText: { flex: 1 },
  resultRef: { fontSize: 13, marginBottom: 4 },
  resultSub: { fontSize: 12 },
  resultVerse: { fontSize: 15, lineHeight: 22 },
  misquoteCard: { borderRadius: 14, borderWidth: 1, padding: 16, gap: 10 },
  misquoteTitle: { fontSize: 12, letterSpacing: 0.6, textTransform: 'uppercase' },
  misquoteExpl: { fontSize: 14, lineHeight: 22 },
  misquoteVerse: { borderTopWidth: StyleSheet.hairlineWidth, paddingTop: 10 },
  misquoteRef: { fontSize: 13, marginBottom: 4 },
  misquoteText: { fontSize: 15, lineHeight: 22 },
  empty: { padding: 24, alignItems: 'center' },
  emptyTitle: { fontSize: 20, marginBottom: 12, textAlign: 'center' },
  emptyBody: { fontSize: 15, lineHeight: 22, textAlign: 'center' },
});
