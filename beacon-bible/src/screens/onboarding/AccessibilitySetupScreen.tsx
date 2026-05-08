import React from 'react';
import {
  View, Text, StyleSheet, TouchableOpacity, ScrollView, Switch,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import * as Haptics from 'expo-haptics';
import { colors } from '@/constants/colors';
import { fontFamilies, readerFontSizes } from '@/constants/typography';
import { useAccessibilityStore } from '@/store/accessibility.store';
import type { OnboardingStackParamList } from '@/types/navigation.types';

type Nav = NativeStackNavigationProp<OnboardingStackParamList, 'AccessibilitySetup'>;

export default function AccessibilitySetupScreen() {
  const nav = useNavigation<Nav>();
  const store = useAccessibilityStore();
  const theme = colors.light;

  function handleToggle(setter: (v: boolean) => void, value: boolean) {
    if (store.hapticsEnabled) Haptics.selectionAsync();
    setter(!value);
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>

        <Text style={[styles.heading, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}
          accessibilityRole="header">
          Make it yours
        </Text>
        <Text style={[styles.subheading, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
          Adjust how Beacon Bible looks and feels. Every setting can be changed later in your profile.
        </Text>

        {/* Font Size */}
        <SectionHeader label="Text size" theme={theme} />
        <View style={styles.fontSizeRow}>
          {(Object.keys(readerFontSizes) as Array<keyof typeof readerFontSizes>).map((size) => (
            <TouchableOpacity
              key={size}
              style={[
                styles.fontSizeOption,
                {
                  backgroundColor: store.readerFontSize === size ? theme.accent : theme.surfaceSecondary,
                  borderColor: store.readerFontSize === size ? theme.accent : theme.border,
                },
              ]}
              onPress={() => store.setReaderFontSize(size)}
              accessibilityRole="radio"
              accessibilityState={{ selected: store.readerFontSize === size }}
              accessibilityLabel={`Text size: ${size}`}
            >
              <Text style={{
                fontSize: readerFontSizes[size] * 0.7,
                color: store.readerFontSize === size ? '#FFFFFF' : theme.textPrimary,
                fontFamily: fontFamilies.serif.regular,
              }}>
                Aa
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Theme */}
        <SectionHeader label="Appearance" theme={theme} />
        <View style={styles.themeRow}>
          {(['light', 'dark', 'highContrast'] as const).map((t) => {
            const labels = { light: 'Light', dark: 'Dark', highContrast: 'High contrast' };
            const isSelected = store.theme === t;
            return (
              <TouchableOpacity
                key={t}
                style={[
                  styles.themeOption,
                  {
                    backgroundColor: t === 'light' ? '#FDFAF5' : t === 'dark' ? '#0D1117' : '#000000',
                    borderColor: isSelected ? theme.accent : theme.border,
                    borderWidth: isSelected ? 2 : StyleSheet.hairlineWidth,
                  },
                ]}
                onPress={() => store.setTheme(t)}
                accessibilityRole="radio"
                accessibilityState={{ selected: isSelected }}
                accessibilityLabel={labels[t]}
              >
                <Text style={{
                  fontSize: 11,
                  color: t === 'light' ? '#3D1F00' : '#FFFFFF',
                  fontFamily: fontFamilies.sans.medium,
                  textAlign: 'center',
                }}>
                  {labels[t]}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>

        {/* Toggle options */}
        <SectionHeader label="Reading & interaction" theme={theme} />
        <ToggleRow
          label="Bold text"
          description="Makes all text heavier for easier reading"
          value={store.boldText}
          onToggle={() => handleToggle(store.setBoldText, store.boldText)}
          theme={theme}
        />
        <ToggleRow
          label="Large touch targets"
          description="Increases button sizes for easier tapping"
          value={store.largeTouchTargets}
          onToggle={() => handleToggle(store.setLargeTouchTargets, store.largeTouchTargets)}
          theme={theme}
        />
        <ToggleRow
          label="Reduce motion"
          description="Turns off animations and transitions"
          value={store.reduceMotion}
          onToggle={() => handleToggle(store.setReduceMotion, store.reduceMotion)}
          theme={theme}
        />
        <ToggleRow
          label="Haptic feedback"
          description="Gentle vibrations when you tap buttons"
          value={store.hapticsEnabled}
          onToggle={() => handleToggle(store.setHapticsEnabled, store.hapticsEnabled)}
          theme={theme}
        />

        {/* Colour blind modes */}
        <SectionHeader label="Colour vision" theme={theme} />
        {(['none', 'deuteranopia', 'protanopia', 'tritanopia'] as const).map((mode) => {
          const labels = {
            none: 'Standard colours',
            deuteranopia: 'Deuteranopia (red-green)',
            protanopia: 'Protanopia (red-green)',
            tritanopia: 'Tritanopia (blue-yellow)',
          };
          const isSelected = store.colourBlindMode === mode;
          return (
            <TouchableOpacity
              key={mode}
              style={[styles.colourRow, { borderColor: isSelected ? theme.accent : theme.border }]}
              onPress={() => store.setColourBlindMode(mode)}
              accessibilityRole="radio"
              accessibilityState={{ selected: isSelected }}
              accessibilityLabel={labels[mode]}
            >
              <View style={[styles.radioOuter, { borderColor: isSelected ? theme.accent : theme.sand400 }]}>
                {isSelected && <View style={[styles.radioInner, { backgroundColor: theme.accent }]} />}
              </View>
              <Text style={[styles.colourLabel, { color: theme.textPrimary, fontFamily: fontFamilies.sans.regular }]}>
                {labels[mode]}
              </Text>
            </TouchableOpacity>
          );
        })}

        <TouchableOpacity
          style={[styles.continueButton, { backgroundColor: theme.accent }]}
          onPress={() => nav.navigate('LanguagePicker')}
          accessibilityRole="button"
          accessibilityLabel="Looks good, continue"
        >
          <Text style={[styles.continueText, { fontFamily: fontFamilies.sans.semiBold }]}>
            Looks good
          </Text>
        </TouchableOpacity>

      </ScrollView>
    </View>
  );
}

function SectionHeader({ label, theme }: { label: string; theme: typeof colors.light }) {
  return (
    <Text style={[{
      fontSize: 12, fontFamily: fontFamilies.sans.semiBold,
      color: theme.textTertiary, letterSpacing: 0.8,
      textTransform: 'uppercase', marginTop: 24, marginBottom: 12,
    }]}>
      {label}
    </Text>
  );
}

function ToggleRow({ label, description, value, onToggle, theme }: {
  label: string; description: string; value: boolean;
  onToggle: () => void; theme: typeof colors.light;
}) {
  return (
    <View style={[styles.toggleRow, { borderColor: theme.border }]}>
      <View style={styles.toggleText}>
        <Text style={[styles.toggleLabel, { color: theme.textPrimary, fontFamily: fontFamilies.sans.medium }]}>
          {label}
        </Text>
        <Text style={[styles.toggleDesc, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
          {description}
        </Text>
      </View>
      <Switch
        value={value}
        onValueChange={onToggle}
        accessibilityLabel={label}
        accessibilityRole="switch"
        accessibilityState={{ checked: value }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  scroll: { paddingHorizontal: 24, paddingTop: 64, paddingBottom: 48 },
  heading: { fontSize: 28, lineHeight: 36, marginBottom: 12 },
  subheading: { fontSize: 15, lineHeight: 22, marginBottom: 8, opacity: 0.8 },
  fontSizeRow: { flexDirection: 'row', gap: 10 },
  fontSizeOption: {
    flex: 1, height: 56, borderRadius: 12, borderWidth: 1,
    justifyContent: 'center', alignItems: 'center',
  },
  themeRow: { flexDirection: 'row', gap: 10 },
  themeOption: {
    flex: 1, height: 64, borderRadius: 12,
    justifyContent: 'center', alignItems: 'center', padding: 8,
  },
  toggleRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingVertical: 14, borderBottomWidth: StyleSheet.hairlineWidth,
  },
  toggleText: { flex: 1, marginRight: 16 },
  toggleLabel: { fontSize: 15, marginBottom: 2 },
  toggleDesc: { fontSize: 12, opacity: 0.7 },
  colourRow: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    paddingVertical: 12, paddingHorizontal: 4,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  radioOuter: {
    width: 22, height: 22, borderRadius: 11, borderWidth: 2,
    justifyContent: 'center', alignItems: 'center',
  },
  radioInner: { width: 12, height: 12, borderRadius: 6 },
  colourLabel: { fontSize: 15 },
  continueButton: {
    height: 56, borderRadius: 16, marginTop: 40,
    justifyContent: 'center', alignItems: 'center',
  },
  continueText: { fontSize: 17, color: '#FFFFFF' },
});
