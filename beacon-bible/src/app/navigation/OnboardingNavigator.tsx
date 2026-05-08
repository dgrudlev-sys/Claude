import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import type { OnboardingStackParamList } from '@/types/navigation.types';

import WelcomeScreen from '@/screens/onboarding/WelcomeScreen';
import IntentScreen from '@/screens/onboarding/IntentScreen';
import AccessibilitySetupScreen from '@/screens/onboarding/AccessibilitySetupScreen';
import LanguagePickerScreen from '@/screens/onboarding/LanguagePickerScreen';
import TranslationPickerScreen from '@/screens/onboarding/TranslationPickerScreen';
import OnboardingCompleteScreen from '@/screens/onboarding/OnboardingCompleteScreen';

const Stack = createNativeStackNavigator<OnboardingStackParamList>();

export default function OnboardingNavigator() {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
        animation: 'slide_from_right',
        contentStyle: { backgroundColor: '#FDFAF5' },
      }}
    >
      <Stack.Screen name="Welcome" component={WelcomeScreen} />
      <Stack.Screen name="Intent" component={IntentScreen} />
      <Stack.Screen name="AccessibilitySetup" component={AccessibilitySetupScreen} />
      <Stack.Screen name="LanguagePicker" component={LanguagePickerScreen} />
      <Stack.Screen name="TranslationPicker" component={TranslationPickerScreen} />
      <Stack.Screen name="OnboardingComplete" component={OnboardingCompleteScreen} />
    </Stack.Navigator>
  );
}
