import React, { useState } from 'react';
import {
  View, Text, StyleSheet, FlatList, TouchableOpacity, ActivityIndicator,
} from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import type { NativeStackNavigationProp, RouteProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import { colors } from '@/constants/colors';
import { fontFamilies } from '@/constants/typography';
import { apiBibleService } from '@/lib/api/apiBible/apiBible.service';
import { usePreferencesStore } from '@/store/preferences.store';
import type { OnboardingStackParamList } from '@/types/navigation.types';

type Nav = NativeStackNavigationProp<OnboardingStackParamList, 'TranslationPicker'>;
type RouteP = RouteProp<OnboardingStackParamList, 'TranslationPicker'>;

// Recommended translations per language
const RECOMMENDED: Record<string, string[]> = {
  eng: ['de4e12af7f28f599-02', '06125adad2d5898a-01', '9879dbb7cfe39e4d-01'],
};

export default function TranslationPickerScreen() {
  const nav = useNavigation<Nav>();
  const route = useRoute<RouteP>();
  const { languageCode } = route.params;
  const setTranslation = usePreferencesStore(s => s.setTranslation);
  const [selected, setSelected] = useState<string | null>(null);
  const theme = colors.light;

  const { data: translations, isLoading } = useQuery({
    queryKey: ['translations', languageCode],
    queryFn: () => apiBibleService.listTranslations(languageCode),
    staleTime: 1000 * 60 * 60 * 24, // 24h cache
  });

  const recommended = RECOMMENDED[languageCode] ?? [];
  const sorted = translations ? [
    ...translations.filter(t => recommended.includes(t.id)),
    ...translations.filter(t => !recommended.includes(t.id)),
  ] : [];

  function handleSelect(id: string) {
    setSelected(id);
    setTranslation(id);
  }

  function handleContinue() {
    nav.navigate('OnboardingComplete');
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={styles.header}>
        <Text style={[styles.heading, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}
          accessibilityRole="header">
          Choose a translation
        </Text>
        <Text style={[styles.subheading, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
          You can switch translations any time while reading.
        </Text>
      </View>

      {isLoading ? (
        <ActivityIndicator style={{ flex: 1 }} color={theme.accent} />
      ) : (
        <FlatList
          data={sorted}
          keyExtractor={item => item.id}
          renderItem={({ item, index }) => {
            const isSelected = selected === item.id;
            const isRecommended = recommended.includes(item.id);
            return (
              <TouchableOpacity
                style={[styles.translationRow, {
                  backgroundColor: isSelected ? theme.accent + '18' : 'transparent',
                  borderColor: isSelected ? theme.accent : theme.border,
                }]}
                onPress={() => handleSelect(item.id)}
                accessibilityRole="radio"
                accessibilityState={{ selected: isSelected }}
                accessibilityLabel={`${item.name} — ${item.abbreviation}`}
              >
                <View style={[styles.abbrevBadge, { backgroundColor: theme.surfaceSecondary }]}>
                  <Text style={[styles.abbrev, { color: theme.accent, fontFamily: fontFamilies.sans.bold }]}>
                    {item.abbreviation}
                  </Text>
                </View>
                <View style={styles.translationText}>
                  <View style={styles.titleRow}>
                    <Text style={[styles.translationName, { color: theme.textPrimary, fontFamily: fontFamilies.sans.medium }]}>
                      {item.name}
                    </Text>
                    {isRecommended && (
                      <View style={[styles.recommendedBadge, { backgroundColor: theme.accent + '22' }]}>
                        <Text style={[styles.recommendedText, { color: theme.accent }]}>Recommended</Text>
                      </View>
                    )}
                  </View>
                  {item.copyright ? (
                    <Text style={[styles.copyright, { color: theme.textTertiary, fontFamily: fontFamilies.sans.regular }]}
                      numberOfLines={1}>
                      {item.copyright}
                    </Text>
                  ) : null}
                </View>
                {isSelected && <Text style={{ color: theme.accent, fontSize: 20 }}>✓</Text>}
              </TouchableOpacity>
            );
          }}
          contentContainerStyle={styles.list}
          ItemSeparatorComponent={() => <View style={{ height: StyleSheet.hairlineWidth, backgroundColor: theme.border }} />}
        />
      )}

      <View style={[styles.footer, { backgroundColor: theme.background, borderTopColor: theme.border }]}>
        <TouchableOpacity
          style={[styles.continueButton, { backgroundColor: theme.accent }]}
          onPress={handleContinue}
          accessibilityRole="button"
          accessibilityLabel={selected ? "Start reading" : "Skip, I'll choose later"}
        >
          <Text style={[styles.continueText, { fontFamily: fontFamilies.sans.semiBold }]}>
            {selected ? "Start reading" : "Skip for now"}
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
  subheading: { fontSize: 14, lineHeight: 20, marginBottom: 4, opacity: 0.8 },
  list: { paddingHorizontal: 24 },
  translationRow: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    paddingVertical: 14, paddingHorizontal: 8,
    borderRadius: 8, marginVertical: 1, borderWidth: StyleSheet.hairlineWidth,
  },
  abbrevBadge: {
    width: 52, height: 36, borderRadius: 8,
    justifyContent: 'center', alignItems: 'center',
  },
  abbrev: { fontSize: 13 },
  translationText: { flex: 1 },
  titleRow: { flexDirection: 'row', alignItems: 'center', gap: 8, flexWrap: 'wrap' },
  translationName: { fontSize: 15 },
  recommendedBadge: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 6 },
  recommendedText: { fontSize: 10, fontWeight: '600' },
  copyright: { fontSize: 11, marginTop: 2, opacity: 0.6 },
  footer: { paddingHorizontal: 24, paddingVertical: 16, borderTopWidth: StyleSheet.hairlineWidth },
  continueButton: { height: 56, borderRadius: 16, justifyContent: 'center', alignItems: 'center' },
  continueText: { fontSize: 17, color: '#FFFFFF' },
});
