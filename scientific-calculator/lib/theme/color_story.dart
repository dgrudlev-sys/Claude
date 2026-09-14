import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Bang Wong / IBM palette. These hues stay separable under the named
/// deficiencies; we never use green vs red as the only cue.
const _wongYellow = Color(0xFFF0E442);
const _wongSky = Color(0xFF56B4E9);
const _wongRoyal = Color(0xFF0072B2);
const _wongOrange = Color(0xFFE69F00);
const _wongTeal = Color(0xFF009E73);
const _wongVermillion = Color(0xFFD55E00);
const _wongPurple = Color(0xFFCC79A7);

enum ColorStoryGroup {
  nature('Nature'),
  colourVision('Colour vision');

  const ColorStoryGroup(this.label);
  final String label;
}

/// Looks. Each story is an 80 / 15 / 5 split:
/// 80 the field (scaffold, display, number keys), 15 supporting
/// surfaces (operators, cards), 5 a single highlight (equals, focus).
enum ColorStory {
  panther(
    label: 'Panther',
    description: 'Night black, silver fur, a gold eye.',
    group: ColorStoryGroup.nature,
  ),
  africa(
    label: 'Africa',
    description: 'Umber dusk, baobab bark, laterite earth.',
    group: ColorStoryGroup.nature,
  ),
  parrot(
    label: 'Parrot',
    description: 'Canopy shade, leaf, a macaw-gold nape.',
    group: ColorStoryGroup.nature,
  ),
  stone(
    label: 'Stone',
    description: 'Charcoal, graphite, a white edge.',
    group: ColorStoryGroup.nature,
  ),
  turtle(
    label: 'Turtle shell',
    description: 'Olive scutes, sea-green, warm horn.',
    group: ColorStoryGroup.nature,
  ),
  savanna(
    label: 'Savanna',
    description: 'Dry-season dusk, acacia, sun.',
    group: ColorStoryGroup.nature,
  ),
  reef(
    label: 'Coral reef',
    description: 'Deep water, lagoon, one coral flash.',
    group: ColorStoryGroup.nature,
  ),
  protanopia(
    label: 'Protanopia',
    description: 'Red-blind. Yellow on blue; reds are not used as signals.',
    group: ColorStoryGroup.colourVision,
  ),
  protanomaly(
    label: 'Protanomaly',
    description: 'Red-weak. Orange highlight, sky operators.',
    group: ColorStoryGroup.colourVision,
  ),
  deuteranopia(
    label: 'Deuteranopia',
    description: 'Green-blind. Yellow on sky; no green vs red.',
    group: ColorStoryGroup.colourVision,
  ),
  deuteranomaly(
    label: 'Deuteranomaly',
    description: 'Green-weak. Orange highlight, royal operators.',
    group: ColorStoryGroup.colourVision,
  ),
  tritanopia(
    label: 'Tritanopia',
    description: 'Blue-blind. Vermillion on teal; no blue vs yellow.',
    group: ColorStoryGroup.colourVision,
  ),
  tritanomaly(
    label: 'Tritanomaly',
    description: 'Blue-weak. Purple highlight, vermillion operators.',
    group: ColorStoryGroup.colourVision,
  ),
  achromatopsia(
    label: 'Achromatopsia',
    description: 'No colour. Five grey steps; meaning is luminance and labels.',
    group: ColorStoryGroup.colourVision,
  ),
  blueCone(
    label: 'Blue-cone',
    description: 'Only blue cones. Black field, sky highlight, no yellow.',
    group: ColorStoryGroup.colourVision,
  );

  const ColorStory({
    required this.label,
    required this.description,
    required this.group,
  });

  final String label;
  final String description;
  final ColorStoryGroup group;

  static Iterable<ColorStory> inGroup(ColorStoryGroup group) =>
      values.where((s) => s.group == group);

  /// 80% field.
  Color get dominant => tokens.dominant;

  /// 15% supporting.
  Color get secondary => tokens.secondary;

  /// 5% highlight.
  Color get accent => tokens.accent;

  ColorStoryTokens get tokens => switch (this) {
        ColorStory.panther => const ColorStoryTokens(
            dominant: Color(0xFF0C0C0E),
            secondary: Color(0xFF2B2E33),
            accent: Color(0xFFC9A227),
            onDominant: Color(0xFFF3EFE6),
            numberKey: Color(0xFF16161A),
            functionKey: Color(0xFF1F2226),
            operatorKey: Color(0xFF2B2E33),
            actionKey: Color(0xFF32363C),
            clearKey: Color(0xFF9B2C2C),
            selectedBorder: Color(0xFFF3EFE6),
            cardFill: Color(0xFF1A1B20),
            cardHairline: Color(0x59363A42),
          ),
        ColorStory.africa => const ColorStoryTokens(
            dominant: Color(0xFF1A110C),
            secondary: Color(0xFF5C3A28),
            accent: Color(0xFFE0703A),
            onDominant: Color(0xFFF6EBDD),
            numberKey: Color(0xFF241810),
            functionKey: Color(0xFF2A1C14),
            operatorKey: Color(0xFF3D281C),
            actionKey: Color(0xFF4A3020),
            clearKey: Color(0xFFA33B2A),
            selectedBorder: Color(0xFFF6EBDD),
            cardFill: Color(0xFF261810),
            cardHairline: Color(0x595C3A28),
          ),
        ColorStory.parrot => const ColorStoryTokens(
            dominant: Color(0xFF0C1610),
            secondary: Color(0xFF1F3D2C),
            accent: Color(0xFFE3B422),
            onDominant: Color(0xFFEAF3E8),
            numberKey: Color(0xFF142018),
            functionKey: Color(0xFF163024),
            operatorKey: Color(0xFF245C3A),
            actionKey: Color(0xFF2A4A38),
            clearKey: Color(0xFFA12A2A),
            selectedBorder: Color(0xFFEAF3E8),
            cardFill: Color(0xFF15241A),
            cardHairline: Color(0x591F3D2C),
          ),
        ColorStory.stone => const ColorStoryTokens(
            dominant: Color(0xFF111111),
            secondary: Color(0xFF3A3A3A),
            accent: Color(0xFFEDEDED),
            onDominant: Color(0xFFF5F5F5),
            numberKey: Color(0xFF1C1C1C),
            functionKey: Color(0xFF222222),
            operatorKey: Color(0xFF2E2E2E),
            actionKey: Color(0xFF444444),
            clearKey: Color(0xFF5C5C5C),
            selectedBorder: Color(0xFFFFFFFF),
            cardFill: Color(0xFF1A1A1A),
            cardHairline: Color(0x594A4A4A),
            equalsOnAccent: Colors.black,
          ),
        ColorStory.turtle => const ColorStoryTokens(
            dominant: Color(0xFF161810),
            secondary: Color(0xFF3A3F2A),
            accent: Color(0xFFC4A46A),
            onDominant: Color(0xFFEFE8D6),
            numberKey: Color(0xFF1E2216),
            functionKey: Color(0xFF22281C),
            operatorKey: Color(0xFF2C4A3A),
            actionKey: Color(0xFF3D4A32),
            clearKey: Color(0xFF8B3A2A),
            selectedBorder: Color(0xFFEFE8D6),
            cardFill: Color(0xFF1E2418),
            cardHairline: Color(0x593A3F2A),
          ),
        ColorStory.savanna => const ColorStoryTokens(
            dominant: Color(0xFF1C1810),
            secondary: Color(0xFF4A3C24),
            accent: Color(0xFFE6B84D),
            onDominant: Color(0xFFF5ECD8),
            numberKey: Color(0xFF262014),
            functionKey: Color(0xFF2A2418),
            operatorKey: Color(0xFF5A4A28),
            actionKey: Color(0xFF6B5428),
            clearKey: Color(0xFFB03A28),
            selectedBorder: Color(0xFFF5ECD8),
            cardFill: Color(0xFF262014),
            cardHairline: Color(0x594A3C24),
          ),
        ColorStory.reef => const ColorStoryTokens(
            dominant: Color(0xFF081422),
            secondary: Color(0xFF1A3A52),
            accent: Color(0xFFE07A6C),
            onDominant: Color(0xFFE8F4F6),
            numberKey: Color(0xFF0E1C30),
            functionKey: Color(0xFF122838),
            operatorKey: Color(0xFF1F5C66),
            actionKey: Color(0xFF245060),
            clearKey: Color(0xFFB03A3A),
            selectedBorder: Color(0xFF7EC8C4),
            cardFill: Color(0xFF0E1C30),
            cardHairline: Color(0x591A3A52),
          ),
        ColorStory.protanopia => const ColorStoryTokens(
            dominant: Color(0xFF050505),
            secondary: _wongRoyal,
            accent: _wongYellow,
            onDominant: Color(0xFFFFFFFF),
            numberKey: Color(0xFF141414),
            functionKey: Color(0xFF1C1C1C),
            operatorKey: _wongRoyal,
            actionKey: Color(0xFF003D63),
            clearKey: Color(0xFF4A5568),
            selectedBorder: Color(0xFFFFFFFF),
            cardFill: Color(0xFF121212),
            cardHairline: Color(0x59FFFFFF),
            errorForeground: _wongYellow,
          ),
        ColorStory.protanomaly => const ColorStoryTokens(
            dominant: Color(0xFF0A0A0C),
            secondary: _wongSky,
            accent: _wongOrange,
            onDominant: Color(0xFFFFFFFF),
            numberKey: Color(0xFF16161A),
            functionKey: Color(0xFF1E1E24),
            operatorKey: _wongSky,
            actionKey: Color(0xFF2A6A8C),
            clearKey: Color(0xFF5A6570),
            selectedBorder: Color(0xFFFFFFFF),
            cardFill: Color(0xFF141418),
            cardHairline: Color(0x5956B4E9),
            errorForeground: _wongYellow,
          ),
        ColorStory.deuteranopia => const ColorStoryTokens(
            dominant: Color(0xFF08080A),
            secondary: _wongSky,
            accent: _wongYellow,
            onDominant: Color(0xFFFFFFFF),
            numberKey: Color(0xFF141418),
            functionKey: Color(0xFF1C1C22),
            operatorKey: _wongSky,
            actionKey: Color(0xFF2A5A78),
            clearKey: Color(0xFF4A5460),
            selectedBorder: Color(0xFFFFFFFF),
            cardFill: Color(0xFF121218),
            cardHairline: Color(0x5956B4E9),
            errorForeground: _wongYellow,
          ),
        ColorStory.deuteranomaly => const ColorStoryTokens(
            dominant: Color(0xFF0A0C10),
            secondary: _wongRoyal,
            accent: _wongOrange,
            onDominant: Color(0xFFFFFFFF),
            numberKey: Color(0xFF141820),
            functionKey: Color(0xFF1A2030),
            operatorKey: _wongRoyal,
            actionKey: Color(0xFF003D63),
            clearKey: Color(0xFF4A5568),
            selectedBorder: Color(0xFFFFFFFF),
            cardFill: Color(0xFF12161C),
            cardHairline: Color(0x590072B2),
            errorForeground: _wongYellow,
          ),
        ColorStory.tritanopia => const ColorStoryTokens(
            dominant: Color(0xFF120A08),
            secondary: _wongTeal,
            accent: _wongVermillion,
            onDominant: Color(0xFFF7F0EA),
            numberKey: Color(0xFF1C1210),
            functionKey: Color(0xFF241816),
            operatorKey: _wongTeal,
            actionKey: Color(0xFF0A5A48),
            clearKey: Color(0xFF5A4A48),
            selectedBorder: Color(0xFFF7F0EA),
            cardFill: Color(0xFF1A100E),
            cardHairline: Color(0x59009E73),
            equalsOnAccent: Colors.white,
            errorForeground: _wongVermillion,
          ),
        ColorStory.tritanomaly => const ColorStoryTokens(
            dominant: Color(0xFF140C0C),
            secondary: _wongVermillion,
            accent: _wongPurple,
            onDominant: Color(0xFFF7F0EA),
            numberKey: Color(0xFF1C1010),
            functionKey: Color(0xFF241414),
            operatorKey: _wongVermillion,
            actionKey: Color(0xFF8A3A00),
            clearKey: Color(0xFF5A4848),
            selectedBorder: Color(0xFFF7F0EA),
            cardFill: Color(0xFF1A1010),
            cardHairline: Color(0x59D55E00),
            equalsOnAccent: Colors.black,
            errorForeground: _wongVermillion,
          ),
        ColorStory.achromatopsia => const ColorStoryTokens(
            dominant: Color(0xFF000000),
            secondary: Color(0xFF5A5A5A),
            accent: Color(0xFFFFFFFF),
            onDominant: Color(0xFFF5F5F5),
            numberKey: Color(0xFF1A1A1A),
            functionKey: Color(0xFF2A2A2A),
            operatorKey: Color(0xFF5A5A5A),
            actionKey: Color(0xFF6E6E6E),
            clearKey: Color(0xFF3D3D3D),
            selectedBorder: Color(0xFFFFFFFF),
            cardFill: Color(0xFF141414),
            cardHairline: Color(0x59FFFFFF),
            equalsOnAccent: Colors.black,
            errorForeground: Color(0xFFFFFFFF),
          ),
        ColorStory.blueCone => const ColorStoryTokens(
            dominant: Color(0xFF000000),
            secondary: Color(0xFF1A2A40),
            accent: _wongSky,
            onDominant: Color(0xFFFFFFFF),
            numberKey: Color(0xFF0C1018),
            functionKey: Color(0xFF141C28),
            operatorKey: Color(0xFF2A4A6A),
            actionKey: Color(0xFF3A5A7A),
            clearKey: Color(0xFF2A2A32),
            selectedBorder: Color(0xFFB0D4F0),
            cardFill: Color(0xFF0C141C),
            cardHairline: Color(0x5956B4E9),
            equalsOnAccent: Colors.black,
            errorForeground: Color(0xFFFFFFFF),
          ),
      };

  CalculatorPalette get keypad {
    final t = tokens;
    return CalculatorPalette(
      numberButton: t.numberKey,
      operatorButton: t.operatorKey,
      functionButton: t.functionKey,
      actionButton: t.actionKey,
      clearButton: t.clearKey,
      equalsButton: t.accent,
      onButton: t.onDominant,
      displayBackground: t.dominant,
      selectedBorder: t.selectedBorder,
      errorForeground: t.errorForeground,
      equalsOnButton: t.equalsOnAccent,
    );
  }
}

class ColorStoryTokens {
  const ColorStoryTokens({
    required this.dominant,
    required this.secondary,
    required this.accent,
    required this.onDominant,
    required this.numberKey,
    required this.functionKey,
    required this.operatorKey,
    required this.actionKey,
    required this.clearKey,
    required this.selectedBorder,
    required this.cardFill,
    required this.cardHairline,
    this.equalsOnAccent = Colors.black,
    this.errorForeground = const Color(0xFFF0E442),
  });

  final Color dominant;
  final Color secondary;
  final Color accent;
  final Color onDominant;
  final Color numberKey;
  final Color functionKey;
  final Color operatorKey;
  final Color actionKey;
  final Color clearKey;
  final Color selectedBorder;
  final Color cardFill;
  final Color cardHairline;
  final Color equalsOnAccent;
  final Color errorForeground;
}
