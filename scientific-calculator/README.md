# Scientific Calculator

A scientific calculator app for Android, built to compete with the free tier
of apps like Mathlab's Graphing Calculator and HiEdu — and, for everyday use
outside the exam room, with physical TI-84-class hardware.

## Status

**TI-84 Plus CE parity, plus two pieces of the TI-Nspire CX II CAS-tier
stretch goal — feature-complete:**

- **Calculator** — arithmetic, trig (degrees/radians), logs, powers/roots,
  a familiar TI-style keypad, selectable layouts (including a
  high-contrast/large-target accessible skin), configurable sound/haptic
  key feedback.
- **Graph** — function, parametric, polar, and sequence plotting with
  pan/zoom, a table of values, and multi-function overlays.
- **3D** — `z = f(x, y)` surface plotting as a rotated wireframe (drag to
  orbit, depth-shaded so it reads as 3D without a full hidden-surface
  renderer).
- **Geometry** — construct points, segments, lines, and circles; midpoint,
  distance, and angle tools; drag any point and everything built from it
  follows.
- **Matrix** — add/subtract/multiply, transpose, determinant, inverse,
  row-reduced echelon form.
- **Statistics** — 1-variable summary stats; regression (linear through
  quartic, power, exponential, logarithmic); normalcdf/invNorm and
  binomial pdf/cdf distributions.
- **Finance** — a TVM solver (solve for any of N/I%/PV/PMT/FV given the
  other four, ordinary or due).
- **Solve** — a numeric equation solver ("solve for x", the same
  starting-guess model a physical calculator's solver uses); exact
  polynomial root-finding for degree 1-4 (including complex roots) with a
  numeric fallback for degree 5+; symbolic derivative and simplify.

138 tests passing: engine/module unit tests (many cross-checked against
`numpy`/`scipy` reference values — see test file comments) plus
integration tests that navigate the actual UI, including gesture-level
tests that verify a simulated drag reaches each canvas's controller (see
the bug note below on why that distinction mattered).

**Still out of scope** (the two heaviest items of the original CAS/3D
wishlist): a general-purpose CAS (symbolic equation solving beyond
polynomials, symbolic integration) and true equation-solving inside the
geometry tool. See the Roadmap.

## Why Flutter

- Single codebase, compiles to real native code for the published Android
  app (not a WebView wrapper).
- `flutter run -d chrome` / `flutter build web` gives a fully working browser
  build to test against before ever touching the Play Store.
- `CustomPainter` is what the 2D graph, 3D surface, and geometry canvases
  are all built on.

## Project layout

```
lib/
  core/            # Pure Dart: expression evaluation, calculator state,
                    # symbolic derivative/simplify, numeric equation solver,
                    # exact polynomial root-finding.
  graphing/         # 2D viewport math, function sampling, controller, painter.
  graphing3d/       # 3D rotation/projection math, surface sampling,
                    # controller, painter.
  geometry/         # Construction model (points/shapes), controller, painter,
                    # plain-geometry formulas (distance/midpoint/angle).
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
                    # (tab navigation, settings access, end-to-end
                    # computations through the real UI) and
                    # canvas_gesture_test (see the bug note below).
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
  parser (`math_expressions`) only understands radians; the 2D/3D samplers
  and equation solver reuse the same engine by binding `x`/`y`/`t`/`theta`/
  `n` as a variable rather than re-parsing per sample.
- **All three keypad layouts render the same button set** — "accessible" is
  a different density/contrast pass over the same keypad, not a
  stripped-down second app.
- **Accessibility is built in, not retrofitted:** every button carries a
  screen-reader label distinct from its glyph, touch targets have a 48dp
  floor at every density, and sound/haptic key feedback are independently
  toggleable (sound defaults off, haptics on).
- **Numeric methods are cross-checked, not just internally consistent** —
  the statistics, finance, and polynomial-root engines were verified
  against `numpy`/`scipy` reference values during development (regression
  coefficients, invNorm, binomial pdf/cdf, TVM round-trips across all five
  solve directions, polynomial roots up to degree 5), not just tested for
  self-consistency.
- **Geometry construction is by point ID, not fixed coordinates** — a
  segment/circle/line stores which points it connects, so dragging a point
  moves everything built from it. A computed point (a midpoint) is a
  snapshot at creation time, not a live constraint — dragging its parents
  afterward won't move it. That's a deliberate scope line (no constraint
  solver), not an oversight.

### A real bug worth documenting: gesture-arena conflict with `TabBarView`

While building the Geometry tool, an end-to-end test that actually
simulated a canvas tap (rather than calling the controller directly)
found that **nothing happened** — no exception, just silence. The same
pattern existed on the Graph and 3D canvases (pan/zoom, drag-to-rotate)
and was equally broken there, undetected until this point because their
tests only exercised the controller logic directly, never a real
simulated gesture through the widget tree.

Root cause: each canvas is a `GestureDetector` (with `onScale*`/`onPan*`)
hosted inside `HomeShell`'s `TabBarView`. `TabBarView` is built on
`PageView`, which has its own horizontal drag recognizer competing in the
same gesture arena. A `TapGestureRecognizer` resolves immediately on
release regardless (unambiguous), so plain taps elsewhere in the app were
fine — but `Pan`/`Scale` recognizers are drag-family and lost the arena to
the ancestor `PageView` even for a stationary tap with zero movement.
(Separately, `behavior: HitTestBehavior.opaque` was also needed and added
to every canvas — a bare `CustomPaint` with no child doesn't claim hit
tests on its own, so without it the ancestor issue wouldn't even have been
reachable.)

Fix: `TabBarView(physics: const NeverScrollableScrollPhysics(), ...)` in
`HomeShell`. Every tab is already reached by tapping the `TabBar`, not by
swiping, so disabling swipe cost nothing and resolved the conflict for
all three canvases at once. `canvas_gesture_test.dart` now verifies this
directly — not "no exception was thrown" (which the bug would have passed
too) but that a simulated drag actually changes controller state,
reproducing the exact `TabBarView` structure the bug depended on.

## Running it

```
flutter pub get
flutter run -d chrome   # or an Android device/emulator
flutter test             # 138 tests: engine correctness + UI integration
```

**Known gap in this dev environment:** the actual `flutter build apk`
hasn't been run here. Investigated directly: this container's network
policy blocks `dl.google.com`, and while `maven.google.com` itself isn't
blocked, it 301-redirects straight to `dl.google.com` — so Gradle's
Android Gradle Plugin resolution is blocked at the infrastructure level,
not just the SDK-download step, and there's no way around it from this
environment. `flutter analyze` (static analysis) and `flutter build web`
(a full real build of the same Dart code, same UI layer) both succeed,
and there is no Android-specific code in this project beyond untouched
`flutter create` boilerplate, so an APK build failure would be
surprising — but it hasn't been directly verified. Worth doing before a
Play Store upload, ideally with a real on-device pass (TalkBack, haptics,
and the touch-based canvases all deserve a physical-device check that
`flutter test` can't fully substitute for).

## Roadmap

What's left is the genuinely large, separate undertakings intentionally
kept out of scope:

1. **A general-purpose CAS** — symbolic equation solving for arbitrary
   (non-polynomial) equations, symbolic integration. `math_expressions`
   provides derivative/simplify (already used) and the `equations` package
   provides exact polynomial roots (already used), but nothing covers
   solving a general transcendental equation symbolically; this would mean
   adopting a larger CAS library rather than writing one from scratch.
2. **Constraint-solving geometry** — live-updating computed objects
   (a midpoint that actually tracks its parents), plus more construction
   tools (perpendicular/parallel lines, polygons, transformations).
3. **Verify the Android build** — run `flutter build apk`/`appbundle` in an
   environment that can reach the Android SDK (see the network-policy note
   above), then a real on-device pass.
