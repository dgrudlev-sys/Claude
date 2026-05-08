import React, { useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity, Switch, Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import { usePreferencesStore } from '@/store/preferences.store';
import { fontFamilies } from '@/constants/typography';

const REMINDER_TIMES = [
  { label: 'Morning', sub: '7:00 AM', value: '07:00' },
  { label: 'Midday', sub: '12:00 PM', value: '12:00' },
  { label: 'Evening', sub: '8:00 PM', value: '20:00' },
  { label: 'Night', sub: '10:00 PM', value: '22:00' },
];

export default function NotificationSettingsScreen() {
  const nav = useNavigation();
  const { theme } = useAccessibilitySettings();
  const { notificationsEnabled, dailyReminderTime, setNotifications } = usePreferencesStore();

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={[styles.header, { borderBottomColor: theme.border }]}>
        <TouchableOpacity onPress={() => nav.goBack()} style={styles.backBtn}
          accessibilityRole="button" accessibilityLabel="Go back">
          <Text style={[styles.backText, { color: theme.accent, fontFamily: fontFamilies.sans.medium }]}>‹ Back</Text>
        </TouchableOpacity>
        <Text style={[styles.title, { color: theme.textPrimary, fontFamily: fontFamilies.sans.semiBold }]}
          accessibilityRole="header">
          Notifications
        </Text>
        <View style={{ width: 60 }} />
      </View>

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>

        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={[styles.row, { borderBottomWidth: 0 }]}>
            <View style={{ flex: 1 }}>
              <Text style={[styles.rowLabel, { color: theme.textPrimary, fontFamily: fontFamilies.sans.regular }]}>
                Daily reading reminder
              </Text>
              <Text style={[styles.rowSub, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
                A gentle nudge to keep your streak going
              </Text>
            </View>
            <Switch
              value={notificationsEnabled}
              onValueChange={(v) => setNotifications(v)}
              trackColor={{ false: theme.border, true: theme.accent + 'AA' }}
              thumbColor={notificationsEnabled ? theme.accent : theme.textTertiary}
              accessibilityLabel="Daily reading reminder"
            />
          </View>
        </View>

        {notificationsEnabled && (
          <>
            <Text style={[styles.sectionLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
              REMINDER TIME
            </Text>
            <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
              {REMINDER_TIMES.map(({ label, sub, value }, idx, arr) => (
                <TouchableOpacity
                  key={value}
                  style={[styles.row, {
                    borderBottomColor: theme.border,
                    borderBottomWidth: idx < arr.length - 1 ? StyleSheet.hairlineWidth : 0,
                  }]}
                  onPress={() => setNotifications(notificationsEnabled, value)}
                  accessibilityRole="radio"
                  accessibilityState={{ selected: dailyReminderTime === value }}
                  accessibilityLabel={`${label} at ${sub}`}
                >
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.rowLabel, { color: theme.textPrimary, fontFamily: fontFamilies.sans.regular }]}>
                      {label}
                    </Text>
                    <Text style={[styles.rowSub, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
                      {sub}
                    </Text>
                  </View>
                  {dailyReminderTime === value && (
                    <Text style={[styles.check, { color: theme.accent }]}>✓</Text>
                  )}
                </TouchableOpacity>
              ))}
            </View>
          </>
        )}

        <Text style={[styles.note, { color: theme.textTertiary, fontFamily: fontFamilies.sans.regular }]}>
          Beacon Bible only sends daily reading reminders. No marketing, no streak-shaming — just a quiet invitation to read.
        </Text>

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
  rowLabel: { fontSize: 16 },
  rowSub: { fontSize: 13, marginTop: 2 },
  check: { fontSize: 18, fontWeight: '700' },
  note: { fontSize: 13, lineHeight: 20, textAlign: 'center', marginTop: 8 },
});
