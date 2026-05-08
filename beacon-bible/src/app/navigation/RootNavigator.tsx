import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { usePreferencesStore } from '@/store/preferences.store';
import type { RootStackParamList } from '@/types/navigation.types';

const Stack = createNativeStackNavigator<RootStackParamList>();

// Lazy imports keep the bundle split clean
const OnboardingNavigator = React.lazy(() => import('./OnboardingNavigator'));
const MainTabNavigator = React.lazy(() => import('./MainTabNavigator'));

const linking = {
  prefixes: ['beaconbible://', 'https://beaconbible.app'],
  config: {
    screens: {
      Main: {
        screens: {
          ReadTab: {
            screens: {
              Reader: 'read/:bookCode/:chapter',
            },
          },
          SearchTab: {
            screens: {
              Search: 'search',
            },
          },
        },
      },
    },
  },
};

export default function RootNavigator() {
  const hasCompletedOnboarding = usePreferencesStore(s => s.hasCompletedOnboarding);

  return (
    <NavigationContainer linking={linking}>
      <Stack.Navigator screenOptions={{ headerShown: false, animation: 'fade' }}>
        {hasCompletedOnboarding ? (
          <Stack.Screen name="Main" component={MainTabNavigator} />
        ) : (
          <Stack.Screen name="Onboarding" component={OnboardingNavigator} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
