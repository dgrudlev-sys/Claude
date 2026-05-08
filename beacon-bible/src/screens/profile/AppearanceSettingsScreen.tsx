import React from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity, Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import { useReaderStore } from '@/store/reader.store';
import { fontFamilies } from '@/constants/typography';

const LINE_SPACINGS = [
  { label: 'Compact', value: 1.0 },
  { label: 'Default', value: 1.4 },
  { label: 'Relaxed', value: 1.8 },
  { label: 'Spacious', value: 2.2 },
];

export default function AppearanceSettingsScreen() {
  const nav = useNavigation();
  const { theme } = useAccessibilitySettings();
  const { showVerseNumbers, setShowVerseNumbers, readerMode, setReaderMode } = useReaderStore();

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={[styles.header, { borderBottomColor: theme.border }]}>
        <TouchableOpacity onPress={() => nav.goBack()} style={styles.backBtn}
          accessibilityRole="button" accessibilityLabel="Go back">
          <Text style={[styles.backText, { color: theme.accent, fontFamily: fontFamilies.sans.medium }]}>‹ Back</Text>
        </TouchableOpacity>
        <Text style={[styles.title, { color: theme.textPrimary, fontFamily: fontFamilies.sans.semiBold }]}
          accessibilityRole="header">
          Appearance
        </Text>
        <View style={{ width: 60 }} />
      </View>

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>

        <Text style={[styles.sectionLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
          READER MODE
        </Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          {(['normal', 'zen'] as const).map((mode, idx, arr) => (
            <TouchableOpacity
              key={mode}
              style={[styles.row, {
                borderBottomColor: theme.border,
                borderBottomWidth: idx < arr.length - 1 ? StyleSheet.hairlineWidth : 0,
              }]}
              onPress={() => setReaderMode(mode)}
              accessibilityRole="radio"
              accessibilityState={{ selected: readerMode === mode }}
            >
              <View style={styles.rowContent}>
                <Text style={[styles.rowLabel, { color: theme.textPrimary, fontFamily: fontFamilies.sans.regular }]}>
                  {mode === 'normal' ? 'Normal' : 'Zen mode'}
                </Text>
                <Text style={[styles.rowSub, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
                  {mode === 'normal' ? 'Full navigation and controls' : 'Minimal chrome, text only'}
                </Text>
              </View>
              {readerMode === mode && (
                <Text style={[styles.check, { color: theme.accent }]}>✓</Text>
              )}
            </TouchableOpacity>
          ))}
        </View>

        <Text style={[styles.sectionLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
          VERSE NUMBERS
        </Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <TouchableOpacity
            style={[styles.row, { borderBottomWidth: 0 }]}
            onPress={() => setShowVerseNumbers(!showVerseNumbers)}
            accessibilityRole="switch"
            accessibilityState={{ checked: showVerseNumbers }}
            accessibilityLabel="Show verse numbers"
          >
            <Text style={[styles.rowLabel, { color: theme.textPrimary, fontFamily: fontFamilies.sans.regular }]}>
              Show verse numbers
            </Text>
            <View style={[styles.toggle, {
              backgroundColor: showVerseNumbers ? theme.accent : theme.border,
            }]}>
              <View style={[styles.toggleThumb, {
                transform: [{ translateX: showVerseNumbers ? 18 : 2 }],
              }]} />
            </View>
          </TouchableOpacity>
        </View>

        <View style={{ height: 40 }} />
      </ScrollView>
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
  scroll: { padding: 24 },
  sectionLabel: { fontSize: 11, letterSpacing: 0.8, marginBottom: 12, marginTop: 8 },
  card: { borderRadius: 16, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden', marginBottom: 24 },
  row: { flexDirection: 'row', alignItems: 'center', padding: 16, minHeight: 52 },
  rowContent: { flex: 1 },
  rowLabel: { fontSize: 16 },
  rowSub: { fontSize: 13, marginTop: 2 },
  check: { fontSize: 18, fontWeight: '700' },
  toggle: {
    width: 44, height: 26, borderRadius: 13,
    justifyContent: 'center',
  },
  toggleThumb: {
    width: 22, height: 22, borderRadius: 11,
    backgroundColor: '#FFF',
    shadowColor: '#000', shadowOpacity: 0.15, shadowRadius: 2, shadowOffset: { width: 0, height: 1 },
    elevation: 2,
  },
});
