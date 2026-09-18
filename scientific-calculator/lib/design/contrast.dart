/// WCAG contrast, so the palettes can be checked rather than asserted.
///
/// The app already shipped a theme whose comment claimed WCAG AAA and
/// whose operator keys measured 1.6:1. A comment cannot be wrong loudly;
/// a test can. This exists so every colour pairing in every appearance is
/// measured on every run.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Relative luminance, per WCAG 2.2.
double relativeLuminance(Color colour) {
  double channel(double value) =>
      value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(colour.r) +
      0.7152 * channel(colour.g) +
      0.0722 * channel(colour.b);
}

/// The contrast ratio between two colours, from 1:1 to 21:1.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// What WCAG asks of a given pairing.
///
/// The threshold depends on how large the text is: large text carries
/// enough stroke weight to stay legible at a lower ratio. Non-text
/// elements — an icon, a border, a focus ring — sit at the same 3:1 as
/// large text.
enum ContrastRequirement {
  /// Body text and anything below 18pt regular or 14pt bold.
  normalText(4.5, 'normal text'),

  /// 18pt regular and up, or 14pt bold and up.
  largeText(3.0, 'large text'),

  /// Icons, borders, separators, focus rings.
  nonText(3.0, 'non-text element'),

  /// The stricter bar, which the high-contrast appearances are held to.
  enhanced(7.0, 'enhanced (AAA)');

  const ContrastRequirement(this.ratio, this.description);

  final double ratio;
  final String description;
}

bool meetsContrast(
  Color foreground,
  Color background, {
  ContrastRequirement requirement = ContrastRequirement.normalText,
}) =>
    contrastRatio(foreground, background) >= requirement.ratio;

/// A human-readable grade, for test failure messages and for the
/// developer-facing contrast report in settings.
String contrastGrade(double ratio) {
  if (ratio >= 7) return 'AAA';
  if (ratio >= 4.5) return 'AA';
  if (ratio >= 3) return 'AA large text only';
  return 'fails WCAG';
}
