import React, { useState } from 'react';
import {
  View, Text, StyleSheet, TouchableOpacity, ScrollView, AccessibilityInfo,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { colors } from '@/constants/colors';
import { fontFamilies } from '@/constants/typography';
import { usePreferencesStore, type OnboardingIntent } from '@/store/preferences.store';
import type { OnboardingStackParamList } from '@/types/navigation.types';

type Nav = NativeStackNavigationProp<OnboardingStackParamList, 'Intent'>;

interface IntentOption {
  id: OnboardingIntent;
  emoji: string;
  title: string;
  subtitle: string;
}

const INTENT_OPTIONS: IntentOption[] = [
  {
    id: 'going_through_something',
    emoji: '🕊',
    title: "I'm going through something hard",
    subtitle: "Find comfort, peace, and hope in Scripture",
  },
  {
    id: 'build_habit',
    emoji: '📅',
    title: "I want to build a daily habit",
    subtitle: "Reading plans, streaks, and gentle reminders",
  },
  {
    id: 'study_deeper',
    emoji: '📚',
    title: "I want to study and understand more",
    subtitle: "Commentaries, original languages, and deep search",
  },
  {
    id: 'exploring_faith',
    emoji: '🌱',
    title: "I'm exploring faith for the first time",
    subtitle: "No jargon, just Scripture and good context",
  },
  {
    id: 'church_group',
    emoji: '🏛',
    title: "I'm here with my church or group",
    subtitle: "Shared plans and reading with friends",
  },
];

export default function IntentScreen() {
  const nav = useNavigation<Nav>();
  const setOnboardingComplete = usePreferencesStore(s => s.setOnboardingComplete);
  const [selected, setSelected] = useState<OnboardingIntent>(null);
  const theme = colors.light;

  function handleSelect(id: OnboardingIntent) {
    setSelected(id);
    AccessibilityInfo.announceForAccessibility(`Selected: ${INTENT_OPTIONS.find(o => o.id === id)?.title}`);
  }

  function handleContinue() {
    nav.navigate('AccessibilitySetup');
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>

        <Text
          style={[styles.heading, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}
          accessibilityRole="header"
        >
          What's on your mind today?
        </Text>
        <Text style={[styles.subheading, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
          We'll set up the experience that fits you best. You can change this any time.
        </Text>

        <View style={styles.options}>
          {INTENT_OPTIONS.map((option) => {
            const isSelected = selected === option.id;
            return (
              <TouchableOpacity
                key={option.id}
                style={[
                  styles.optionCard,
                  {
                    backgroundColor: isSelected ? theme.accentLight + '22' : theme.surface,
                    borderColor: isSelected ? theme.accent : theme.border,
                    borderWidth: isSelected ? 2 : StyleSheet.hairlineWidth,
                  },
                ]}
                onPress={() => handleSelect(option.id)}
                accessibilityRole="radio"
                accessibilityState={{ selected: isSelected }}
                accessibilityLabel={option.title}
                accessibilityHint={option.subtitle}
              >
                <Text style={styles.optionEmoji}>{option.emoji}</Text>
                <View style={styles.optionText}>
                  <Text style={[styles.optionTitle, { color: theme.textPrimary, fontFamily: fontFamilies.sans.semiBold }]}>
                    {option.title}
                  </Text>
                  <Text style={[styles.optionSubtitle, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
                    {option.subtitle}
                  </Text>
                </View>
                {isSelected && (
                  <View style={[styles.checkmark, { backgroundColor: theme.accent }]}>
                    <Text style={styles.checkmarkIcon}>✓</Text>
                  </View>
                )}
              </TouchableOpacity>
            );
          })}
        </View>

        <TouchableOpacity
          style={[
            styles.continueButton,
            {
              backgroundColor: selected ? theme.accent : theme.sand300,
            },
          ]}
          onPress={handleContinue}
          disabled={false} // allow skip — user can continue without selecting
          accessibilityRole="button"
          accessibilityLabel={selected ? "Continue" : "Skip for now"}
        >
          <Text style={[styles.continueText, { fontFamily: fontFamilies.sans.semiBold }]}>
            {selected ? 'Continue' : 'Skip for now'}
          </Text>
        </TouchableOpacity>

      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  scroll: { paddingHorizontal: 24, paddingTop: 64, paddingBottom: 40 },
  heading: { fontSize: 28, lineHeight: 36, marginBottom: 12 },
  subheading: { fontSize: 15, lineHeight: 22, marginBottom: 32, opacity: 0.8 },
  options: { gap: 12, marginBottom: 32 },
  optionCard: {
    flexDirection: 'row', alignItems: 'center',
    padding: 16, borderRadius: 16, gap: 12,
  },
  optionEmoji: { fontSize: 28, width: 40, textAlign: 'center' },
  optionText: { flex: 1 },
  optionTitle: { fontSize: 15, marginBottom: 2 },
  optionSubtitle: { fontSize: 13, opacity: 0.7 },
  checkmark: {
    width: 24, height: 24, borderRadius: 12,
    justifyContent: 'center', alignItems: 'center',
  },
  checkmarkIcon: { color: '#FFFFFF', fontSize: 14, fontWeight: '700' },
  continueButton: {
    height: 56, borderRadius: 16,
    justifyContent: 'center', alignItems: 'center',
  },
  continueText: { fontSize: 17, color: '#FFFFFF' },
});
