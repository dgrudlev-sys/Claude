# Flutter Implementation — Quick-Start

Scope: how to set up a Flutter/Dart project to pursue the same Apple-grade bar the rest of this family documents. This is the routing layer for Flutter work — it tells you what foundation to lay and which packages the other skills' Flutter recipes assume. It does not re-teach the HIG principles; read `references/philosophy-and-evolution.md` and `references/restraint-and-antislop.md` first — they are the "why" regardless of platform.

---

## Cupertino as the foundation, not an afterthought

Flutter ships two widget libraries: `material` and `cupertino`. For an Apple-grade app, **Cupertino is the base layer**, even if the app also ships on Android [documented — Flutter SDK]. `CupertinoApp` gives you the iOS scroll physics (`BouncingScrollPhysics` by default), `CupertinoPageRoute` transitions (the native slide-over-push), and system-matched text (`.SF UI Text`/`-apple-system` equivalents come free on-device — see the font section below).

Decision rule [inferred]:

| Situation | Base widget set |
|---|---|
| iOS-only app, or cross-platform app whose brand IS "feels native on iOS" | `CupertinoApp` root; Cupertino widgets throughout |
| Cross-platform app with one shared visual identity (not trying to look native per-OS) | `MaterialApp` root is fine, but reach for Cupertino-shaped primitives (icons, sheet transitions, switches) to keep the "restraint + depth" feel; avoid Material-specific tells (ripples, FABs, elevation shadows) if the goal is Apple-grade |
| App explicitly adapting per-platform (Cupertino on iOS, Material on Android) | `PlatformWidget`-style branching, or the community `flutter_platform_widgets` package — verify current API on pub.dev before relying on it [inferred] |

```dart
import 'package:flutter/cupertino.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Apple-Grade Flutter App',
      theme: CupertinoThemeData(
        brightness: Brightness.light, // omit to follow system brightness
        primaryColor: CupertinoColors.systemBlue,
      ),
      home: HomeScreen(),
    );
  }
}
```

Even inside a `MaterialApp` shell, you can nest `CupertinoTheme`/`CupertinoPageScaffold` in specific routes — Flutter does not require picking one system globally. Mixing is normal; mixing *inconsistently within one screen* is the anti-pattern (same restraint discipline as the rest of this family: pick a system per surface, don't alternate mid-screen) [inferred].

---

## When Material creeps in anyway

Some Flutter internals (text selection toolbars, some form fields, `Scaffold`-adjacent APIs, `Overlay`) are easiest to reach via Material widgets even in a Cupertino-first app. This is normal — Flutter's own Cupertino library itself depends on the Material `Overlay`/`Navigator` machinery under the hood [documented]. Practical rule: wrap the whole app in `CupertinoApp`, and only pull in individual Material widgets (never `Scaffold` + `AppBar`) when there's no Cupertino equivalent. Avoid `MaterialApp` + Material `Scaffold` as the outer shell if the design goal is "feels like an iOS app."

---

## Recommended base packages

None of these calls are verified against current pub.dev listings — this environment cannot browse pub.dev. Treat every package name below as [inferred] and confirm the exact name, current API, and null-safety/SDK-constraint status on pub.dev before adding it to a pubspec. `cupertino_icons` is the one exception — it ships in every new Flutter project's default `pubspec.yaml` and is safe to treat as [documented].

| Need | Package (verify on pub.dev) | Notes |
|---|---|---|
| SF-Symbols-shaped icon set | `cupertino_icons` | Already a default dependency; small subset, not the full SF Symbols library — see `apple-design-materials/references/flutter-implementation.md` |
| Glass / frosted blur | Flutter's own `dart:ui` `ImageFilter.blur` + `BackdropFilter` (no package needed) | The reliable baseline; see `apple-design-materials/references/flutter-implementation.md` for the recipe |
| Pre-built glassmorphism widgets | `glassmorphism`, `liquid_glass_renderer`, `blur` [inferred — unverified exact package/API] | Optional shortcuts over `BackdropFilter`; confirm current API before use |
| Spring-based animation physics | Flutter's own `SpringSimulation`/`SpringDescription` (`physics` field of `AnimationController`) (no package needed); `flutter_animate` for a higher-level animation DSL [inferred] | See `apple-design-motion` skill's Flutter reference for spring-curve translation |
| Haptics | Flutter's own `HapticFeedback` class (`services.dart`, no package needed) for basic impacts; `flutter_haptic_feedback` or platform channels for finer iOS Taptic Engine control [inferred] | Basic light/medium/heavy/selection feedback needs no package |
| Cross-platform font matching SF Pro's feel | `google_fonts` (Inter, etc.) | See foundations reference for the full type-scale mapping |
| Superellipse/squircle corners | `figma_squircle` [inferred — unverified exact package/API] | See materials reference for a hand-rolled fallback clipper |
| Staggered/bento grid layouts | `flutter_staggered_grid_view` [inferred — unverified exact package/API] | `Wrap`/`GridView` cover most cases without a package — see foundations reference |

Do not add a package purely because it exists — Flutter's own SDK (`BackdropFilter`, `HapticFeedback`, `SpringSimulation`, `CupertinoIcons`) already covers the load-bearing 80%. Reach for a package when the SDK primitive would require meaningfully more hand-rolled math (squircle paths, staggered grids) — same restraint principle as the rest of this family: don't add a dependency that only adds convenience, not capability [inferred].

---

## Font licensing — read this before bundling anything

SF Pro, SF Compact, SF Mono, New York, and SF Symbols are Apple-proprietary and licensed only for use inside apps built for Apple's own operating systems, downloaded through Apple's developer tools [documented — Apple Font License, covered in depth in `apple-design-foundations/references/typography.md`]. This has a direct, practical consequence for Flutter:

- **On iOS**, a `CupertinoApp` (or any Flutter text widget with no custom `fontFamily`) already renders in the system's SF Pro without you bundling anything — Flutter's Cupertino text theme defaults to the platform's system font stack, same as Safari's `-apple-system` [documented — Flutter Cupertino text theme defaults to platform font]. **No action needed on iOS.**
- **You cannot legally bundle SF Pro/SF Symbols font files inside a Flutter app's assets** to render them uniformly on Android, web, Windows, or Linux — that would be redistributing Apple's licensed font outside an Apple OS context [documented — same license terms apply to any redistribution, Flutter included].
- **For a genuinely cross-platform app** that wants an SF-Pro-*like* feel everywhere, use a licensed or metrically-similar alternative: `google_fonts` package serving **Inter** (closest open geometric grotesque to SF Pro's aperture/x-height philosophy) is the standard substitute referenced throughout this family's foundations doc — never present it as "SF Pro," just as a visually-compatible stand-in [inferred].
- SF Symbols glyphs have the identical restriction — see `apple-design-materials/references/flutter-implementation.md` for the `cupertino_icons` / open icon-set alternatives.

---

## What the sibling skills' Flutter references cover

This file is intentionally thin. Depth lives in:

| Topic | File |
|---|---|
| Colors (CupertinoColors, dynamic light/dark, P3 gap), Dynamic Type, fonts, 8pt grid, bento layout | `apple-design-foundations/references/flutter-implementation.md` |
| Glass/blur/vibrancy, squircle corners, SF Symbols alternatives | `apple-design-materials/references/flutter-implementation.md` |

Motion/springs/haptics and OS-surface (sheets, tab bars, nav) Flutter recipes are not yet written for `apple-design-motion` / `apple-design-os` — until they exist, use the SDK primitives named in the table above (`SpringSimulation`, `HapticFeedback`) and cross-reference those skills' native recipes for the *behavior* to replicate, translating the timing/curve values by hand.

## Confidence summary

Flutter SDK behavior described here (`CupertinoApp` defaults, `BackdropFilter`, `HapticFeedback`, `cupertino_icons` as a default dependency, system-font inheritance on iOS) is `[documented]` against the public Flutter SDK API. Every named third-party package is `[inferred]` — this environment has no live pub.dev access, so verify name, current API surface, and maintenance status before depending on any of them.
