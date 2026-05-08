import React from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity,
  Linking, Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import { usePreferencesStore } from '@/store/preferences.store';
import { fontFamilies } from '@/constants/typography';
import type { ProfileStackParamList } from '@/types/navigation.types';

type Nav = NativeStackNavigationProp<ProfileStackParamList, 'Profile'>;

const FRED_HOLLOWS_URL = 'https://www.hollows.org/donate/';
const FFB_URL = 'https://www.fightingblindness.org/donate/';

export default function ProfileScreen() {
  const nav = useNavigation<Nav>();
  const { theme } = useAccessibilitySettings();
  const { streakCount, totalDaysRead } = usePreferencesStore();

  function openLink(url: string) {
    Linking.openURL(url);
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>

        <Text style={[styles.heading, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}
          accessibilityRole="header">
          My Library
        </Text>

        {/* Stats */}
        <View style={styles.statsRow}>
          <StatCard value={streakCount} label="Day streak" theme={theme} />
          <StatCard value={totalDaysRead} label="Days read" theme={theme} />
        </View>

        {/* Menu groups */}
        <MenuGroup label="ANNOTATIONS" theme={theme}>
          <MenuItem icon="🖊" label="Highlights" onPress={() => nav.navigate('Highlights')} theme={theme} />
          <MenuItem icon="🔖" label="Bookmarks" onPress={() => nav.navigate('Bookmarks')} theme={theme} />
          <MenuItem icon="📝" label="Notes" onPress={() => nav.navigate('Notes')} theme={theme} />
        </MenuGroup>

        <MenuGroup label="CONTENT" theme={theme}>
          <MenuItem icon="📥" label="Downloaded content" onPress={() => nav.navigate('Downloads')} theme={theme} />
        </MenuGroup>

        <MenuGroup label="SETTINGS" theme={theme}>
          <MenuItem icon="♿" label="Accessibility" onPress={() => nav.navigate('AccessibilitySettings')} theme={theme} />
          <MenuItem icon="🎨" label="Appearance" onPress={() => nav.navigate('AppearanceSettings')} theme={theme} />
          <MenuItem icon="🔔" label="Notifications" onPress={() => nav.navigate('NotificationSettings')} theme={theme} />
        </MenuGroup>

        {/* Donation section */}
        <View style={[styles.donationCard, { backgroundColor: theme.accent + '14', borderColor: theme.accent + '40' }]}>
          <Text style={[styles.donationTitle, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}>
            Support the mission
          </Text>
          <Text style={[styles.donationBody, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
            Beacon Bible is free forever. Donations beyond running costs go directly to restoring sight — $25 funds one cataract surgery.
          </Text>
          <TouchableOpacity
            style={[styles.donateBtn, { backgroundColor: theme.accent }]}
            onPress={() => openLink(FRED_HOLLOWS_URL)}
            accessibilityRole="link"
            accessibilityLabel="Donate to the Fred Hollows Foundation — opens in browser"
          >
            <Text style={[styles.donateBtnText, { fontFamily: fontFamilies.sans.semiBold }]}>
              Donate — Fred Hollows Foundation ↗
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.donateBtnSecondary, { borderColor: theme.accent }]}
            onPress={() => openLink(FFB_URL)}
            accessibilityRole="link"
            accessibilityLabel="Donate to Foundation Fighting Blindness — opens in browser"
          >
            <Text style={[styles.donateBtnSecondaryText, { color: theme.accent, fontFamily: fontFamilies.sans.medium }]}>
              Foundation Fighting Blindness ↗
            </Text>
          </TouchableOpacity>

          <Text style={[styles.donationNote, { color: theme.textTertiary, fontFamily: fontFamilies.sans.regular }]}>
            You'll be taken to the charity's secure website.{'\n'}Beacon Bible receives no payment data.
          </Text>
        </View>

        {/* Mission verse */}
        <Text style={[styles.missionVerse, { color: theme.textTertiary, fontFamily: fontFamilies.serif.italic }]}>
          "To give light to those who sit in darkness… to guide our feet into the way of peace."
        </Text>
        <Text style={[styles.missionRef, { color: theme.accent, fontFamily: fontFamilies.sans.regular }]}>
          Luke 1:79
        </Text>

        <View style={{ height: 48 }} />
      </ScrollView>
    </View>
  );
}

function StatCard({ value, label, theme }: { value: number; label: string; theme: any }) {
  return (
    <View style={[styles.statCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
      accessibilityLabel={`${value} ${label}`}>
      <Text style={[styles.statValue, { color: theme.accent, fontFamily: fontFamilies.serif.bold }]}>
        {value}
      </Text>
      <Text style={[styles.statLabel, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
        {label}
      </Text>
    </View>
  );
}

function MenuGroup({ label, children, theme }: { label: string; children: React.ReactNode; theme: any }) {
  return (
    <View style={styles.menuGroup}>
      <Text style={[styles.menuGroupLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
        {label}
      </Text>
      <View style={[styles.menuGroupItems, { backgroundColor: theme.surface, borderColor: theme.border }]}>
        {children}
      </View>
    </View>
  );
}

function MenuItem({ icon, label, onPress, theme }: {
  icon: string; label: string; onPress: () => void; theme: any;
}) {
  return (
    <TouchableOpacity
      style={[styles.menuItem, { borderBottomColor: theme.border }]}
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={label}
    >
      <Text style={styles.menuIcon}>{icon}</Text>
      <Text style={[styles.menuLabel, { color: theme.textPrimary, fontFamily: fontFamilies.sans.regular }]}>
        {label}
      </Text>
      <Text style={[styles.menuChevron, { color: theme.textTertiary }]}>›</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  scroll: { paddingTop: Platform.OS === 'ios' ? 64 : 24, paddingHorizontal: 24 },
  heading: { fontSize: 30, marginBottom: 20 },
  statsRow: { flexDirection: 'row', gap: 12, marginBottom: 24 },
  statCard: {
    flex: 1, borderRadius: 16, borderWidth: StyleSheet.hairlineWidth,
    padding: 16, alignItems: 'center',
  },
  statValue: { fontSize: 36 },
  statLabel: { fontSize: 12, marginTop: 2 },
  menuGroup: { marginBottom: 20 },
  menuGroupLabel: { fontSize: 11, letterSpacing: 0.8, marginBottom: 8 },
  menuGroupItems: { borderRadius: 16, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  menuItem: {
    flexDirection: 'row', alignItems: 'center', padding: 16,
    borderBottomWidth: StyleSheet.hairlineWidth, gap: 12, minHeight: 52,
  },
  menuIcon: { fontSize: 20, width: 28, textAlign: 'center' },
  menuLabel: { flex: 1, fontSize: 16 },
  menuChevron: { fontSize: 20 },
  donationCard: { borderRadius: 18, borderWidth: 1, padding: 20, marginBottom: 24 },
  donationTitle: { fontSize: 20, marginBottom: 10 },
  donationBody: { fontSize: 14, lineHeight: 22, marginBottom: 16 },
  donateBtn: { height: 48, borderRadius: 12, justifyContent: 'center', alignItems: 'center', marginBottom: 10 },
  donateBtnText: { color: '#FFFFFF', fontSize: 14 },
  donateBtnSecondary: {
    height: 44, borderRadius: 12, borderWidth: 1.5,
    justifyContent: 'center', alignItems: 'center', marginBottom: 14,
  },
  donateBtnSecondaryText: { fontSize: 14 },
  donationNote: { fontSize: 12, lineHeight: 18, textAlign: 'center' },
  missionVerse: { fontSize: 14, lineHeight: 22, textAlign: 'center', marginBottom: 4 },
  missionRef: { fontSize: 12, textAlign: 'center' },
});
