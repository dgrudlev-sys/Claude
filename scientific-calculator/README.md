# Scientific Calculator

A scientific calculator app for Android, built to compete with the free tier
of apps like Mathlab's Graphing Calculator and HiEdu — and, for everyday use
outside the exam room, with physical TI-84-class hardware.

## Status

**V1 (TI-84 Plus CE parity) — feature-complete:**

- **Calculator** — arithmetic, trig (degrees/radians), logs, powers/roots,
  a familiar TI-style keypad, selectable layouts (including a
  high-contrast/large-target accessible skin), configurable sound/haptic
  key feedback.
- **Graph** — function, parametric, polar, and sequence plotting with
  pan/zoom, a table of values, and multi-function overlays.
- **Matrix** — add/subtract/multiply, transpose, determinant, inverse,
  row-reduced echelon form.
- **Statistics** — 1-variable summary stats; regression (linear through
  quartic, power, exponential, logarithmic); normalcdf/invNorm and
  binomial pdf/cdf distributions.
- **Finance** — a TVM solver (solve for any of N/I%/PV/PMT/FV given the
  other four, ordinary or due).
- **Solve** — a numeric equation solver ("solve for x", the same
  starting-guess model a physical calculator's solver uses) plus symbolic
  derivative and simplify, built on `math_expressions`' own symbolic
  primitives.

98 tests passing: engine/module unit tests (many cross-checked against
`numpy`/`scipy` reference values — see test file comments) plus
integration tests that navigate the actual UI.

**Explicitly out of scope for this pass** (TI-Nspire CX II CAS-tier, not
TI-84-tier): a true CAS (symbolic equation solving, not just derivative/
simplify), 3D graphing, and a geometry app. These would each be a
significant, separate undertaking — see the Roadmap.

## Why Flutter

- Single codebase, compiles to real native code for the published Android
  app (not a WebView wrapper).
- `flutter run -d chrome` / `flutter build web` gives a fully working browser
  build to test against before ever touching the Play Store.
- `CustomPainter` is what the graphing canvas is built on (pan/zoom,
  multi-curve rendering, axis/grid labeling).

## Project layout

```
lib/
  core/            # Pure Dart: expression evaluation, calculator state,
                    # symbolic derivative/simplify, numeric equation solver.
  graphing/         # Viewport math, function sampling, the graph controller
                    # and CustomPainter.
  matrix/           # Matrix arithmetic (Gaussian/Gauss-Jordan elimination).
  statistics/       # 1-var stats, regression suite, distributions.
  finance/          # TVM solver.
  services/        # Settings persistence, key-press feedback.
  theme/           # Layout skins (Classic / Compact / Accessible) and colors.
  widgets/         # Keypad, buttons, display.
  screens/         # One screen per mode, plus the HomeShell tying them
                    # together behind a shared tab bar and settings icon.
test/
  *_test.dart      # One test file per engine/module, plus home_shell_test
                    # (tab navigation, settings access, an end-to-end
                    # matrix computation through the real UI).
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
  parser (`math_expressions`) only understands radians; the graphing
  sampler and equation solver reuse the same engine by binding `x`/`t`/
  `theta`/`n` as a variable rather than re-parsing per sample.
- **All three keypad layouts render the same button set** — "accessible" is
  a different density/contrast pass over the same keypad, not a
  stripped-down second app.
- **Accessibility is built in, not retrofitted:** every button carries a
  screen-reader label distinct from its glyph, touch targets have a 48dp
  floor at every density, and sound/haptic key feedback are independently
  toggleable (sound defaults off, haptics on).
- **Numeric methods are cross-checked, not just internally consistent** —
  the statistics and finance engines were verified against `numpy`/`scipy`
  reference values during development (regression coefficients, invNorm,
  binomial pdf/cdf, TVM round-trips across all five solve directions), not
  just tested for self-consistency.

## Running it

```
flutter pub get
flutter run -d chrome   # or an Android device/emulator
flutter test             # 98 tests: engine correctness + UI integration
```

**Known gap in this dev environment:** the actual `flutter build apk`
hasn't been run here — this container's network policy blocks
`dl.google.com`, so the Android SDK can't be installed to verify it.
`flutter analyze` (static analysis) and `flutter build web` (a full real
build of the same Dart code, same UI layer) both succeed, and there is no
Android-specific code in this project beyond untouched `flutter create`
boilerplate, so an APK build failure would be surprising — but it hasn't
been directly verified. Worth doing before a Play Store upload.

## Roadmap

Everything above is done. What's left is the genuinely large, separate
undertakings intentionally deferred out of V1:

1. **A true CAS** — symbolic equation solving (isolating x algebraically,
   not just the numeric solver this app ships with), symbolic integration.
   `math_expressions` provides derivative/simplify primitives (already
   used) but nothing solve-oriented; this would mean adopting an existing
   open-source CAS library rather than writing one from scratch.
2. **3D graphing** — a different rendering approach entirely (real
   perspective/rotation, not the 2D `CustomPainter` this app has).
3. **A geometry app** — dynamic geometry construction, unrelated to
   anything built so far.
4. **Verify the Android build** — run `flutter build apk`/`appbundle` in an
   environment that can reach the Android SDK, and do a real on-device
   pass (the accessibility features in particular — TalkBack, haptics —
   need a physical device or emulator, not just `flutter test`).
