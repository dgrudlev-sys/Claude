# Flutter Implementation — Foundations (color · typography · layout)

Scope: translating this skill's color-systems, typography, and layout-grid-spacing references into idiomatic Flutter/Dart. Read the three sibling reference files first — this file assumes their HIG rationale and only adds the Dart/Flutter "how." Confidence labels follow the family convention: `[documented]` for verifiable Flutter/Dart SDK API behavior, `[inferred]` for a reasonable but unconfirmed recommendation, `[speculative]` for an untested idea.

---

## 1. Semantic & dynamic color

### CupertinoColors — the built-in semantic layer

Flutter's Cupertino library ships a set of `CupertinoDynamicColor` constants that mirror Apple's semantic UIKit colors directly — `CupertinoColors.label`, `.systemBackground`, `.systemBlue`, `.separator`, and the full gray scale [documented — `package:flutter/cupertino.dart`, `CupertinoColors` class]. These are **dynamic colors**: each one already encodes a light and a dark resolved value, and Flutter resolves the correct one from `BuildContext` automatically when used through `CupertinoDynamicColor.resolve(context)` or directly as a `Color` inside a widget tree under `CupertinoTheme`/`MediaQuery` [documented].

```dart
import 'package:flutter/cupertino.dart';

// Direct usage — resolves automatically against the ambient brightness
Text(
  'Hello',
  style: TextStyle(color: CupertinoColors.label),
)

Container(
  color: CupertinoColors.systemBackground,
  child: const Divider(color: CupertinoColors.separator),
)

// WRONG — hardcoded hex, breaks dark mode / contrast just like native
Text('Hello', style: TextStyle(color: Color(0xFF000000)))
```

`CupertinoColors` values that map directly to the color-systems reference's semantic table [documented — names match 1:1 with UIKit tokens]:

| HIG token | CupertinoColors constant |
|---|---|
| `.label` | `CupertinoColors.label` |
| `.secondaryLabel` | `CupertinoColors.secondaryLabel` |
| `.tertiaryLabel` | `CupertinoColors.tertiaryLabel` |
| `.quaternaryLabel` | `CupertinoColors.quaternaryLabel` |
| `.systemBackground` | `CupertinoColors.systemBackground` |
| `.secondarySystemBackground` | `CupertinoColors.secondarySystemBackground` |
| `.tertiarySystemBackground` | `CupertinoColors.tertiarySystemBackground` |
| `.systemGroupedBackground` | `CupertinoColors.systemGroupedBackground` |
| `.separator` | `CupertinoColors.separator` |
| `.opaqueSeparator` | `CupertinoColors.opaqueSeparator` |
| `.systemBlue` / `.systemGreen` / `.systemRed` / etc. | `CupertinoColors.systemBlue`, `.systemGreen`, `.systemRed`, `.systemOrange`, `.systemYellow`, `.systemPink`, `.systemPurple`, `.systemTeal`, `.systemIndigo` |
| Gray scale | `CupertinoColors.systemGrey` through `.systemGrey6` (note British spelling `Grey`, not `Gray`) [documented] |

`Material`-side apps that still want an Apple-adjacent semantic palette should not reach for `Colors.blue` etc. (Material's tonal palette does not track Apple's values); import `CupertinoColors` regardless of whether the rest of the tree is Material [inferred — CupertinoColors is just a `Color`/`CupertinoDynamicColor` constant set, usable anywhere].

### Building your own dynamic colors — `CupertinoDynamicColor.withBrightness`

For brand/custom colors that must behave like system colors (auto light/dark, and ideally high-contrast variants), construct a `CupertinoDynamicColor` directly instead of hand-branching on `Theme.of(context).brightness` everywhere [documented — `CupertinoDynamicColor` constructor].

```dart
import 'package:flutter/cupertino.dart';

// Mirrors the native "Any Appearance / Dark / High Contrast" xcasset pattern
const brandAccent = CupertinoDynamicColor.withBrightness(
  color: Color(0xFF007AFF),       // light mode
  darkColor: Color(0xFF0A84FF),   // dark mode — brighter, per HIG dark-mode accent rule
);

// Full 4-way variant (light / dark / high-contrast light / high-contrast dark)
const brandAccentHC = CupertinoDynamicColor.withBrightnessAndContrast(
  color: Color(0xFF007AFF),
  darkColor: Color(0xFF0A84FF),
  highContrastColor: Color(0xFF0040CC),
  darkHighContrastColor: Color(0xFF4DA3FF),
);

// Resolve explicitly when you need the raw Color (e.g. passing to a
// non-Cupertino-aware API that doesn't auto-resolve BuildContext colors)
final resolved = CupertinoDynamicColor.resolve(brandAccent, context);
```

`CupertinoDynamicColor` only resolves automatically when it flows through widgets that call `.resolveFrom(context)` internally (most Cupertino widgets do this for you); if you store one in a plain `Color` variable and hand it to a raw `Paint()` or `CustomPainter`, resolve it explicitly first [documented — resolution is context-dependent, not automatic on every code path].

### Dark mode: dimming, not inverting — same rule, Flutter mechanism

Implement the three-step dark elevation staircase (`#000000 → #1C1C1E → #2C2C2E`, per the color-systems reference) as your own `CupertinoDynamicColor` constants rather than computing an inverted value at runtime [inferred — matches the native anti-pattern warning against pure inversion]:

```dart
class AppColors {
  AppColors._();

  static const bgBase = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF000000),
  );
  static const bgElevated1 = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF1C1C1E),
  );
  static const bgElevated2 = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF2C2C2E),
  );
}
```

Reading the current brightness directly (for branching logic, not for color resolution) uses `MediaQuery.platformBrightnessOf(context)` or `CupertinoTheme.brightnessOf(context)` [documented]. To force an app into a fixed appearance regardless of system setting (the "pinned light" pattern from the CSS reference), set `CupertinoThemeData(brightness: Brightness.light)` explicitly at the `CupertinoApp` root rather than reading system brightness at all [documented].

### Display P3 wide gamut — the real gap

**Flutter's `Color` class is sRGB-only** [documented — `dart:ui`'s `Color` stores a 32-bit ARGB integer with no color-space tag; there is no P3 `Color` constructor in the stable Flutter SDK as of this writing]. This is a genuine capability gap versus native: SwiftUI's `Color(displayP3Red:green:blue:opacity:)` and CSS's `color(display-p3 ...)` both have no first-class Flutter equivalent.

Practical consequences and workarounds:

- Every `Color(0xFF007AFF)`-style constant in Flutter is interpreted as sRGB. On a wide-gamut (P3) display, the OS compositor will render it at its sRGB value — you get the *sRGB-clipped* version of Apple's colors, not the more saturated P3 original, same ceiling the color-systems reference describes for plain CSS hex values [inferred — consistent with `Color`'s documented sRGB storage and general platform compositing behavior].
- As of recent Flutter/Skia (Impeller) engine versions there has been movement toward wide-gamut rendering support on iOS for `Image`/texture content, but the public, stable `dart:ui` `Color` API itself does not expose a way to author a P3-tagged color value [speculative — engine-level wide-gamut plumbing is a moving target across Flutter versions; verify current engine capability against the Flutter version in use before relying on it].
- **Workaround for photographic/texture content:** if wide-gamut fidelity matters for an image or gradient asset (not a solid UI color), ship the asset itself as a P3-tagged image (e.g. a P3 PNG/HEIC) via `Image.asset`/`Image.network` — the image decoder and engine compositor handle color-managed image *content* more capably than the `Color` API handles solid values [inferred].
- **Workaround for solid UI colors:** there is no reliable workaround inside stable, engine-version-agnostic Flutter to author a genuinely-P3 solid color today. Treat this as an accepted platform gap: use the sRGB hex values from the color-systems reference's tables as-is, and do not claim P3 fidelity for solid Flutter UI colors [inferred].
- If P3 fidelity is a hard product requirement on iOS specifically, the fallback is a native platform channel/view (`UiKitView`) rendering a small SwiftUI/UIKit layer for that specific element — outside the scope of "pure Flutter," noted here only so the gap isn't silently swallowed [speculative].

### Increase Contrast / Reduce Transparency — reading the platform signal

```dart
// Increase Contrast (iOS) surfaces through MediaQuery
final highContrast = MediaQuery.highContrastOf(context); // documented — MediaQueryData.highContrast

// Reduce Transparency
final reduceTransparency = MediaQuery.disableAnimationsOf(context); // NOT the right flag — see note below
```

`MediaQueryData.highContrast` is a real, documented Flutter field sourced from the OS accessibility setting [documented — `MediaQueryData.highContrast`, iOS-backed]. Flutter's `MediaQueryData` does **not** expose a direct "Reduce Transparency" boolean as of the stable SDK at time of writing — there is `MediaQueryData.disableAnimations` (maps to Reduce Motion) and `MediaQueryData.boldText`, but no confirmed first-class Reduce-Transparency flag [inferred — verify against the current Flutter SDK version's `MediaQueryData` field list before depending on this; if absent, the practical fallback is to always ship an opaque/near-opaque variant of any glass surface and let `highContrast` double as the trigger for it].

---

## 2. Dynamic Type equivalent

### `MediaQuery.textScalerOf` — Flutter's Dynamic Type hook

Flutter reads the platform's user-selected text scale (iOS Settings → Display & Brightness → Text Size, and the Accessibility large-text levels) through `MediaQuery.textScalerOf(context)`, a `TextScaler` — the modern replacement for the older `textScaleFactor` double [documented — `TextScaler` introduced as the `textScaleFactor` replacement in recent stable Flutter; `textScaleFactor` is deprecated in current SDKs].

```dart
import 'package:flutter/cupertino.dart';

@override
Widget build(BuildContext context) {
  final textScaler = MediaQuery.textScalerOf(context);

  return Text(
    'Body copy that must reflow, never truncate',
    style: const TextStyle(fontSize: 17), // base size; scaler multiplies it
    // Most Cupertino/Material widgets apply textScaler automatically —
    // manual application (below) is only needed for custom painting.
  );
}

// Manual scaling (e.g. inside a CustomPainter or a non-widget layout calc)
final scaledFontSize = MediaQuery.textScalerOf(context).scale(17.0);
```

Nearly every built-in text-bearing widget (`Text`, `CupertinoButton`'s label, form fields) already reads the ambient `MediaQuery` text scaler automatically and applies it without extra code [documented — `Text` widget's default `textScaler` parameter falls back to `MediaQuery.textScalerOf(context)`]. The failure mode to avoid is the same as native: passing an explicit `TextScaler.noScaling` or wrapping a subtree in a `MediaQuery` override that pins `textScaler` to a fixed value — this silently opts a whole subtree out of Dynamic Type, mirroring the native anti-pattern of `adjustsFontForContentSizeCategory = false` [inferred — same category of accessibility regression].

### Avoiding fixed-pixel text — layout implications

Because scaled text can grow substantially at accessibility sizes, any layout using `Text` inside a fixed-height `Container` or a `SizedBox` with a hardcoded height risks clipping — same "must reflow" rule as the native and CSS references [documented — general Flutter layout principle; large Dynamic Type sizes can scale body text well past 2x].

```dart
// WRONG — fixed height clips scaled text
SizedBox(
  height: 20,
  child: Text('Status', style: TextStyle(fontSize: 13)),
)

// RIGHT — let the row size to its (scaled) content
Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Text('Status', style: TextStyle(fontSize: 13)),
)
```

For rows/lists at accessibility text sizes, test with `MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)), child: ...)` wrapped around a subtree in development to preview extreme scaling without changing the simulator/device setting [inferred — a standard debugging pattern for this class of Flutter bug, not an official API name].

### Clamping — when, and why to be careful

Some teams clamp `textScaler` to a maximum to protect a specific fragile layout (e.g. a tab bar label). This trades an accessibility guarantee for layout safety and should be treated as a last resort, scoped as narrowly as possible (one widget, not the whole app) — mirrors the HIG's own "must reflow, never truncate" stance being violated only under duress [inferred].

```dart
Text(
  'Home',
  style: const TextStyle(fontSize: 10),
  textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
)
```

---

## 3. San Francisco / New York alternatives in Flutter

### On iOS: the system font is already free

A `CupertinoApp`/`CupertinoTheme` with no custom `fontFamily` set renders text using the platform's default font, which resolves to San Francisco on iOS devices automatically — Flutter's Cupertino text theme is built to inherit the native system font stack rather than bundling its own [documented — `CupertinoTextThemeData` defaults reference the platform font; consistent with the licensing note in `apple-design/references/flutter-implementation.md` that no SF Pro bundling is needed or permitted on iOS]. Do not set an explicit `fontFamily` unless you intentionally want to override it.

```dart
// Correct — inherits SF Pro on iOS automatically, platform font elsewhere
const CupertinoApp(
  theme: CupertinoThemeData(), // no fontFamily override
)
```

### Cross-platform: google_fonts and metrically-similar alternatives

For a brand feel that should look consistent across iOS, Android, and web, the standard approach is `google_fonts`, which fetches/bundles open-license fonts without you needing to vendor font files by hand [documented — `google_fonts` is a widely used, actively maintained Flutter package; verify current version/API on pub.dev before pinning a version].

| SF Pro role | Suggested google_fonts alternative | Rationale |
|---|---|---|
| UI text / body | **Inter** | Closest open geometric-grotesque match to SF Pro's aperture and x-height philosophy — the same recommendation the typography reference makes for CSS [inferred, consistent with `typography.md`'s web guidance] |
| A slightly warmer/rounder alternative | **Plus Jakarta Sans**, **Manrope** | Cited in the typography reference as secondary options [inferred] |
| Android-native feel instead of imitating iOS | **Roboto Flex** (variable font) | Google's own SF-Pro-equivalent variable font; appropriate when the app deliberately wants to look native per-platform rather than uniformly Apple-styled [inferred] |
| New York (serif reading face) | **Source Serif 4**, **Lora**, or **Georgia** (system) | No open font perfectly replicates New York's optical-size behavior; pick a well-hinted text serif and accept the approximation [inferred] |

```dart
import 'package:google_fonts/google_fonts.dart';

final bodyStyle = GoogleFonts.inter(
  fontSize: 17,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.label,
);

// Apply as a theme-wide default
CupertinoTheme(
  data: CupertinoThemeData(
    textTheme: CupertinoTextThemeData(
      textStyle: GoogleFonts.interTextTheme().bodyMedium!.copyWith(
        color: CupertinoColors.label,
      ),
    ),
  ),
  child: const MyHomePage(),
)
```

Never label an Inter/Roboto Flex-based type system as "SF Pro" in UI copy, App Store listings, or code comments meant for a design review — it is a compatible substitute, not the real typeface, exactly as the typography reference insists for its CSS equivalent [inferred — same honesty principle applied to Flutter].

### Custom font loading via pubspec.yaml

For a licensed font (purchased, or a font you have rights to redistribute — never SF Pro/SF Symbols/New York), bundle it as a local asset instead of `google_fonts`' network/asset-bundling approach [documented — standard Flutter custom-font mechanism]:

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: BrandSans
      fonts:
        - asset: assets/fonts/BrandSans-Regular.ttf
          weight: 400
        - asset: assets/fonts/BrandSans-Semibold.ttf
          weight: 600
        - asset: assets/fonts/BrandSans-Bold.ttf
          weight: 700
```

```dart
const bodyStyle = TextStyle(
  fontFamily: 'BrandSans',
  fontSize: 17,
  fontWeight: FontWeight.w400,
);
```

For a font not declared in `pubspec.yaml` (e.g. loaded at runtime from a downloaded file), use the `FontLoader` API [documented — `dart:ui`'s `FontLoader`, exposed via `package:flutter/services.dart` friendly wrappers]:

```dart
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

Future<void> loadRuntimeFont() async {
  final fontLoader = FontLoader('RuntimeFont');
  fontLoader.addFont(rootBundle.load('assets/fonts/Runtime-Regular.ttf'));
  await fontLoader.load();
  // Now usable as TextStyle(fontFamily: 'RuntimeFont')
}
```

### Mapping the Dynamic Type scale to Dart constants

Mirror the 11 HIG text styles as a Dart class so call sites read semantically, same discipline as `.font(.body)` in SwiftUI or the CSS custom-property scale in the foundations CSS recipe [inferred — direct translation of the typography reference's table]:

```dart
class AppTypeScale {
  AppTypeScale._();

  static const largeTitle = TextStyle(fontSize: 34, fontWeight: FontWeight.w400, height: 41 / 34);
  static const title1     = TextStyle(fontSize: 28, fontWeight: FontWeight.w400, height: 34 / 28);
  static const title2     = TextStyle(fontSize: 22, fontWeight: FontWeight.w400, height: 28 / 22);
  static const title3     = TextStyle(fontSize: 20, fontWeight: FontWeight.w400, height: 25 / 20);
  static const headline   = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 22 / 17);
  static const body       = TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 22 / 17);
  static const callout    = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 21 / 16);
  static const subhead    = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 20 / 15);
  static const footnote   = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 18 / 13);
  static const caption1   = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 16 / 12);
  static const caption2   = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, height: 13 / 11);
}

// Usage
Text('Section title', style: AppTypeScale.headline.copyWith(color: CupertinoColors.label));
```

`height` in Flutter's `TextStyle` is a line-height *multiplier of the font size*, not an absolute pixel value — `height: 22 / 17` means "22pt line-height at 17pt font size," matching the ratio convention Flutter expects [documented — `TextStyle.height` semantics].

---

## 4. The 8pt grid and safe areas in Flutter

### Spacing constants — direct translation of the CSS token scale

Flutter has no native CSS-custom-property equivalent, so the idiomatic pattern is a `class` of `static const double` values, mirroring the 8pt (and 4pt half-step) scale from the layout-grid-spacing reference exactly [inferred — direct translation, same numeric values]:

```dart
class AppSpacing {
  AppSpacing._();

  static const double xs2  = 2;
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double base = 16;
  static const double lg   = 24;
  static const double xl   = 32;
  static const double xl2  = 40;
  static const double xl3  = 48;
  static const double xl4  = 64;
}

// Usage
Padding(
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.lg),
  child: content,
)

Column(
  children: [
    header,
    const SizedBox(height: AppSpacing.md), // 12pt — soft-grid list-row gap
    body,
  ],
)
```

`EdgeInsets` is Flutter's box-model spacing primitive; the named constructors (`EdgeInsets.symmetric`, `.only`, `.all`, `.fromLTRB`) map cleanly onto the "side margin / interior padding" vocabulary from the layout reference [documented].

### SafeArea widget and MediaQuery.padding

Flutter's `SafeArea` widget is the direct equivalent of `env(safe-area-inset-*)`/UIKit's `safeAreaLayoutGuide` — it reads the current device's notch/Dynamic-Island/home-indicator insets and pads its child accordingly [documented — `SafeArea` widget, backed by `MediaQuery.paddingOf(context)`].

```dart
CupertinoPageScaffold(
  child: SafeArea(
    // top/bottom/left/right default to true; disable per-edge where a
    // bar or tab bar already accounts for that edge, to avoid double-padding
    child: MyScreenContent(),
  ),
)
```

`CupertinoPageScaffold`, `CupertinoTabScaffold`, and `CupertinoNavigationBar` already account for safe areas internally for their own chrome [documented] — wrapping their *content* slot in an additional `SafeArea` is usually still correct (it protects against notch/home-indicator overlap for content that scrolls under translucent bars), but wrapping the whole scaffold redundantly can cause doubled insets; test on a Dynamic-Island-class simulator profile [inferred].

For manual inset math (e.g. positioning something absolutely with a `Stack`), read the raw values directly:

```dart
final padding = MediaQuery.paddingOf(context);
// padding.top    → status bar / Dynamic Island inset
// padding.bottom → home indicator inset
```

### EdgeInsets conventions matching the native margin table

| HIG value (from layout reference) | Flutter usage |
|---|---|
| Phone portrait side margin: 16pt | `EdgeInsets.symmetric(horizontal: 16)` on the outermost content wrapper |
| iPad side margin: 20pt+ | Branch on `MediaQuery.sizeOf(context).width` or use `LayoutBuilder` to switch to 20–24 |
| Card interior padding: 24pt | `EdgeInsets.all(24)` inside a card `Container`/`DecoratedBox` |
| Min tap target 44×44pt | `SizedBox(width: 44, height: 44)` wrapping any custom tappable, or rely on Cupertino widgets' built-in minimums (`CupertinoButton` already enforces roughly this) [documented — Cupertino widgets follow the 44pt HIG minimum by default] |

A minimal responsive-margin helper, mirroring the native size-class branching pattern from the layout reference [inferred]:

```dart
double horizontalMargin(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 1024) return AppSpacing.xl;   // desktop/iPad landscape-class
  if (width >= 768) return AppSpacing.lg;    // iPad portrait-class
  return AppSpacing.base;                    // phone
}
```

### `LayoutBuilder` as Flutter's size-class proxy

Flutter has no built-in `horizontalSizeClass` enum; `LayoutBuilder` (or `MediaQuery.sizeOf`) is the mechanism for the same "branch on available space, not device name" principle the layout reference insists on for SwiftUI [documented — `LayoutBuilder` gives the parent's constraints, the Flutter-native way to make this decision]:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isRegular = constraints.maxWidth >= 700; // pick your own breakpoint
    return isRegular
        ? Row(children: [sidebar, Expanded(child: detail)])   // "regular" — HStack equivalent
        : detail;                                              // "compact" — VStack/single column
  },
)
```

---

## 5. Bento-grid layout recipe

Three approaches, in increasing sophistication, mirroring the "simplest that fits" guidance the layout reference gives for its own SwiftUI patterns [inferred].

### Approach A: `GridView` with explicit spans (simplest, fixed grid)

Standard `GridView.count`/`GridView.builder` do not natively support Apple's bento pattern of *tiles occupying different row/column spans* (`2×2` hero + `1×1` fillers) — that spanning behavior needs `StaggeredGrid` (Approach C) or manual `Wrap`/`CustomMultiChildLayout`. For a **fixed, hand-authored** bento section (a handful of known tiles, not a dynamic feed), the most direct Flutter primitive is nested `Row`/`Column`/`Expanded`, mirroring the fixed CSS grid-template-areas approach rather than a generic grid widget [inferred]:

```dart
// Mirrors the "1 hero (2×2) + 2 squares + 1 wide" 6-tile Apple bento blueprint
Padding(
  padding: const EdgeInsets.all(AppSpacing.base),
  child: SizedBox(
    height: 336 * 2 + AppSpacing.sm, // two row-heights + one gap
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: BentoTile.hero(title: 'Camera')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            children: [
              Expanded(child: BentoTile.square(title: 'Battery')),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: BentoTile.square(title: 'Display')),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            children: [
              Expanded(child: BentoTile.square(title: 'Chip')),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: BentoTile.wide(title: 'Battery life')),
            ],
          ),
        ),
      ],
    ),
  ),
)
```

This is verbose but gives pixel-exact control over spans — appropriate for a marketing/showcase screen with a small, fixed tile count, matching the layout reference's own observation that Apple's bento sections are hand-composed, not dynamically generated [inferred].

### Approach B: `Wrap` (simplest, for uniform or near-uniform tiles)

When tiles are closer to uniform size (no 2×2 hero requirement), `Wrap` reflows naturally at any width with zero span math [documented — `Wrap` widget]:

```dart
Wrap(
  spacing: AppSpacing.sm,
  runSpacing: AppSpacing.sm,
  children: features.map((f) => SizedBox(
    width: 160,
    height: 160,
    child: BentoTile.square(title: f.title),
  )).toList(),
)
```

### Approach C: `flutter_staggered_grid_view` for dynamic span-aware grids

For a bento layout driven by data (variable tile counts/sizes, not hand-authored), the community package `flutter_staggered_grid_view` is the standard reach [inferred — verify current package name/API on pub.dev; this is the most commonly cited package for this use case but unverified against the current pub.dev listing in this environment]. Its `StaggeredGrid`/`SliverStaggeredGrid` API models column/row spans directly, closer to CSS Grid's `grid-column: span N` than plain `GridView` allows:

```dart
// Illustrative — confirm exact class/constructor names against the
// current flutter_staggered_grid_view API on pub.dev before shipping.
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

StaggeredGrid.count(
  crossAxisCount: 4,
  mainAxisSpacing: AppSpacing.sm,
  crossAxisSpacing: AppSpacing.sm,
  children: [
    StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: BentoTile.hero(title: 'Camera')),
    StaggeredGridTile.count(crossAxisCellCount: 1, mainAxisCellCount: 1, child: BentoTile.square(title: 'Battery')),
    StaggeredGridTile.count(crossAxisCellCount: 1, mainAxisCellCount: 1, child: BentoTile.square(title: 'Display')),
    StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 1, child: BentoTile.wide(title: 'Battery life')),
  ],
)
```

### A minimal `BentoTile` widget (shared by all three approaches)

```dart
class BentoTile extends StatelessWidget {
  const BentoTile({super.key, required this.title, this.isHero = false});

  final String title;
  final bool isHero;

  factory BentoTile.hero({required String title}) => BentoTile(title: title, isHero: true);
  factory BentoTile.square({required String title}) => BentoTile(title: title);
  factory BentoTile.wide({required String title}) => BentoTile(title: title);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(18), // matches the 18px HIG bento radius
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Align(
          alignment: Alignment.bottomLeft, // text anchors bottom, per HIG bento pattern
          child: Text(
            title,
            style: (isHero ? AppTypeScale.title2 : AppTypeScale.headline)
                .copyWith(color: CupertinoColors.label.resolveFrom(context)),
          ),
        ),
      ),
    );
  }
}
```

Zero-orphan rule and "bento once, where it earns it" restraint discipline apply identically in Flutter — this recipe is a layout mechanism, not a license to add a bento section to every screen [inferred — same rule as `apple-design/references/restraint-and-antislop.md`].

---

## Confidence summary

`CupertinoColors`, `CupertinoDynamicColor`, `MediaQuery.textScalerOf`, `SafeArea`, `LayoutBuilder`, `Wrap`, `EdgeInsets`, and the `Color` class's sRGB-only storage are `[documented]` Flutter/Dart SDK behavior. `google_fonts` and `flutter_staggered_grid_view` package names and their exact current APIs are `[inferred]` — verify both on pub.dev before depending on them. The P3 wide-gamut gap assessment and its workarounds are `[inferred]`/`[speculative]` given this environment cannot check current engine-version capability live.
