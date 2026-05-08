import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Animated } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import * as Haptics from 'expo-haptics';
import { colors } from '@/constants/colors';
import { fontFamilies } from '@/constants/typography';
import { usePreferencesStore } from '@/store/preferences.store';
import type { OnboardingStackParamList } from '@/types/navigation.types';

type Nav = NativeStackNavigationProp<OnboardingStackParamList, 'OnboardingComplete'>;

export default function OnboardingCompleteScreen() {
  const nav = useNavigation<Nav>();
  const setOnboardingComplete = usePreferencesStore(s => s.setOnboardingComplete);
  const onboardingIntent = usePreferencesStore(s => s.onboardingIntent);
  const scaleAnim = useRef(new Animated.Value(0.8)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const theme = colors.light;

  useEffect(() => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    Animated.parallel([
      Animated.spring(scaleAnim, { toValue: 1, tension: 60, friction: 8, useNativeDriver: true }),
      Animated.timing(fadeAnim, { toValue: 1, duration: 600, useNativeDriver: true }),
    ]).start();
  }, []);

  function handleStart() {
    setOnboardingComplete(onboardingIntent);
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <Animated.View style={[styles.content, { opacity: fadeAnim, transform: [{ scale: scaleAnim }] }]}>

        <View style={[styles.iconWrap, { backgroundColor: theme.accent + '22' }]}>
          <Text style={styles.icon}>✦</Text>
        </View>

        <Text style={[styles.heading, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}
          accessibilityRole="header">
          You're ready
        </Text>

        <Text style={[styles.body, { color: theme.textSecondary, fontFamily: fontFamilies.serif.regular }]}>
          Beacon Bible is free, always. Every donation beyond what it costs to run goes directly to restoring sight to those who've lost it.
        </Text>

        <Text style={[styles.verse, { color: theme.textTertiary, fontFamily: fontFamilies.serif.italic }]}>
          "To give light to those who sit in darkness… to guide our feet into the way of peace."
        </Text>
        <Text style={[styles.verseRef, { color: theme.accent, fontFamily: fontFamilies.sans.medium }]}>
          Luke 1:79
        </Text>

        <TouchableOpacity
          style={[styles.startButton, { backgroundColor: theme.accent }]}
          onPress={handleStart}
          accessibilityRole="button"
          accessibilityLabel="Start reading the Bible"
        >
          <Text style={[styles.startText, { fontFamily: fontFamilies.sans.semiBold }]}>
            Start reading
          </Text>
        </TouchableOpacity>

      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', paddingHorizontal: 32 },
  content: { alignItems: 'center', width: '100%' },
  iconWrap: {
    width: 80, height: 80, borderRadius: 24,
    justifyContent: 'center', alignItems: 'center', marginBottom: 28,
  },
  icon: { fontSize: 36, color: '#D97706' },
  heading: { fontSize: 32, marginBottom: 20, textAlign: 'center' },
  body: {
    fontSize: 16, lineHeight: 26, textAlign: 'center',
    marginBottom: 28, opacity: 0.85,
  },
  verse: { fontSize: 15, lineHeight: 24, textAlign: 'center', marginBottom: 6 },
  verseRef: { fontSize: 13, marginBottom: 48 },
  startButton: {
    width: '100%', height: 56, borderRadius: 16,
    justifyContent: 'center', alignItems: 'center',
  },
  startText: { fontSize: 18, color: '#FFFFFF' },
});
