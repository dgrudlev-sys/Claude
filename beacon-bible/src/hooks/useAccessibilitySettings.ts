import { useEffect } from 'react';
import { AccessibilityInfo } from 'react-native';
import { useAccessibilityStore } from '@/store/accessibility.store';
import { colors } from '@/constants/colors';
import { fontFamilies, readerFontSizes, lineHeights } from '@/constants/typography';

export function useAccessibilitySettings() {
  const store = useAccessibilityStore();

  // Mirror OS accessibility settings on mount
  useEffect(() => {
    AccessibilityInfo.isScreenReaderEnabled().then((enabled) => {
      store.setScreenReaderActive(enabled);
    });

    AccessibilityInfo.isReduceMotionEnabled().then((enabled) => {
      if (enabled) store.setReduceMotion(true);
    });

    const screenReaderSub = AccessibilityInfo.addEventListener(
      'screenReaderChanged',
      store.setScreenReaderActive
    );
    const motionSub = AccessibilityInfo.addEventListener(
      'reduceMotionChanged',
      (enabled) => { if (enabled) store.setReduceMotion(true); }
    );

    return () => {
      screenReaderSub.remove();
      motionSub.remove();
    };
  }, []);

  const theme = colors[store.theme];

  const readerFont = store.fontFamily === 'dyslexic'
    ? fontFamilies.dyslexic
    : store.fontFamily === 'sans'
      ? fontFamilies.sans
      : fontFamilies.serif;

  const readerFontSizeValue = readerFontSizes[store.readerFontSize];
  const lineHeight = readerFontSizeValue * store.lineSpacingMultiplier;
  const fontWeight = store.boldText ? '700' : '400';
  const minTouchTarget = store.largeTouchTargets ? 56 : 44;

  return {
    theme,
    readerFont,
    readerFontSize: readerFontSizeValue,
    lineHeight,
    fontWeight,
    minTouchTarget,
    hapticsEnabled: store.hapticsEnabled,
    reduceMotion: store.reduceMotion,
    screenReaderActive: store.screenReaderActive,
    colourBlindMode: store.colourBlindMode,
    isDark: store.theme === 'dark' || store.theme === 'highContrast',
  };
}
