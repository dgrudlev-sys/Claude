import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { View, Text, StyleSheet } from 'react-native';
import { useAccessibilitySettings } from '@/hooks/useAccessibilitySettings';
import type { MainTabParamList } from '@/types/navigation.types';

// Screens
import HomeScreen from '@/screens/reader/HomeScreen';
import ReaderScreen from '@/screens/reader/ReaderScreen';
import BookPickerScreen from '@/screens/reader/BookPickerScreen';
import ChapterPickerScreen from '@/screens/reader/ChapterPickerScreen';
import SearchScreen from '@/screens/search/SearchScreen';
import PlansScreen from '@/screens/plans/PlansScreen';
import ProfileScreen from '@/screens/profile/ProfileScreen';
import AccessibilitySettingsScreen from '@/screens/profile/AccessibilitySettingsScreen';
import AppearanceSettingsScreen from '@/screens/profile/AppearanceSettingsScreen';
import NotificationSettingsScreen from '@/screens/profile/NotificationSettingsScreen';

const Tab = createBottomTabNavigator<MainTabParamList>();
const ReadStack = createNativeStackNavigator();
const SearchStack = createNativeStackNavigator();
const PlansStack = createNativeStackNavigator();
const ProfileStack = createNativeStackNavigator();

function ReadStackNavigator() {
  return (
    <ReadStack.Navigator screenOptions={{ headerShown: false }}>
      <ReadStack.Screen name="Home" component={HomeScreen} />
      <ReadStack.Screen name="BookPicker" component={BookPickerScreen} />
      <ReadStack.Screen name="ChapterPicker" component={ChapterPickerScreen} />
      <ReadStack.Screen name="Reader" component={ReaderScreen} />
    </ReadStack.Navigator>
  );
}

function SearchStackNavigator() {
  return (
    <SearchStack.Navigator screenOptions={{ headerShown: false }}>
      <SearchStack.Screen name="Search" component={SearchScreen} />
    </SearchStack.Navigator>
  );
}

function PlansStackNavigator() {
  return (
    <PlansStack.Navigator screenOptions={{ headerShown: false }}>
      <PlansStack.Screen name="PlansHome" component={PlansScreen} />
    </PlansStack.Navigator>
  );
}

function ProfileStackNavigator() {
  return (
    <ProfileStack.Navigator screenOptions={{ headerShown: false }}>
      <ProfileStack.Screen name="Profile" component={ProfileScreen} />
      <ProfileStack.Screen name="AccessibilitySettings" component={AccessibilitySettingsScreen} />
      <ProfileStack.Screen name="AppearanceSettings" component={AppearanceSettingsScreen} />
      <ProfileStack.Screen name="NotificationSettings" component={NotificationSettingsScreen} />
    </ProfileStack.Navigator>
  );
}

function TabIcon({ name, focused, color }: { name: string; focused: boolean; color: string }) {
  const icons: Record<string, string> = {
    ReadTab: '📖', SearchTab: '🔍', PlansTab: '📋', ProfileTab: '👤',
  };
  return (
    <Text style={{ fontSize: 22, opacity: focused ? 1 : 0.5 }}
      accessibilityLabel={name.replace('Tab', '')}>
      {icons[name] ?? '•'}
    </Text>
  );
}

export default function MainTabNavigator() {
  const { theme } = useAccessibilitySettings();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarStyle: {
          backgroundColor: theme.tabBarBackground,
          borderTopColor: theme.border,
          borderTopWidth: StyleSheet.hairlineWidth,
          paddingBottom: 4,
          height: 60,
        },
        tabBarActiveTintColor: theme.tabBarActive,
        tabBarInactiveTintColor: theme.tabBarInactive,
        tabBarIcon: ({ focused, color }) => (
          <TabIcon name={route.name} focused={focused} color={color} />
        ),
        tabBarLabelStyle: { fontSize: 11, fontWeight: '500', marginBottom: 2 },
      })}
    >
      <Tab.Screen name="ReadTab" component={ReadStackNavigator} options={{ title: 'Read' }} />
      <Tab.Screen name="SearchTab" component={SearchStackNavigator} options={{ title: 'Search' }} />
      <Tab.Screen name="PlansTab" component={PlansStackNavigator} options={{ title: 'Plans' }} />
      <Tab.Screen name="ProfileTab" component={ProfileStackNavigator} options={{ title: 'Profile' }} />
    </Tab.Navigator>
  );
}
