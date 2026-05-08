import React, { useState } from 'react';
import {
  View, Text, StyleSheet, SectionList, TouchableOpacity,
  TextInput, Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import { fontFamilies } from '@/constants/typography';
import {
  BOOK_NAMES, BOOK_SHORT_NAMES,
  OLD_TESTAMENT_BOOKS, NEW_TESTAMENT_BOOKS, type BookCode,
} from '@/constants/bible.constants';
import type { ReadStackParamList } from '@/types/navigation.types';

type Nav = NativeStackNavigationProp<ReadStackParamList, 'BookPicker'>;

export default function BookPickerScreen() {
  const nav = useNavigation<Nav>();
  const { theme } = useAccessibilitySettings();
  const [search, setSearch] = useState('');

  const filter = (books: readonly BookCode[]) =>
    books.filter(b =>
      search === '' ||
      BOOK_NAMES[b].toLowerCase().includes(search.toLowerCase()) ||
      BOOK_SHORT_NAMES[b].toLowerCase().includes(search.toLowerCase())
    );

  const sections = [
    { title: 'Old Testament', data: filter(OLD_TESTAMENT_BOOKS) },
    { title: 'New Testament', data: filter(NEW_TESTAMENT_BOOKS) },
  ].filter(s => s.data.length > 0);

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={[styles.header, { borderBottomColor: theme.border }]}>
        <TouchableOpacity onPress={() => nav.goBack()} style={styles.backBtn}
          accessibilityRole="button" accessibilityLabel="Go back">
          <Text style={[styles.backText, { color: theme.accent, fontFamily: fontFamilies.sans.medium }]}>‹ Back</Text>
        </TouchableOpacity>
        <Text style={[styles.title, { color: theme.textPrimary, fontFamily: fontFamilies.sans.semiBold }]}
          accessibilityRole="header">
          Choose a book
        </Text>
        <View style={{ width: 60 }} />
      </View>

      <TextInput
        style={[styles.search, {
          backgroundColor: theme.surfaceSecondary, borderColor: theme.border,
          color: theme.textPrimary, fontFamily: fontFamilies.sans.regular,
        }]}
        placeholder="Search books…"
        placeholderTextColor={theme.textTertiary}
        value={search}
        onChangeText={setSearch}
        accessibilityLabel="Search Bible books"
        autoCorrect={false}
      />

      <SectionList
        sections={sections}
        keyExtractor={item => item}
        renderSectionHeader={({ section }) => (
          <Text style={[styles.sectionHeader, {
            color: theme.textTertiary, backgroundColor: theme.background,
            fontFamily: fontFamilies.sans.semiBold,
          }]}>
            {section.title}
          </Text>
        )}
        renderItem={({ item: bookCode }) => (
          <TouchableOpacity
            style={[styles.bookRow, { borderBottomColor: theme.border }]}
            onPress={() => nav.navigate('ChapterPicker', { bookCode })}
            accessibilityRole="button"
            accessibilityLabel={BOOK_NAMES[bookCode]}
          >
            <Text style={[styles.bookShort, { color: theme.accent, fontFamily: fontFamilies.sans.medium }]}>
              {BOOK_SHORT_NAMES[bookCode]}
            </Text>
            <Text style={[styles.bookName, { color: theme.textPrimary, fontFamily: fontFamilies.sans.regular }]}>
              {BOOK_NAMES[bookCode]}
            </Text>
            <Text style={[styles.chevron, { color: theme.textTertiary }]}>›</Text>
          </TouchableOpacity>
        )}
        contentContainerStyle={{ paddingBottom: 40 }}
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
  search: {
    margin: 16, height: 44, borderRadius: 12, paddingHorizontal: 14,
    fontSize: 15, borderWidth: StyleSheet.hairlineWidth,
  },
  sectionHeader: {
    fontSize: 11, letterSpacing: 0.8, paddingHorizontal: 16,
    paddingVertical: 8, textTransform: 'uppercase',
  },
  bookRow: {
    flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16,
    paddingVertical: 14, borderBottomWidth: StyleSheet.hairlineWidth, gap: 12,
    minHeight: 52,
  },
  bookShort: { width: 40, fontSize: 13 },
  bookName: { flex: 1, fontSize: 16 },
  chevron: { fontSize: 18 },
});
