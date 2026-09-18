/// The design tokens every surface in the app is built from.
///
/// Two rules from Apple's Human Interface Guidelines shape this file, and
/// both are enforced by structure rather than by discipline:
///
/// **Semantic over literal.** Nothing outside this file names a colour.
/// Widgets ask for a role — `label`, `accent`, `separator` — and the role
/// resolves differently in light, dark and increased-contrast appearances.
/// A hardcoded hex in a widget cannot adapt, and the app already had the
/// bug that proves it: the high-contrast theme painted white text on an
/// amber key at 1.6:1, because the surface and its text were chosen in
/// two different places.
///
/// **A surface is never separable from its text.** [SurfacePair] carries
/// both, so no caller can pick one and forget the other. That single
/// decision makes the contrast bug above impossible to write again.
library;

import 'package:flutter/widgets.dart';

/// A background and the foreground that is guaranteed to be legible on it.
@immutable
class SurfacePair {
  const SurfacePair(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static SurfacePair lerp(SurfacePair a, SurfacePair b, double t) => SurfacePair(
        Color.lerp(a.background, b.background, t)!,
        Color.lerp(a.foreground, b.foreground, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is SurfacePair &&
      other.background == background &&
      other.foreground == foreground;

  @override
  int get hashCode => Object.hash(background, foreground);
}

/// Which visual appearance a palette is for.
///
/// Light is listed first because it is the default. Apple's interfaces are
/// light unless the user or the moment asks otherwise, and an app that is
/// only ever dark has taken that choice away.
enum Appearance { light, dark, lightHighContrast, darkHighContrast }

extension AppearanceTraits on Appearance {
  bool get isDark =>
      this == Appearance.dark || this == Appearance.darkHighContrast;

  bool get isHighContrast =>
      this == Appearance.lightHighContrast ||
      this == Appearance.darkHighContrast;

  /// The matching appearance once the user turns Increase Contrast on.
  Appearance get highContrast =>
      isDark ? Appearance.darkHighContrast : Appearance.lightHighContrast;
}

/// The 8-point grid.
///
/// Apple lays out on multiples of 8, with 4 available for tight pairings.
/// Off-grid spacing is the most common reason an interface feels
/// approximately right rather than right.
abstract final class Space {
  /// Half-step, for tight pairings only.
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// The side margin on a phone in portrait.
  static const double phoneMargin = 16;

  /// The side margin on a tablet, which HIG sets higher.
  static const double tabletMargin = 20;

  /// Past this width a single column of content becomes tiring to read,
  /// so content is centred rather than stretched.
  static const double readableWidth = 560;
}

abstract final class Radii {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
}

/// Apple's hardest layout constraint: every interactive element must be at
/// least this tall and wide, whatever it looks like.
abstract final class TouchTarget {
  static const double minimum = 44;

  /// What this app uses. Above the 44 floor because a calculator key is
  /// pressed repeatedly and at speed.
  static const double comfortable = 48;
}

/// Motion budget for a utility surface.
///
/// A calculator is somewhere a person comes to get something done, so
/// motion should get out of the way rather than comment on the task. Every
/// duration here collapses to zero when the system asks for reduced
/// motion — a cross-fade or a cut, never a slide that crosses the screen.
abstract final class Motion {
  static const Duration instant = Duration.zero;
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 240);

  /// Never longer than this on a utility screen.
  static const Duration longest = Duration(milliseconds: 300);

  static Duration resolve(Duration wanted, {required bool reduceMotion}) =>
      reduceMotion ? instant : wanted;
}

/// The colour roles, resolved for one appearance.
///
/// The accent is deliberately the only chromatic colour in the set.
/// Everything else is neutral, which is what lets the one accent actually
/// point at something.
@immutable
class Palette {
  const Palette({
    required this.appearance,
    required this.background,
    required this.groupedBackground,
    required this.elevatedSurface,
    required this.label,
    required this.secondaryLabel,
    required this.separator,
    required this.accent,
    required this.onAccent,
    required this.keyNumber,
    required this.keyOperator,
    required this.keyFunction,
    required this.keyAction,
    required this.keyEquals,
    required this.display,
    required this.errorSurface,
  });

  final Appearance appearance;

  /// The page behind everything.
  final Color background;

  /// Behind a group of controls, one step away from [background].
  final Color groupedBackground;

  /// A surface that sits above the page. In dark appearances this is
  /// *lighter* than the background, never darker — dark mode dims, it does
  /// not invert.
  final Color elevatedSurface;

  final Color label;
  final Color secondaryLabel;
  final Color separator;

  /// The single accent. One colour, doing all the pointing.
  final Color accent;
  final Color onAccent;

  final SurfacePair keyNumber;
  final SurfacePair keyOperator;
  final SurfacePair keyFunction;
  final SurfacePair keyAction;
  final SurfacePair keyEquals;
  final SurfacePair display;

  /// A failed calculation or an invalid entry. Chromatic like the accent,
  /// because an error is meaning rather than decoration — but it never
  /// carries the message alone: an error always has words beside it.
  final SurfacePair errorSurface;

  /// Every surface/foreground pairing in this palette, for the tests that
  /// check contrast. Anything added above belongs here too, or it ships
  /// unchecked.
  Map<String, SurfacePair> get allPairs => {
        'body text': SurfacePair(background, label),
        'secondary text': SurfacePair(background, secondaryLabel),
        'grouped body text': SurfacePair(groupedBackground, label),
        'elevated text': SurfacePair(elevatedSurface, label),
        'accent': SurfacePair(accent, onAccent),
        'number key': keyNumber,
        'operator key': keyOperator,
        'function key': keyFunction,
        'action key': keyAction,
        'equals key': keyEquals,
        'display': display,
        'error': errorSurface,
      };

  static Palette of(Appearance appearance) => switch (appearance) {
        Appearance.light => _light,
        Appearance.dark => _dark,
        Appearance.lightHighContrast => _lightHighContrast,
        Appearance.darkHighContrast => _darkHighContrast,
      };
}

// The palettes. These are the only literal colours in the application.

const _ink = Color(0xFF1A1714);
const _paper = Color(0xFFF7F5F2);

const _light = Palette(
  appearance: Appearance.light,
  background: _paper,
  groupedBackground: Color(0xFFEDE9E3),
  elevatedSurface: Color(0xFFFFFFFF),
  label: _ink,
  secondaryLabel: Color(0xFF5C554D),
  separator: Color(0xFFD5CFC6),
  accent: Color(0xFF8A4B00),
  onAccent: Color(0xFFFFFFFF),
  keyNumber: SurfacePair(Color(0xFFFFFFFF), _ink),
  keyOperator: SurfacePair(Color(0xFFE4DDD3), _ink),
  keyFunction: SurfacePair(Color(0xFFEDE9E3), _ink),
  keyAction: SurfacePair(Color(0xFFDCD3C6), _ink),
  keyEquals: SurfacePair(Color(0xFF8A4B00), Color(0xFFFFFFFF)),
  display: SurfacePair(_paper, _ink),
  errorSurface: SurfacePair(Color(0xFFF7F5F2), Color(0xFF9B1C1C)),
);

const _dark = Palette(
  appearance: Appearance.dark,
  background: Color(0xFF16140F),
  groupedBackground: Color(0xFF1E1C17),
  // Lighter than the background: elevation reads as light in dark mode.
  elevatedSurface: Color(0xFF2A2721),
  label: Color(0xFFF5F1EA),
  secondaryLabel: Color(0xFFB5ADA1),
  separator: Color(0xFF3A362F),
  accent: Color(0xFFF0A23C),
  onAccent: Color(0xFF1A1714),
  keyNumber: SurfacePair(Color(0xFF35322E), Color(0xFFF5F1EA)),
  keyOperator: SurfacePair(Color(0xFF4A4540), Color(0xFFF5F1EA)),
  keyFunction: SurfacePair(Color(0xFF2C2A27), Color(0xFFF5F1EA)),
  keyAction: SurfacePair(Color(0xFF574E3F), Color(0xFFF5F1EA)),
  keyEquals: SurfacePair(Color(0xFFF0A23C), Color(0xFF1A1714)),
  display: SurfacePair(Color(0xFF16140F), Color(0xFFF5F1EA)),
  errorSurface: SurfacePair(Color(0xFF16140F), Color(0xFFFF9A8A)),
);

/// Increase Contrast, light. Not a different design — the same design with
/// the neutrals pushed apart and the accent darkened.
const _lightHighContrast = Palette(
  appearance: Appearance.lightHighContrast,
  background: Color(0xFFFFFFFF),
  groupedBackground: Color(0xFFF0EEEA),
  elevatedSurface: Color(0xFFFFFFFF),
  label: Color(0xFF000000),
  secondaryLabel: Color(0xFF3A3530),
  separator: Color(0xFF6B655C),
  accent: Color(0xFF6B3A00),
  onAccent: Color(0xFFFFFFFF),
  keyNumber: SurfacePair(Color(0xFFFFFFFF), Color(0xFF000000)),
  keyOperator: SurfacePair(Color(0xFFDBD3C7), Color(0xFF000000)),
  keyFunction: SurfacePair(Color(0xFFEFECE7), Color(0xFF000000)),
  keyAction: SurfacePair(Color(0xFFCFC4B3), Color(0xFF000000)),
  keyEquals: SurfacePair(Color(0xFF6B3A00), Color(0xFFFFFFFF)),
  display: SurfacePair(Color(0xFFFFFFFF), Color(0xFF000000)),
  errorSurface: SurfacePair(Color(0xFFFFFFFF), Color(0xFF8A0000)),
);

/// Increase Contrast, dark. True black, because it serves OLED here and
/// because this is the appearance a low-vision user reaches for.
const _darkHighContrast = Palette(
  appearance: Appearance.darkHighContrast,
  background: Color(0xFF000000),
  groupedBackground: Color(0xFF0D0D0D),
  elevatedSurface: Color(0xFF1A1A1A),
  label: Color(0xFFFFFFFF),
  secondaryLabel: Color(0xFFD8D3CB),
  separator: Color(0xFF8A857D),
  accent: Color(0xFFFFC24B),
  // Black on amber, 13:1. This is the pairing the old theme got wrong.
  onAccent: Color(0xFF000000),
  keyNumber: SurfacePair(Color(0xFF1A1A1A), Color(0xFFFFFFFF)),
  keyOperator: SurfacePair(Color(0xFF3A3A3A), Color(0xFFFFFFFF)),
  keyFunction: SurfacePair(Color(0xFF262626), Color(0xFFFFFFFF)),
  keyAction: SurfacePair(Color(0xFF4A4A4A), Color(0xFFFFFFFF)),
  keyEquals: SurfacePair(Color(0xFFFFC24B), Color(0xFF000000)),
  display: SurfacePair(Color(0xFF000000), Color(0xFFFFFFFF)),
  errorSurface: SurfacePair(Color(0xFF000000), Color(0xFFFFB3A6)),
);
