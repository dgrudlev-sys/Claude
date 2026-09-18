/// The type scale, and the contract that goes with it.
///
/// Apple's eleven text styles are a *contract*, not a set of sizes: pick the
/// role a piece of text plays and the system decides how big it is, using
/// the size the user asked for in Settings. Fighting that with hardcoded
/// point sizes gives up the accessibility guarantee, which is exactly what
/// this app was doing — every key used `fontSize: 18 * style.fontScale`,
/// a private scale of its own that ignored the system setting entirely.
/// Someone who had set large text everywhere on their phone got nothing.
///
/// Sizes below are the default ("Large") values. Flutter's `TextScaler`
/// applies the user's preference on top, so the numbers here are a
/// starting point rather than a result.
library;

import 'package:flutter/widgets.dart';

abstract final class AppType {
  static const largeTitle = TextStyle(fontSize: 34, height: 41 / 34, letterSpacing: 0.37);
  static const title1 = TextStyle(fontSize: 28, height: 34 / 28, letterSpacing: 0.36);
  static const title2 = TextStyle(fontSize: 22, height: 28 / 22, letterSpacing: 0.35);
  static const title3 = TextStyle(fontSize: 20, height: 25 / 20, letterSpacing: 0.38);
  static const headline =
      TextStyle(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600, letterSpacing: -0.41);
  static const body = TextStyle(fontSize: 17, height: 22 / 17, letterSpacing: -0.41);
  static const callout = TextStyle(fontSize: 16, height: 21 / 16, letterSpacing: -0.32);
  static const subheadline = TextStyle(fontSize: 15, height: 20 / 15, letterSpacing: -0.24);
  static const footnote = TextStyle(fontSize: 13, height: 18 / 13, letterSpacing: -0.08);
  static const caption1 = TextStyle(fontSize: 12, height: 16 / 12);
  static const caption2 = TextStyle(fontSize: 11, height: 13 / 11, letterSpacing: 0.07);

  /// The running result. Large by design, and the one place tracking is
  /// pulled tight — large type needs less letter-spacing to feel solid,
  /// which is the rule third-party apps break most often.
  static const displayResult =
      TextStyle(fontSize: 48, height: 1.1, fontWeight: FontWeight.w300, letterSpacing: -1.2);

  /// A calculator key. A key is a label, not body copy, so it gets the
  /// weight of a headline at the size of a title.
  static const key = TextStyle(fontSize: 20, height: 1.1, fontWeight: FontWeight.w500);

  /// Working text that has to line up in columns — matrices, tables of
  /// results — where proportional digits would wander.
  static const mono = TextStyle(fontSize: 15, height: 20 / 15, fontFamily: 'monospace');
}

/// How the app should behave given what the user has asked the system for.
///
/// Read once, near the top of the tree, and passed down — so every widget
/// answers the same question the same way, and a test can construct one
/// directly instead of faking a whole MediaQuery.
@immutable
class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.textScale = 1.0,
    this.boldText = false,
    this.highContrast = false,
    this.reduceMotion = false,
    this.screenReader = false,
  });

  factory AccessibilityPreferences.of(BuildContext context) {
    final media = MediaQuery.of(context);
    return AccessibilityPreferences(
      textScale: media.textScaler.scale(17) / 17,
      boldText: media.boldText,
      highContrast: media.highContrast,
      reduceMotion: media.disableAnimations,
      screenReader: media.accessibleNavigation,
    );
  }

  /// How much larger the user wants text, as a multiple of the default.
  /// iOS goes past 2.0 at the accessibility sizes.
  final double textScale;

  final bool boldText;
  final bool highContrast;
  final bool reduceMotion;

  /// A screen reader is driving. Affects what is worth animating and what
  /// should be grouped into a single spoken element.
  final bool screenReader;

  /// Past this point a row of label-and-value pairs has to become a
  /// column, or it will truncate. HIG is explicit that primary content
  /// must reflow rather than be cut off.
  bool get needsVerticalLayout => textScale >= 1.35;

  /// At the largest sizes a dense keypad cannot keep five columns and
  /// still show a readable label in each.
  int keypadColumns({int standard = 5}) => textScale >= 1.6 ? 4 : standard;

  /// Light weights lose their strokes at large sizes, so the floor rises
  /// as the text does.
  FontWeight resolveWeight(FontWeight wanted) {
    const steps = FontWeight.values;
    if (boldText) {
      final at = steps.indexOf(wanted);
      return steps[(at + 2).clamp(0, steps.length - 1)];
    }
    if (textScale >= 1.35 && wanted.value < FontWeight.w400.value) {
      return FontWeight.w400;
    }
    return wanted;
  }

  @override
  bool operator ==(Object other) =>
      other is AccessibilityPreferences &&
      other.textScale == textScale &&
      other.boldText == boldText &&
      other.highContrast == highContrast &&
      other.reduceMotion == reduceMotion &&
      other.screenReader == screenReader;

  @override
  int get hashCode =>
      Object.hash(textScale, boldText, highContrast, reduceMotion, screenReader);
}
