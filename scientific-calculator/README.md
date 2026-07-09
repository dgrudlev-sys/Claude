# Scientific Calculator

A scientific calculator app for Android, built to compete with the free tier
of apps like Mathlab's Graphing Calculator and HiEdu — and, for everyday use
outside the exam room, with physical TI-84-class hardware.

## Status

**V1 scope (in progress):** scientific calculator — arithmetic, trig
(degrees/radians), logs, powers/roots, a familiar TI-style keypad layout,
selectable layouts (including a high-contrast/large-target accessible skin),
and configurable sound/haptic feedback on key press.

**Not yet built:** graphing, matrices, statistics/regression, the finance
(TVM) solver, and CAS/symbolic math — see the roadmap below.

## Why Flutter

- Single codebase, compiles to real native code for the published Android
  app (not a WebView wrapper).
- `flutter run -d chrome` / `flutter build web` gives a fully working browser
  build to test against before ever touching the Play Store.
- `CustomPainter` is well suited to the graphing engine this app will need
  next.

## Project layout

```
lib/
  core/            # Pure Dart: expression evaluation, calculator state.
                    # No Flutter imports — this is the testable math layer.
  services/        # Settings persistence, key-press feedback.
  theme/           # Layout skins (Classic / Compact / Accessible) and colors.
  widgets/         # Keypad, buttons, display.
  screens/         # Calculator screen, settings screen.
test/
  calculator_engine_test.dart   # Math correctness (arithmetic, trig, degree
                                 # conversion edge cases, error handling).
  widget_test.dart               # End-to-end: simulated key taps -> display.
```

## Design notes

- **Keypad layout is deliberately TI-familiar** (key positions, `2nd` shift
  key, MathPrint-style natural display) so switching from a physical
  calculator has no learning curve — but the color identity is original
  (warm charcoal/amber), not TI's navy/silver trade dress.
- **Degree-mode trig** is handled by rewriting the expression before it hits
  the parser (`sin(30)` → `sin(pi/180*30)` for direct trig; inverse trig is
  wrapped with paren-matching so it converts only its own term even inside a
  larger expression — see `CalculatorEngine` and its tests). The underlying
  parser (`math_expressions`) only understands radians.
- **All three layouts render the same button set** — "accessible" is a
  different density/contrast pass over the same keypad, not a stripped-down
  second app. New buttons only need to be added once.
- **Accessibility is built in, not retrofitted:** every button carries a
  screen-reader label distinct from its glyph, touch targets have a 48dp
  floor at every density, and sound/haptic key feedback are independently
  toggleable (sound defaults off, haptics on).

## Running it

```
flutter pub get
flutter run -d chrome   # or an Android device/emulator
flutter test             # 19 tests: engine correctness + interaction flow
```

## Roadmap

1. **Graphing** — function/parametric/polar/sequence plotting with a table
   of values (the biggest remaining lift; needs a `CustomPainter` canvas).
2. **Matrices, statistics/regression, finance (TVM) solver** — deterministic
   math, no new architecture needed, matches TI-84 Plus CE parity.
3. **CAS/symbolic math, 3D graphing** (TI-Nspire CX II CAS-tier) — planned
   as a fast-follow on an existing open-source CAS library rather than a
   from-scratch symbolic engine; explicitly out of scope for V1.
