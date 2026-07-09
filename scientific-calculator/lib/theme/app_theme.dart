import 'package:flutter/material.dart';

import 'layout_style.dart';

enum ButtonRole { number, operatorKey, function, action, equals }

/// Per-role button colors for the current theme. Kept separate from
/// [ThemeData] because the calculator keypad needs more color categories
/// than Material's default roles cover.
class CalculatorPalette extends ThemeExtension<CalculatorPalette> {
  const CalculatorPalette({
    required this.numberButton,
    required this.operatorButton,
    required this.functionButton,
    required this.actionButton,
    required this.equalsButton,
    required this.onButton,
    required this.displayBackground,
  });

  final Color numberButton;
  final Color operatorButton;
  final Color functionButton;
  final Color actionButton;
  final Color equalsButton;
  final Color onButton;
  final Color displayBackground;

  Color forRole(ButtonRole role) => switch (role) {
        ButtonRole.number => numberButton,
        ButtonRole.operatorKey => operatorButton,
        ButtonRole.function => functionButton,
        ButtonRole.action => actionButton,
        ButtonRole.equals => equalsButton,
      };

  @override
  CalculatorPalette copyWith({
    Color? numberButton,
    Color? operatorButton,
    Color? functionButton,
    Color? actionButton,
    Color? equalsButton,
    Color? onButton,
    Color? displayBackground,
  }) {
    return CalculatorPalette(
      numberButton: numberButton ?? this.numberButton,
      operatorButton: operatorButton ?? this.operatorButton,
      functionButton: functionButton ?? this.functionButton,
      actionButton: actionButton ?? this.actionButton,
      equalsButton: equalsButton ?? this.equalsButton,
      onButton: onButton ?? this.onButton,
      displayBackground: displayBackground ?? this.displayBackground,
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
      equalsButton: Color.lerp(equalsButton, other.equalsButton, t)!,
      onButton: Color.lerp(onButton, other.onButton, t)!,
      displayBackground:
          Color.lerp(displayBackground, other.displayBackground, t)!,
    );
  }
}

/// Builds the [ThemeData] for a given [LayoutStyle]. Colors are deliberately
/// not TI's navy/silver trade dress — a warm charcoal-and-amber identity
/// keeps the familiar key layout without copying the physical device's look.
ThemeData buildAppTheme(LayoutStyle style) {
  if (style == LayoutStyle.accessible) {
    // Pure black/white/amber: maximizes contrast (WCAG AAA) for low-vision
    // users rather than matching the other skins' palette.
    const amber = Color(0xFFFFC24B);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: amber,
        surface: Colors.black,
      ),
      extensions: const [
        CalculatorPalette(
          numberButton: Color(0xFF1A1A1A),
          operatorButton: amber,
          functionButton: Color(0xFF262626),
          actionButton: Color(0xFF3A3A3A),
          equalsButton: amber,
          onButton: Colors.white,
          displayBackground: Colors.black,
        ),
      ],
    );
  }

  const charcoal = Color(0xFF1E1C1A);
  const amber = Color(0xFFE08A2C);
  const slate = Color(0xFF2C2A27);

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: charcoal,
    colorScheme: const ColorScheme.dark(
      primary: amber,
      surface: charcoal,
    ),
    extensions: const [
      CalculatorPalette(
        numberButton: Color(0xFF35322E),
        operatorButton: Color(0xFF4A4540),
        functionButton: slate,
        actionButton: Color(0xFF574E3F),
        equalsButton: amber,
        onButton: Color(0xFFF5F1EA),
        displayBackground: charcoal,
      ),
    ],
  );
}
