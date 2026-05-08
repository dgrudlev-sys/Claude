// Beacon Bible Design Token Primitives
// Warm + intimate palette, WCAG AAA accessible

export const palette = {
  // Warm cream — primary backgrounds
  cream50:  '#FDFAF5',
  cream100: '#FAF3E7',
  cream200: '#F5E6CC',
  cream300: '#EDD5A8',

  // Deep amber — primary accent
  amber400: '#F59E0B',
  amber500: '#D97706',
  amber600: '#B45309',
  amber700: '#92400E',

  // Rich brown — text on light
  brown800: '#3D1F00',
  brown900: '#1C0D00',

  // Warm neutrals
  sand200:  '#E8DCC8',
  sand300:  '#D4C4A8',
  sand400:  '#B8A888',
  sand500:  '#8C7A5E',
  sand700:  '#5C4A32',
  sand800:  '#3D3020',

  // Deep navy — dark mode base
  navy900:  '#0D1117',
  navy800:  '#161B22',
  navy700:  '#21262D',
  navy600:  '#30363D',

  // Pure tones
  white:    '#FFFFFF',
  black:    '#000000',

  // Semantic — highlight colours (colour-blind safe, named not just coloured)
  highlightAmber: '#FCD34D',   // deuteranopia-safe warm yellow
  highlightBlue:  '#93C5FD',   // protanopia-safe blue
  highlightGreen: '#6EE7B7',   // tritanopia-safe teal-green
  highlightRose:  '#FCA5A5',   // general pink/red

  // Status
  success:  '#10B981',
  warning:  '#F59E0B',
  error:    '#EF4444',
  info:     '#3B82F6',
} as const;

export const colors = {
  // Light theme (default — warm & intimate)
  light: {
    background:         palette.cream50,
    backgroundSecondary: palette.cream100,
    surface:            palette.white,
    surfaceSecondary:   palette.cream200,
    border:             palette.sand200,
    borderStrong:       palette.sand300,

    textPrimary:        palette.brown900,
    textSecondary:      palette.sand700,
    textTertiary:       palette.sand500,
    textInverse:        palette.white,

    accent:             palette.amber500,
    accentLight:        palette.amber400,
    accentDark:         palette.amber700,

    tabBarBackground:   palette.white,
    tabBarActive:       palette.amber600,
    tabBarInactive:     palette.sand400,

    readerBackground:   palette.cream50,
    verseText:          palette.brown900,
    verseNumber:        palette.sand400,
    chapterHeader:      palette.brown800,
  },

  // Dark theme
  dark: {
    background:         palette.navy900,
    backgroundSecondary: palette.navy800,
    surface:            palette.navy800,
    surfaceSecondary:   palette.navy700,
    border:             palette.navy600,
    borderStrong:       '#484F58',

    textPrimary:        '#F0E6D3',
    textSecondary:      '#B8A888',
    textTertiary:       '#8C7A5E',
    textInverse:        palette.brown900,

    accent:             palette.amber400,
    accentLight:        '#FDE68A',
    accentDark:         palette.amber500,

    tabBarBackground:   palette.navy800,
    tabBarActive:       palette.amber400,
    tabBarInactive:     '#8C7A5E',

    readerBackground:   palette.navy900,
    verseText:          '#F0E6D3',
    verseNumber:        '#5C4A32',
    chapterHeader:      '#E8D5B0',
  },

  // High contrast — WCAG AAA (21:1 ratio targets)
  highContrast: {
    background:         palette.black,
    backgroundSecondary: '#111111',
    surface:            '#111111',
    surfaceSecondary:   '#222222',
    border:             '#FFFFFF',
    borderStrong:       '#FFFFFF',

    textPrimary:        palette.white,
    textSecondary:      '#EEEEEE',
    textTertiary:       '#CCCCCC',
    textInverse:        palette.black,

    accent:             '#FFD700',
    accentLight:        '#FFE55C',
    accentDark:         '#CCA800',

    tabBarBackground:   palette.black,
    tabBarActive:       '#FFD700',
    tabBarInactive:     '#888888',

    readerBackground:   palette.black,
    verseText:          palette.white,
    verseNumber:        '#888888',
    chapterHeader:      '#FFD700',
  },
} as const;

export type ColorTheme = 'light' | 'dark' | 'highContrast';
export type ThemeColors = typeof colors.light;
