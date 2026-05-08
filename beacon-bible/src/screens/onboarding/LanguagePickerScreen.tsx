import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, FlatList, TouchableOpacity,
  TextInput, ActivityIndicator,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import { colors } from '@/constants/colors';
import { fontFamilies } from '@/constants/typography';
import { apiBibleService } from '@/lib/api/apiBible/apiBible.service';
import { usePreferencesStore } from '@/store/preferences.store';
import type { OnboardingStackParamList } from '@/types/navigation.types';

type Nav = NativeStackNavigationProp<OnboardingStackParamList, 'LanguagePicker'>;

interface LanguageItem {
  code: string;
  name: string;
  nameLocal: string;
  bibleCount: number;
}

// Featured languages shown at the top
const FEATURED_LANGUAGES = [
  { code: 'eng', name: 'English', nameLocal: 'English' },
  { code: 'spa', name: 'Spanish', nameLocal: 'Español' },
  { code: 'por', name: 'Portuguese', nameLocal: 'Português' },
  { code: 'fra', name: 'French', nameLocal: 'Français' },
  { code: 'deu', name: 'German', nameLocal: 'Deutsch' },
  { code: 'zho', name: 'Chinese (Simplified)', nameLocal: '中文' },
  { code: 'ara', name: 'Arabic', nameLocal: 'العربية' },
  { code: 'hin', name: 'Hindi', nameLocal: 'हिन्दी' },
  { code: 'rus', name: 'Russian', nameLocal: 'Русский' },
  { code: 'kor', name: 'Korean', nameLocal: '한국어' },
];

export default function LanguagePickerScreen() {
  const nav = useNavigation<Nav>();
  const setLanguage = usePreferencesStore(s => s.setLanguage);
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState('eng');
  const theme = colors.light;

  const filtered = FEATURED_LANGUAGES.filter(l =>
    l.name.toLowerCase().includes(search.toLowerCase()) ||
    l.nameLocal.toLowerCase().includes(search.toLowerCase())
  );

  function handleSelect(code: string) {
    setSelected(code);
    setLanguage(code);
  }

  function handleContinue() {
    nav.navigate('TranslationPicker', { languageCode: selected });
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={styles.header}>
        <Text style={[styles.heading, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}
          accessibilityRole="header">
          Choose your language
        </Text>
        <Text style={[styles.subheading, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
          2,600+ languages available. Start with your preferred reading language.
        </Text>
        <TextInput
          style={[styles.searchInput, {
            backgroundColor: theme.surfaceSecondary,
            color: theme.textPrimary,
            borderColor: theme.border,
            fontFamily: fontFamilies.sans.regular,
          }]}
          placeholder="Search languages..."
          placeholderTextColor={theme.textTertiary}
          value={search}
          onChangeText={setSearch}
          accessibilityLabel="Search languages"
          autoCorrect={false}
          autoCapitalize="none"
        />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={item => item.code}
        renderItem={({ item }) => {
          const isSelected = selected === item.code;
          return (
            <TouchableOpacity
              style={[styles.languageRow, {
                backgroundColor: isSelected ? theme.accent + '18' : 'transparent',
                borderColor: isSelected ? theme.accent : theme.border,
              }]}
              onPress={() => handleSelect(item.code)}
              accessibilityRole="radio"
              accessibilityState={{ selected: isSelected }}
              accessibilityLabel={`${item.name} — ${item.nameLocal}`}
            >
              <View style={styles.languageText}>
                <Text style={[styles.languageName, { color: theme.textPrimary, fontFamily: fontFamilies.sans.medium }]}>
                  {item.name}
                </Text>
                <Text style={[styles.languageLocal, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
                  {item.nameLocal}
                </Text>
              </View>
              {isSelected && (
                <Text style={{ color: theme.accent, fontSize: 20 }}>✓</Text>
              )}
            </TouchableOpacity>
          );
        }}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: StyleSheet.hairlineWidth, backgroundColor: theme.border }} />}
      />

      <View style={[styles.footer, { backgroundColor: theme.background, borderTopColor: theme.border }]}>
        <TouchableOpacity
          style={[styles.continueButton, { backgroundColor: theme.accent }]}
          onPress={handleContinue}
          accessibilityRole="button"
          accessibilityLabel="Continue with selected language"
        >
          <Text style={[styles.continueText, { fontFamily: fontFamilies.sans.semiBold }]}>
            Continue
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { paddingHorizontal: 24, paddingTop: 64, paddingBottom: 16 },
  heading: { fontSize: 28, lineHeight: 36, marginBottom: 8 },
  subheading: { fontSize: 14, lineHeight: 20, marginBottom: 16, opacity: 0.8 },
  searchInput: {
    height: 48, borderRadius: 12, paddingHorizontal: 16,
    fontSize: 15, borderWidth: StyleSheet.hairlineWidth,
  },
  list: { paddingHorizontal: 24 },
  languageRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingVertical: 16, paddingHorizontal: 12, borderRadius: 8, marginVertical: 1,
    borderWidth: StyleSheet.hairlineWidth,
  },
  languageText: {},
  languageName: { fontSize: 16, marginBottom: 2 },
  languageLocal: { fontSize: 13, opacity: 0.7 },
  footer: {
    paddingHorizontal: 24, paddingVertical: 16,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  continueButton: {
    height: 56, borderRadius: 16,
    justifyContent: 'center', alignItems: 'center',
  },
  continueText: { fontSize: 17, color: '#FFFFFF' },
});
