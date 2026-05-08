import React from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity,
  Switch, Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import { useAccessibilityStore } from '@/store/accessibility.store';
import { fontFamilies } from '@/constants/typography';

const FONT_SIZES = [
  { label: 'Small', key: 'small' as const },
  { label: 'Default', key: 'default' as const },
  { label: 'Large', key: 'large' as const },
  { label: 'X-Large', key: 'extraLarge' as const },
  { label: 'Huge', key: 'huge' as const },
];

const THEMES = [
  { label: 'Light', key: 'light' as const },
  { label: 'Dark', key: 'dark' as const },
  { label: 'High Contrast', key: 'highContrast' as const },
];

const FONTS = [
  { label: 'Serif (Lora)', key: 'serif' as const },
  { label: 'Sans-serif (Inter)', key: 'sans' as const },
  { label: 'OpenDyslexic', key: 'dyslexic' as const },
];

const COLOUR_MODES = [
  { label: 'Default', key: 'none' as const },
  { label: 'Deuteranopia', key: 'deuteranopia' as const },
  { label: 'Protanopia', key: 'protanopia' as const },
  { label: 'Tritanopia', key: 'tritanopia' as const },
];

export default function AccessibilitySettingsScreen() {
  const nav = useNavigation();
  const { theme } = useAccessibilitySettings();
  const {
    theme: themeName, setTheme,
    readerFontSize, setReaderFontSize,
    fontFamily, setFontFamily,
    boldText, setBoldText,
    lineSpacingMultiplier, setLineSpacingMultiplier,
    reduceMotion, setReduceMotion,
    hapticsEnabled, setHapticsEnabled,
    largeTouchTargets, setLargeTouchTargets,
    colourBlindMode, setColourBlindMode,
  } = useAccessibilityStore();

  const s = StyleSheet.create({
    container: { flex: 1 },
    header: {
      flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
      paddingTop: Platform.OS === 'ios' ? 56 : 16, paddingBottom: 12,
      paddingHorizontal: 16, borderBottomWidth: StyleSheet.hairlineWidth,
    },
    backBtn: { width: 60 },
    backText: { fontSize: 16 },
    title: { fontSize: 17 },
    scroll: { padding: 24 },
    sectionLabel: { fontSize: 11, letterSpacing: 0.8, marginBottom: 12, marginTop: 8 },
    chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 24 },
    chip: {
      paddingHorizontal: 16, paddingVertical: 10,
      borderRadius: 20, borderWidth: 1.5,
    },
    chipText: { fontSize: 14 },
    card: { borderRadius: 16, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden', marginBottom: 24 },
    row: {
      flexDirection: 'row', alignItems: 'center', padding: 16,
      borderBottomWidth: StyleSheet.hairlineWidth, minHeight: 52,
    },
    rowLabel: { flex: 1, fontSize: 16 },
    preview: {
      marginBottom: 24, borderRadius: 14, padding: 20,
      borderWidth: StyleSheet.hairlineWidth,
    },
    previewText: { fontSize: 19, lineHeight: 30 },
  });

  return (
    <View style={[s.container, { backgroundColor: theme.background }]}>
      <View style={[s.header, { borderBottomColor: theme.border }]}>
        <TouchableOpacity onPress={() => nav.goBack()} style={s.backBtn}
          accessibilityRole="button" accessibilityLabel="Go back">
          <Text style={[s.backText, { color: theme.accent, fontFamily: fontFamilies.sans.medium }]}>‹ Back</Text>
        </TouchableOpacity>
        <Text style={[s.title, { color: theme.textPrimary, fontFamily: fontFamilies.sans.semiBold }]}
          accessibilityRole="header">
          Accessibility
        </Text>
        <View style={{ width: 60 }} />
      </View>

      <ScrollView contentContainerStyle={s.scroll} showsVerticalScrollIndicator={false}>

        {/* Preview */}
        <View style={[s.preview, { backgroundColor: theme.readerBackground, borderColor: theme.border }]}>
          <Text style={[s.previewText, {
            color: theme.verseText,
            fontFamily: fontFamily === 'dyslexic'
              ? fontFamilies.dyslexic?.regular ?? fontFamilies.serif.regular
              : fontFamily === 'sans'
                ? fontFamilies.sans.regular
                : fontFamilies.serif.regular,
          }]}>
            "For God so loved the world that he gave his one and only Son."
          </Text>
          <Text style={[{ fontSize: 13, marginTop: 8, color: theme.verseNumber, fontFamily: fontFamilies.sans.regular }]}>
            John 3:16 — Preview
          </Text>
        </View>

        {/* Theme */}
        <Text style={[s.sectionLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
          THEME
        </Text>
        <View style={s.chipRow}>
          {THEMES.map(({ label, key }) => (
            <TouchableOpacity
              key={key}
              style={[s.chip, {
                backgroundColor: themeName === key ? theme.accent : theme.surface,
                borderColor: themeName === key ? theme.accent : theme.border,
              }]}
              onPress={() => setTheme(key)}
              accessibilityRole="radio"
              accessibilityState={{ selected: themeName === key }}
              accessibilityLabel={label}
            >
              <Text style={[s.chipText, {
                color: themeName === key ? '#FFF' : theme.textPrimary,
                fontFamily: fontFamilies.sans.medium,
              }]}>
                {label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Font size */}
        <Text style={[s.sectionLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
          TEXT SIZE
        </Text>
        <View style={s.chipRow}>
          {FONT_SIZES.map(({ label, key }) => (
            <TouchableOpacity
              key={key}
              style={[s.chip, {
                backgroundColor: readerFontSize === key ? theme.accent : theme.surface,
                borderColor: readerFontSize === key ? theme.accent : theme.border,
              }]}
              onPress={() => setReaderFontSize(key)}
              accessibilityRole="radio"
              accessibilityState={{ selected: readerFontSize === key }}
              accessibilityLabel={label}
            >
              <Text style={[s.chipText, {
                color: readerFontSize === key ? '#FFF' : theme.textPrimary,
                fontFamily: fontFamilies.sans.medium,
              }]}>
                {label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Font family */}
        <Text style={[s.sectionLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
          READING FONT
        </Text>
        <View style={s.chipRow}>
          {FONTS.map(({ label, key }) => (
            <TouchableOpacity
              key={key}
              style={[s.chip, {
                backgroundColor: fontFamily === key ? theme.accent : theme.surface,
                borderColor: fontFamily === key ? theme.accent : theme.border,
              }]}
              onPress={() => setFontFamily(key)}
              accessibilityRole="radio"
              accessibilityState={{ selected: fontFamily === key }}
              accessibilityLabel={label}
            >
              <Text style={[s.chipText, {
                color: fontFamily === key ? '#FFF' : theme.textPrimary,
                fontFamily: fontFamilies.sans.medium,
              }]}>
                {label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Colour vision */}
        <Text style={[s.sectionLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
          COLOUR VISION
        </Text>
        <View style={s.chipRow}>
          {COLOUR_MODES.map(({ label, key }) => (
            <TouchableOpacity
              key={key}
              style={[s.chip, {
                backgroundColor: colourBlindMode === key ? theme.accent : theme.surface,
                borderColor: colourBlindMode === key ? theme.accent : theme.border,
              }]}
              onPress={() => setColourBlindMode(key)}
              accessibilityRole="radio"
              accessibilityState={{ selected: colourBlindMode === key }}
              accessibilityLabel={label}
            >
              <Text style={[s.chipText, {
                color: colourBlindMode === key ? '#FFF' : theme.textPrimary,
                fontFamily: fontFamilies.sans.medium,
              }]}>
                {label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Toggles */}
        <Text style={[s.sectionLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
          DISPLAY
        </Text>
        <View style={[s.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          {[
            { label: 'Bold text', value: boldText, onChange: setBoldText },
            { label: 'Large touch targets', value: largeTouchTargets, onChange: setLargeTouchTargets },
            { label: 'Reduce motion', value: reduceMotion, onChange: setReduceMotion },
            { label: 'Haptic feedback', value: hapticsEnabled, onChange: setHapticsEnabled },
          ].map(({ label, value, onChange }, idx, arr) => (
            <View
              key={label}
              style={[s.row, { borderBottomColor: theme.border, borderBottomWidth: idx < arr.length - 1 ? StyleSheet.hairlineWidth : 0 }]}
            >
              <Text style={[s.rowLabel, { color: theme.textPrimary, fontFamily: fontFamilies.sans.regular }]}>
                {label}
              </Text>
              <Switch
                value={value}
                onValueChange={onChange}
                trackColor={{ false: theme.border, true: theme.accent + 'AA' }}
                thumbColor={value ? theme.accent : theme.textTertiary}
                accessibilityLabel={label}
              />
            </View>
          ))}
        </View>

        <View style={{ height: 40 }} />
      </ScrollView>
    </View>
  );
}
