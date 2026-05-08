import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Platform } from 'react-native';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import { fontFamilies } from '@/constants/typography';

const CURATED_PLANS = [
  {
    id: 'beginnings',
    title: 'In the Beginning',
    description: 'A 30-day narrative journey through creation, covenant, and the promise of redemption.',
    days: 30, author: 'Beacon Bible Editors', tags: ['narrative', 'genesis', 'foundation'],
    emoji: '🌅',
  },
  {
    id: 'psalms-of-peace',
    title: 'Psalms of Peace',
    description: 'Fifteen psalms curated for when life feels heavy. Each day opens with a crisis and closes with rest.',
    days: 15, author: 'Beacon Bible Editors', tags: ['anxiety', 'peace', 'psalms'],
    emoji: '🕊',
  },
  {
    id: 'sermon-on-the-mount',
    title: 'The Sermon on the Mount',
    description: 'Seven days in Matthew 5–7. Each day follows the arc: the standard Jesus sets, why it matters, how to live it.',
    days: 7, author: 'Beacon Bible Editors', tags: ['jesus', 'ethics', 'matthew'],
    emoji: '⛰',
  },
  {
    id: 'paul-on-grace',
    title: "Paul on Grace",
    description: "Romans, Galatians, and Ephesians — tracing Paul's most radical claim: that grace is the whole point.",
    days: 21, author: 'Beacon Bible Editors', tags: ['grace', 'paul', 'theology'],
    emoji: '✉',
  },
];

export default function PlansScreen() {
  const { theme } = useAccessibilitySettings();

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>

        <Text style={[styles.heading, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}
          accessibilityRole="header">
          Reading Plans
        </Text>
        <Text style={[styles.subheading, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
          Narrative-arc plans crafted to go somewhere — not just daily disconnected verses.
        </Text>

        <Text style={[styles.sectionLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold }]}>
          CRAFTED PLANS
        </Text>

        {CURATED_PLANS.map(plan => (
          <TouchableOpacity
            key={plan.id}
            style={[styles.planCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
            accessibilityRole="button"
            accessibilityLabel={`${plan.title}, ${plan.days} days. ${plan.description}`}
          >
            <View style={styles.planTop}>
              <Text style={styles.planEmoji}>{plan.emoji}</Text>
              <View style={[styles.daysBadge, { backgroundColor: theme.accent + '22' }]}>
                <Text style={[styles.daysText, { color: theme.accent, fontFamily: fontFamilies.sans.semiBold }]}>
                  {plan.days} days
                </Text>
              </View>
            </View>
            <Text style={[styles.planTitle, { color: theme.textPrimary, fontFamily: fontFamilies.serif.bold }]}>
              {plan.title}
            </Text>
            <Text style={[styles.planDesc, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
              {plan.description}
            </Text>
            <Text style={[styles.planAuthor, { color: theme.textTertiary, fontFamily: fontFamilies.sans.regular }]}>
              {plan.author}
            </Text>
            <TouchableOpacity
              style={[styles.startBtn, { backgroundColor: theme.accent }]}
              accessibilityRole="button"
              accessibilityLabel={`Start ${plan.title}`}
            >
              <Text style={[styles.startBtnText, { fontFamily: fontFamilies.sans.semiBold }]}>
                Start plan
              </Text>
            </TouchableOpacity>
          </TouchableOpacity>
        ))}

        <Text style={[styles.sectionLabel, { color: theme.textTertiary, fontFamily: fontFamilies.sans.semiBold, marginTop: 32 }]}>
          COMMUNITY PLANS
        </Text>
        <View style={[styles.communityPlaceholder, { backgroundColor: theme.surfaceSecondary, borderColor: theme.border }]}>
          <Text style={[styles.communityTitle, { color: theme.textPrimary, fontFamily: fontFamilies.sans.semiBold }]}>
            Coming soon
          </Text>
          <Text style={[styles.communityDesc, { color: theme.textSecondary, fontFamily: fontFamilies.sans.regular }]}>
            Community-authored plans will appear here once our editorial review process opens. The best ones get featured alongside the crafted plans.
          </Text>
        </View>

        <View style={{ height: 48 }} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  scroll: { paddingTop: Platform.OS === 'ios' ? 64 : 24, paddingHorizontal: 24 },
  heading: { fontSize: 30, marginBottom: 8 },
  subheading: { fontSize: 14, lineHeight: 20, marginBottom: 24, opacity: 0.8 },
  sectionLabel: { fontSize: 11, letterSpacing: 0.8, marginBottom: 14 },
  planCard: {
    borderRadius: 18, borderWidth: StyleSheet.hairlineWidth,
    padding: 20, marginBottom: 16,
  },
  planTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
  planEmoji: { fontSize: 28 },
  daysBadge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 20 },
  daysText: { fontSize: 12 },
  planTitle: { fontSize: 22, marginBottom: 8 },
  planDesc: { fontSize: 14, lineHeight: 22, marginBottom: 10 },
  planAuthor: { fontSize: 12, marginBottom: 16 },
  startBtn: { height: 44, borderRadius: 12, justifyContent: 'center', alignItems: 'center' },
  startBtnText: { fontSize: 15, color: '#FFFFFF' },
  communityPlaceholder: {
    borderRadius: 16, borderWidth: StyleSheet.hairlineWidth,
    padding: 20,
  },
  communityTitle: { fontSize: 16, marginBottom: 8 },
  communityDesc: { fontSize: 14, lineHeight: 20 },
});
