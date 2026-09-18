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

  /// A content card — a category row, a result panel, an example. The
  /// largest radius in the app, and the one that does most of the work of
  /// making a list read as a stack of cards rather than a table.
  static const double card = 18;

  /// A key on the keypad, and the icon badge beside a category name.
  static const double key = 20;

  /// Fully round: search fields, pills, the equals key.
  static const double pill = 999;
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
/// The neutrals carry the whole interface and two chromatic roles sit on
/// top of them, each with one job. [accent] — blue — is navigation and
/// action: the selected tab, the Calculate button, a link. The operator
/// column on the keypad is warm, because an arithmetic operator is not a
/// navigation affordance and colouring it the same blue would say it was.
/// Nothing else in the app is coloured at all.
///
/// [categoryTints] is the one deliberate exception: a browsable list of
/// twenty subjects needs its rows to be told apart at a glance, and a tint
/// behind an icon does that without colouring the text.
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
    required this.accentOnSurface,
    required this.accentSoft,
    required this.categoryTints,
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

  /// The accent as a *fill* — a button, a selected tab indicator — with
  /// [onAccent] written on it.
  final Color accent;
  final Color onAccent;

  /// The accent as *ink on the page*, for a link or a selected tab's
  /// label. It is a different value from [accent] in dark appearances: a
  /// blue dark enough to carry white text is too dark to read against a
  /// near-black background, and one value cannot be both.
  final Color accentOnSurface;

  /// A pale wash of the accent with the accent written on it — a selected
  /// row, a highlighted example, the badge on the primary tool.
  final SurfacePair accentSoft;

  /// Tints for the icon badge beside a category name, in the order
  /// categories are offered. A browsable list of twenty subjects needs
  /// them told apart at a glance; the tint does that behind the icon so
  /// the text stays the one neutral colour.
  final List<SurfacePair> categoryTints;

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
        'accent ink on page': SurfacePair(background, accentOnSurface),
        'accent ink on a card': SurfacePair(elevatedSurface, accentOnSurface),
        'soft accent': accentSoft,
        for (var i = 0; i < categoryTints.length; i++)
          'category tint $i': categoryTints[i],
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
//
// The neutrals are very slightly blue rather than pure grey. A warm grey
// reads as paper and a cool one as glass; a calculator is an instrument,
// so it gets glass.

const _ink = Color(0xFF0C1220);
const _paper = Color(0xFFF2F5FA);
const _white = Color(0xFFFFFFFF);

/// The operator column. Warm on purpose: an operator is not navigation,
/// and painting it the same blue as the Calculate button would say it was.
/// Dark ink on the amber rather than the white that calculators
/// traditionally use — white on this orange is 2.2:1, which is not a
/// label, it is a rumour of one.
const _amber = Color(0xFFF59E0B);

const _light = Palette(
  appearance: Appearance.light,
  background: _paper,
  groupedBackground: Color(0xFFE7ECF5),
  elevatedSurface: _white,
  label: _ink,
  secondaryLabel: Color(0xFF596478),
  separator: Color(0xFFD4DBE7),
  accent: Color(0xFF1B5FD9),
  onAccent: _white,
  accentOnSurface: Color(0xFF1451BE),
  accentSoft: SurfacePair(Color(0xFFE4EDFC), Color(0xFF14509E)),
  categoryTints: _lightTints,
  keyNumber: SurfacePair(_white, _ink),
  keyFunction: SurfacePair(Color(0xFFE7ECF5), _ink),
  keyAction: SurfacePair(Color(0xFFD3DBE8), _ink),
  keyOperator: SurfacePair(Color(0xFFFFE9C2), Color(0xFF6B3E00)),
  keyEquals: SurfacePair(Color(0xFFB45309), _white),
  display: SurfacePair(_white, _ink),
  errorSurface: SurfacePair(_paper, Color(0xFFB4231C)),
);

const _darkInk = Color(0xFFF1F4FA);
const _darkPage = Color(0xFF0B0E14);

const _dark = Palette(
  appearance: Appearance.dark,
  background: _darkPage,
  groupedBackground: Color(0xFF141922),
  // Lighter than the background: elevation reads as light in dark mode.
  elevatedSurface: Color(0xFF1B212C),
  label: _darkInk,
  secondaryLabel: Color(0xFF98A3B6),
  separator: Color(0xFF262E3C),
  accent: Color(0xFF2563EB),
  onAccent: _white,
  // A blue dark enough to carry white text is too dark to read against a
  // near-black page, so ink and fill are different values here.
  accentOnSurface: Color(0xFF6BA3FF),
  accentSoft: SurfacePair(Color(0xFF15233D), Color(0xFF8CB8FF)),
  categoryTints: _darkTints,
  keyNumber: SurfacePair(Color(0xFF242B37), _darkInk),
  keyFunction: SurfacePair(Color(0xFF171D27), _darkInk),
  keyAction: SurfacePair(Color(0xFF323B4A), _darkInk),
  keyOperator: SurfacePair(_amber, Color(0xFF291A00)),
  keyEquals: SurfacePair(_amber, Color(0xFF291A00)),
  display: SurfacePair(Color(0xFF11161F), _darkInk),
  errorSurface: SurfacePair(_darkPage, Color(0xFFFF9A8A)),
);

/// Increase Contrast, light. Not a different design — the same design with
/// the neutrals pushed apart and the accent darkened.
const _lightHighContrast = Palette(
  appearance: Appearance.lightHighContrast,
  background: _white,
  groupedBackground: Color(0xFFEDF1F8),
  elevatedSurface: _white,
  label: Color(0xFF000000),
  secondaryLabel: Color(0xFF323B4A),
  separator: Color(0xFF5E6878),
  accent: Color(0xFF0B3F96),
  onAccent: _white,
  accentOnSurface: Color(0xFF0B3F96),
  accentSoft: SurfacePair(Color(0xFFDCE8FB), Color(0xFF08306F)),
  categoryTints: _lightHighContrastTints,
  keyNumber: SurfacePair(_white, Color(0xFF000000)),
  keyFunction: SurfacePair(Color(0xFFEDF1F8), Color(0xFF000000)),
  keyAction: SurfacePair(Color(0xFFC9D2E0), Color(0xFF000000)),
  keyOperator: SurfacePair(Color(0xFFFFE2AE), Color(0xFF3D2300)),
  keyEquals: SurfacePair(Color(0xFF7A3703), _white),
  display: SurfacePair(_white, Color(0xFF000000)),
  errorSurface: SurfacePair(_white, Color(0xFF8A0000)),
);

/// Increase Contrast, dark. True black, because it serves OLED here and
/// because this is the appearance a low-vision user reaches for.
const _darkHighContrast = Palette(
  appearance: Appearance.darkHighContrast,
  background: Color(0xFF000000),
  groupedBackground: Color(0xFF0C0C0E),
  elevatedSurface: Color(0xFF17181C),
  label: _white,
  secondaryLabel: Color(0xFFCDD4E0),
  separator: Color(0xFF858C99),
  // 9.7:1 against its white label. The ordinary dark accent is 5.7:1,
  // which is AA but not the AAA this appearance exists to provide.
  accent: Color(0xFF0B3F96),
  onAccent: _white,
  accentOnSurface: Color(0xFF9CC2FF),
  accentSoft: SurfacePair(Color(0xFF0E1B30), Color(0xFFAFCEFF)),
  categoryTints: _darkHighContrastTints,
  keyNumber: SurfacePair(Color(0xFF1B1D22), _white),
  keyFunction: SurfacePair(Color(0xFF101216), _white),
  keyAction: SurfacePair(Color(0xFF3A3F49), _white),
  keyOperator: SurfacePair(Color(0xFFFFC24B), Color(0xFF000000)),
  // Black on amber, 13:1. This is the pairing the old theme got wrong.
  keyEquals: SurfacePair(Color(0xFFFFC24B), Color(0xFF000000)),
  display: SurfacePair(Color(0xFF000000), _white),
  errorSurface: SurfacePair(Color(0xFF000000), Color(0xFFFFB3A6)),
);

/// Six tints, cycled. Six is enough that adjacent rows never repeat and
/// few enough that the list still looks like one family rather than a
/// paint chart.
const _lightTints = <SurfacePair>[
  SurfacePair(Color(0xFFE3EDFC), Color(0xFF14509E)),
  SurfacePair(Color(0xFFEBE8FD), Color(0xFF4B32AE)),
  SurfacePair(Color(0xFFDFF3E7), Color(0xFF13633A)),
  SurfacePair(Color(0xFFFBE7F0), Color(0xFF9C1256)),
  SurfacePair(Color(0xFFFCEBDC), Color(0xFF8A4206)),
  SurfacePair(Color(0xFFDDF0F4), Color(0xFF0A5A6A)),
];

const _darkTints = <SurfacePair>[
  SurfacePair(Color(0xFF16273F), Color(0xFF8FBAFF)),
  SurfacePair(Color(0xFF231F45), Color(0xFFB8A8FF)),
  SurfacePair(Color(0xFF0F2C1F), Color(0xFF76D6A0)),
  SurfacePair(Color(0xFF37162A), Color(0xFFFFA0C6)),
  SurfacePair(Color(0xFF362413), Color(0xFFFFB878)),
  SurfacePair(Color(0xFF0E2A31), Color(0xFF79D3DE)),
];

const _lightHighContrastTints = <SurfacePair>[
  SurfacePair(Color(0xFFDCE8FB), Color(0xFF08306F)),
  SurfacePair(Color(0xFFE6E1FC), Color(0xFF331F84)),
  SurfacePair(Color(0xFFD7EFE1), Color(0xFF0B4527)),
  SurfacePair(Color(0xFFFADFEA), Color(0xFF6E0C3C)),
  SurfacePair(Color(0xFFFBE4D0), Color(0xFF632F04)),
  SurfacePair(Color(0xFFD4ECF1), Color(0xFF07404B)),
];

const _darkHighContrastTints = <SurfacePair>[
  SurfacePair(Color(0xFF0D1B2E), Color(0xFFAFCEFF)),
  SurfacePair(Color(0xFF191534), Color(0xFFCFC2FF)),
  SurfacePair(Color(0xFF0A2016), Color(0xFF9BE6BC)),
  SurfacePair(Color(0xFF2A0F20), Color(0xFFFFBBD6)),
  SurfacePair(Color(0xFF29190B), Color(0xFFFFCE9C)),
  SurfacePair(Color(0xFF082026), Color(0xFF9FE3EC)),
];
