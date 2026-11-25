import 'package:flutter/material.dart';

import 'app_metrics.dart';
import 'color_story.dart';
import 'layout_style.dart';
import 'type_voice.dart';
import 'vision_profile.dart';

CardThemeData _cardTheme({required Color fill, required Color hairline}) {
  return CardThemeData(
    elevation: 0,
    color: fill,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
      side: BorderSide(color: hairline, width: AppMetrics.hairline),
    ),
  );
}

enum ButtonRole { number, operatorKey, function, action, clear, equals }

/// Per-role button colors for the current theme. Kept separate from
/// [ThemeData] because the calculator keypad needs more color categories
/// than Material's default roles cover.
class CalculatorPalette extends ThemeExtension<CalculatorPalette> {
  const CalculatorPalette({
    required this.numberButton,
    required this.operatorButton,
    required this.functionButton,
    required this.actionButton,
    required this.clearButton,
    required this.equalsButton,
    required this.onButton,
    required this.displayBackground,
    required this.selectedBorder,
    required this.errorForeground,
    this.equalsOnButton,
  });

  final Color numberButton;
  final Color operatorButton;
  final Color functionButton;
  final Color actionButton;
  /// Destructive clear key. Always the letter C so color is never the only signal.
  final Color clearButton;
  final Color equalsButton;
  final Color onButton;
  final Color displayBackground;
  final Color selectedBorder;
  final Color errorForeground;
  final Color? equalsOnButton;

  Color forRole(ButtonRole role) => switch (role) {
        ButtonRole.number => numberButton,
        ButtonRole.operatorKey => operatorButton,
        ButtonRole.function => functionButton,
        ButtonRole.action => actionButton,
        ButtonRole.clear => clearButton,
        ButtonRole.equals => equalsButton,
      };

  Color labelForRole(ButtonRole role) {
    if (role == ButtonRole.equals) return equalsOnButton ?? onButton;
    if (role == ButtonRole.clear) return Colors.white;
    return onButton;
  }

  @override
  CalculatorPalette copyWith({
    Color? numberButton,
    Color? operatorButton,
    Color? functionButton,
    Color? actionButton,
    Color? clearButton,
    Color? equalsButton,
    Color? onButton,
    Color? displayBackground,
    Color? selectedBorder,
    Color? errorForeground,
    Color? equalsOnButton,
  }) {
    return CalculatorPalette(
      numberButton: numberButton ?? this.numberButton,
      operatorButton: operatorButton ?? this.operatorButton,
      functionButton: functionButton ?? this.functionButton,
      actionButton: actionButton ?? this.actionButton,
      clearButton: clearButton ?? this.clearButton,
      equalsButton: equalsButton ?? this.equalsButton,
      onButton: onButton ?? this.onButton,
      displayBackground: displayBackground ?? this.displayBackground,
      selectedBorder: selectedBorder ?? this.selectedBorder,
      errorForeground: errorForeground ?? this.errorForeground,
      equalsOnButton: equalsOnButton ?? this.equalsOnButton,
    );
  }

  @override
  CalculatorPalette lerp(ThemeExtension<CalculatorPalette>? other, double t) {
    if (other is! CalculatorPalette) return this;
    return CalculatorPalette(
      numberButton: Color.lerp(numberButton, other.numberButton, t)!,
      operatorButton: Color.lerp(operatorButton, other.operatorButton, t)!,
      functionButton: Color.lerp(functionButton, other.functionButton, t)!,
      actionButton: Color.lerp(actionButton, other.actionButton, t)!,
      clearButton: Color.lerp(clearButton, other.clearButton, t)!,
      equalsButton: Color.lerp(equalsButton, other.equalsButton, t)!,
      onButton: Color.lerp(onButton, other.onButton, t)!,
      displayBackground: Color.lerp(displayBackground, other.displayBackground, t)!,
      selectedBorder: Color.lerp(selectedBorder, other.selectedBorder, t)!,
      errorForeground: Color.lerp(errorForeground, other.errorForeground, t)!,
      equalsOnButton: Color.lerp(equalsOnButton, other.equalsOnButton, t),
    );
  }
}

/// Builds the [ThemeData] for layout, vision, colour story, and type.
ThemeData buildAppTheme(
  LayoutStyle style, {
  VisionProfile vision = VisionProfile.standard,
  ColorStory story = ColorStory.panther,
  TypeVoice voice = TypeVoice.laboratory,
}) {
  final highContrast = vision == VisionProfile.highContrastColorBlind || style == LayoutStyle.accessible;
  final theme = highContrast ? _highContrastTheme() : _storyTheme(story);
  return _withType(theme, voice);
}

ThemeData _highContrastTheme() {
  // Wong palette on pure black: yellow equals (F0E442), sky-blue operators
  // (56B4E9), royal-blue selected border (0072B2). White text ≥ 7:1 AAA.
  // Errors use a warning icon + the word "Error" — not red vs green.
  const yellow = Color(0xFFF0E442);
  const sky = Color(0xFF56B4E9);
  const royal = Color(0xFF0072B2);
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: yellow,
      secondary: sky,
      surface: Colors.black,
      onSurface: Colors.white,
      error: yellow,
      onError: Colors.black,
    ),
    visualDensity: VisualDensity.comfortable,
    cardTheme: _cardTheme(fill: const Color(0xFF111111), hairline: const Color(0x59FFFFFF)),
    extensions: const [
      CalculatorPalette(
        numberButton: Color(0xFF111111),
        operatorButton: sky,
        functionButton: Color(0xFF1A1A1A),
        actionButton: Color(0xFF2A2A2A),
        // Dark red + the letter C — color-blind users still read the label.
        clearButton: Color(0xFFB71C1C),
        equalsButton: yellow,
        onButton: Colors.white,
        displayBackground: Colors.black,
        selectedBorder: royal,
        errorForeground: yellow,
        equalsOnButton: Colors.black,
      ),
    ],
  );
}

ThemeData _storyTheme(ColorStory story) {
  final t = story.tokens;
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: t.dominant,
    colorScheme: ColorScheme.dark(
      primary: t.accent,
      secondary: t.secondary,
      surface: t.dominant,
      onSurface: t.onDominant,
      error: const Color(0xFFF0E442),
      onError: Colors.black,
    ),
    cardTheme: _cardTheme(fill: t.cardFill, hairline: t.cardHairline),
    extensions: [story.keypad],
  );
}

ThemeData _withType(ThemeData theme, TypeVoice voice) {
  final on = theme.colorScheme.onSurface;
  final surface = theme.colorScheme.surface;
  final text = theme.textTheme.apply(fontFamily: voice.uiFamily, bodyColor: on, displayColor: on);
  final titled = text.copyWith(
    titleLarge: text.titleLarge?.copyWith(
      fontFamily: voice.uiFamily,
      fontWeight: FontWeight.w700,
      height: 1.20,
      letterSpacing: -0.3,
    ),
    titleMedium: text.titleMedium?.copyWith(
      fontFamily: voice.uiFamily,
      fontWeight: FontWeight.w600,
      height: AppMetrics.titleHeight,
      letterSpacing: AppMetrics.titleTracking,
    ),
    bodyMedium: text.bodyMedium?.copyWith(
      fontFamily: voice.uiFamily,
      height: AppMetrics.bodyHeight,
    ),
    bodySmall: text.bodySmall?.copyWith(
      fontFamily: voice.uiFamily,
      height: AppMetrics.captionHeight,
      letterSpacing: AppMetrics.captionTracking,
    ),
  );
  return theme.copyWith(
    textTheme: titled,
    iconTheme: IconThemeData(color: on, size: AppMetrics.iconSize),
    primaryIconTheme: IconThemeData(color: theme.colorScheme.primary, size: AppMetrics.iconSize),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: on,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: on, size: AppMetrics.iconSize),
      actionsIconTheme: IconThemeData(color: on, size: AppMetrics.iconSize),
      titleTextStyle: titled.titleLarge?.copyWith(color: on),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: on,
        iconColor: on,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: on.withValues(alpha: 0.35),
      thickness: AppMetrics.hairline,
      space: 1,
    ),
    extensions: [
      theme.extension<CalculatorPalette>()!,
      AppTypefaces(uiFamily: voice.uiFamily, mathFamily: voice.mathFamily),
    ],
  );
}
