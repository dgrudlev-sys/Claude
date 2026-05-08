import React, { useEffect, useRef } from 'react';
import {
  View, Text, StyleSheet, TouchableOpacity, Animated,
  AccessibilityInfo, Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { colors } from '@/constants/colors';
import { fontFamilies } from '@/constants/typography';
import type { OnboardingStackParamList } from '@/types/navigation.types';

type Nav = NativeStackNavigationProp<OnboardingStackParamList, 'Welcome'>;

export default function WelcomeScreen() {
  const nav = useNavigation<Nav>();
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const slideAnim = useRef(new Animated.Value(24)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.timing(fadeAnim, { toValue: 1, duration: 800, useNativeDriver: true }),
      Animated.timing(slideAnim, { toValue: 0, duration: 600, useNativeDriver: true }),
    ]).start();

    // Announce to screen readers
    AccessibilityInfo.announceForAccessibility(
      'Welcome to Beacon Bible. A free Bible app built for everyone.'
    );
  }, []);

  const theme = colors.light;

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <Animated.View style={[styles.content, { opacity: fadeAnim, transform: [{ translateY: slideAnim }] }]}>

        {/* Logo mark */}
        <View
          style={[styles.logoMark, { backgroundColor: theme.accent }]}
          accessibilityRole="image"
          accessibilityLabel="Beacon Bible logo"
        >
          <Text style={styles.logoIcon}>✦</Text>
        </View>

        <Text
          style={[styles.appName, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}
          accessibilityRole="header"
        >
          Beacon Bible
        </Text>

        <Text style={[styles.tagline, { color: theme.textSecondary, fontFamily: fontFamilies.serif.regular }]}>
          Light for every reader
        </Text>

        <Text style={[styles.missionNote, { color: theme.textTertiary, fontFamily: fontFamilies.sans.regular }]}>
          Free forever · Funds blindness research
        </Text>

        <View style={styles.spacer} />

        <TouchableOpacity
          style={[styles.startButton, { backgroundColor: theme.accent }]}
          onPress={() => nav.navigate('Intent')}
          accessibilityRole="button"
          accessibilityLabel="Begin — get started with Beacon Bible"
          accessibilityHint="Takes you to choose your reading focus"
        >
          <Text style={[styles.startButtonText, { fontFamily: fontFamilies.sans.semiBold }]}>
            Begin
          </Text>
        </TouchableOpacity>

        <Text style={[styles.legalNote, { color: theme.textTertiary, fontFamily: fontFamilies.sans.regular }]}>
          No account required to start reading
        </Text>

      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', paddingHorizontal: 32 },
  content: { alignItems: 'center', width: '100%' },
  logoMark: {
    width: 72, height: 72, borderRadius: 20,
    justifyContent: 'center', alignItems: 'center', marginBottom: 24,
  },
  logoIcon: { fontSize: 32, color: '#FFFFFF' },
  appName: { fontSize: 36, letterSpacing: -0.5, marginBottom: 8 },
  tagline: { fontSize: 18, marginBottom: 12, opacity: 0.8 },
  missionNote: { fontSize: 13, marginBottom: 0 },
  spacer: { height: 64 },
  startButton: {
    width: '100%', height: 56, borderRadius: 16,
    justifyContent: 'center', alignItems: 'center', marginBottom: 16,
  },
  startButtonText: { fontSize: 18, color: '#FFFFFF', letterSpacing: 0.3 },
  legalNote: { fontSize: 12, textAlign: 'center' },
});
