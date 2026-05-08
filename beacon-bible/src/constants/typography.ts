export const fontFamilies = {
  // Serif — warm, classic, reading body text
  serif: {
    regular: 'Lora_400Regular',
    italic:  'Lora_400Regular_Italic',
    bold:    'Lora_700Bold',
    boldItalic: 'Lora_700Bold_Italic',
  },
  // Sans-serif — clean UI chrome
  sans: {
    regular: 'Inter_400Regular',
    medium:  'Inter_500Medium',
    semiBold: 'Inter_600SemiBold',
    bold:    'Inter_700Bold',
  },
  // OpenDyslexic — accessibility option
  dyslexic: {
    regular: 'OpenDyslexic_400Regular',
    bold:    'OpenDyslexic_700Bold',
  },
} as const;

// Base scale — multiplied by user's accessibility fontSize multiplier
export const fontSizes = {
  xs:   12,
  sm:   14,
  base: 16,
  md:   18,
  lg:   20,
  xl:   24,
  '2xl': 28,
  '3xl': 32,
  '4xl': 40,
} as const;

// Reader-specific scale — separate from UI scale
export const readerFontSizes = {
  small:       16,
  default:     19,
  large:       23,
  extraLarge:  28,
  huge:        34,
} as const;

export const lineHeights = {
  tight:   1.25,
  normal:  1.5,
  relaxed: 1.75,
  loose:   2.0,
} as const;

export const letterSpacing = {
  tight:  -0.5,
  normal:  0,
  wide:    0.5,
  wider:   1.0,
} as const;

export type FontFamily = 'serif' | 'sans' | 'dyslexic';
export type ReaderFontSize = keyof typeof readerFontSizes;
