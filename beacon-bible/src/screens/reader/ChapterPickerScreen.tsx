import React from 'react';
import {
  View, Text, StyleSheet, FlatList, TouchableOpacity, Platform,
} from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import type { NativeStackNavigationProp, RouteProp } from '@react-navigation/native-stack';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import { fontFamilies } from '@/constants/typography';
import { BOOK_NAMES, CHAPTER_COUNTS } from '@/constants/bible.constants';
import type { ReadStackParamList } from '@/types/navigation.types';

type Nav = NativeStackNavigationProp<ReadStackParamList, 'ChapterPicker'>;
type RouteP = RouteProp<ReadStackParamList, 'ChapterPicker'>;

const COLUMNS = 5;

export default function ChapterPickerScreen() {
  const nav = useNavigation<Nav>();
  const route = useRoute<RouteP>();
  const { bookCode } = route.params;
  const { theme } = useAccessibilitySettings();

  const totalChapters = CHAPTER_COUNTS[bookCode];
  const chapters = Array.from({ length: totalChapters }, (_, i) => i + 1);

  function openChapter(chapter: number) {
    nav.navigate('Reader', { bookCode, chapter });
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={[styles.header, { borderBottomColor: theme.border }]}>
        <TouchableOpacity onPress={() => nav.goBack()} style={styles.backBtn}
          accessibilityRole="button" accessibilityLabel="Go back">
          <Text style={[styles.backText, { color: theme.accent, fontFamily: fontFamilies.sans.medium }]}>‹ Back</Text>
        </TouchableOpacity>
        <Text style={[styles.title, { color: theme.textPrimary, fontFamily: fontFamilies.sans.semiBold }]}
          accessibilityRole="header">
          {BOOK_NAMES[bookCode]}
        </Text>
        <View style={{ width: 60 }} />
      </View>

      <Text style={[styles.subtitle, { color: theme.textTertiary, fontFamily: fontFamilies.sans.regular }]}>
        {totalChapters} {totalChapters === 1 ? 'chapter' : 'chapters'}
      </Text>

      <FlatList
        data={chapters}
        keyExtractor={item => String(item)}
        numColumns={COLUMNS}
        contentContainerStyle={styles.grid}
        columnWrapperStyle={styles.row}
        renderItem={({ item: chapter }) => (
          <TouchableOpacity
            style={[styles.chapterBtn, { backgroundColor: theme.surface, borderColor: theme.border }]}
            onPress={() => openChapter(chapter)}
            accessibilityRole="button"
            accessibilityLabel={`Chapter ${chapter}`}
          >
            <Text style={[styles.chapterNum, { color: theme.textPrimary, fontFamily: fontFamilies.sans.medium }]}>
              {chapter}
            </Text>
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingTop: Platform.OS === 'ios' ? 56 : 16, paddingBottom: 12,
    paddingHorizontal: 16, borderBottomWidth: StyleSheet.hairlineWidth,
  },
  backBtn: { width: 60 },
  backText: { fontSize: 16 },
  title: { fontSize: 17 },
  subtitle: {
    fontSize: 13, textAlign: 'center',
    paddingVertical: 12,
  },
  grid: { padding: 16, paddingBottom: 40 },
  row: { gap: 10, marginBottom: 10 },
  chapterBtn: {
    flex: 1, aspectRatio: 1, borderRadius: 12,
    borderWidth: StyleSheet.hairlineWidth,
    justifyContent: 'center', alignItems: 'center',
    minHeight: 52,
  },
  chapterNum: { fontSize: 16 },
});
