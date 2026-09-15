# Flutter Implementation — Motion, Gestures & Feedback

**Scope**: Dart/Flutter equivalents for the spring physics, gesture, hero-transition, haptic, and reduced-motion recipes in `motion-animation.md`, `gestures-interaction.md`, and `microinteractions-feedback.md`. Those files remain the source of truth for *why* — response/dampingFraction semantics, timing rationale, choreography rules. This file is the *how*, for a Cupertino-styled Flutter app rather than SwiftUI or CSS/JS.

Package names below are current as of this writing but **not version-pinned** — always check current API surface on pub.dev before depending on an exact method signature; anything not shipped in the Flutter SDK itself is marked `[inferred]` for that reason, even when the general approach is solid.

---

## 1. Spring physics in Flutter

### 1.1 The SDK primitives

Flutter's `dart:ui`-adjacent `flutter/physics.dart` (no package needed — it ships in the Flutter SDK) [documented] provides the same damped-harmonic-oscillator model Apple's springs are built on:

- `SpringDescription(mass, stiffness, damping)` — the raw physical parameters, same three quantities as §2.1 of `motion-animation.md`.
- `SpringDescription.withDampingRatio({mass, stiffness, ratio})` — the design-friendly form: `ratio` is `actual/critical` damping, i.e. **exactly** SwiftUI's `dampingFraction` (0 = infinite bounce, 1 = no overshoot). [documented]
- `SpringSimulation(spring, start, end, velocity)` — an analytic solution you drive an `AnimationController` with via `controller.animateWith(simulation)`. `velocity` is in the same units as `start`/`end` per second — this is the gesture-velocity-handoff slot.

```dart
import 'package:flutter/physics.dart';
import 'package:flutter/animation.dart';

class SpringToggle extends StatefulWidget {
  const SpringToggle({super.key});
  @override
  State<SpringToggle> createState() => _SpringToggleState();
}

class _SpringToggleState extends State<SpringToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, value: 0);
  bool _expanded = false;

  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 150, // see §1.2 for how to derive this from response
    ratio: 0.75,
  );

  void _toggle() {
    _expanded = !_expanded;
    final target = _expanded ? 1.0 : 0.0;
    _controller.animateWith(
      SpringSimulation(_spring, _controller.value, target, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: lerpDouble(80, 280, _controller.value),
          height: lerpDouble(80, 160, _controller.value),
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(
              lerpDouble(12, 24, _controller.value)!,
            ),
          ),
        ),
      ),
    );
  }
}
```

### 1.2 Converting Apple's `response` + `dampingFraction` to Flutter's `mass`/`stiffness`/`damping`

Apple's own WWDC23 conversion (quoted in `motion-animation.md` §2.1, assuming unit mass `m = 1`) is:

```
stiffness = (2π / response)²
damping   = 4π × dampingFraction / response
```

Flutter's `SpringDescription.withDampingRatio` computes `damping = ratio × criticalDamping`, and critical damping for `m = 1` is `2√stiffness = 2 × (2π/response) = 4π/response`. Substituting: `ratio × 4π/response = 4π × dampingFraction / response` — **algebraically identical** to Apple's formula when `ratio = dampingFraction`. [documented — this is a direct algebraic identity, not an approximation, as long as you keep `mass = 1` to match SwiftUI's default]

```dart
import 'dart:math' as math;
import 'package:flutter/physics.dart';

/// Converts a SwiftUI `.spring(response:dampingFraction:)` pair into a
/// Flutter [SpringDescription]. Mass defaults to 1 to match SwiftUI's
/// default — pass a different mass only if you changed it on the Apple side too.
SpringDescription appleSpring({
  required double response,
  required double dampingFraction,
  double mass = 1,
}) {
  final stiffness = mass * math.pow(2 * math.pi / response, 2).toDouble();
  return SpringDescription.withDampingRatio(
    mass: mass,
    stiffness: stiffness,
    ratio: dampingFraction,
  );
}
```

For the `duration` + `bounce` (iOS 17+) form, reuse the same conversion given in `motion-animation.md` §2.1 to first get `stiffness`/`damping`, then wrap directly:

```dart
/// SwiftUI's iOS17+ `.spring(duration:bounce:)`, bounce ∈ [-1, 1], 0 = no overshoot.
SpringDescription appleSpringDurationBounce({
  required double duration,
  required double bounce,
  double mass = 1,
}) {
  final stiffness = mass * math.pow(2 * math.pi / duration, 2).toDouble();
  final damping = bounce >= 0
      ? mass * (1 - 4 * math.pi * bounce / duration) * 2 * math.sqrt(stiffness)
      : mass * (4 * math.pi / (duration + 4 * math.pi * bounce));
  return SpringDescription(mass: mass, stiffness: stiffness, damping: damping);
}
```
`[inferred]` — the `bounce < 0` branch in particular is a direct port of the formula in `motion-animation.md` §2.1 and has not been cross-checked against Apple's actual implementation; verify visually against a real SwiftUI view if the exact overdamped feel matters.

### 1.3 A token set mirroring Apple's timing decision table

`motion-animation.md` §4.9.1's decision table gives concrete `response`/`dampingFraction` pairs per interaction type. Port them once as Dart constants so the whole app pulls from one source, exactly as the Swift side would reference `.spring(response:dampingFraction:)` literals:

```dart
/// Spring tokens ported from motion-animation.md §4.9.1's decision table.
/// [documented as a direct port of that table's response/dampingFraction pairs]
abstract final class AppleSprings {
  static SpringDescription get tapFeedback =>
      appleSpring(response: 0.25, dampingFraction: 0.85);
  static SpringDescription get toggle =>
      appleSpring(response: 0.30, dampingFraction: 0.80);
  static SpringDescription get inlineExpand =>
      appleSpring(response: 0.38, dampingFraction: 0.80);
  static SpringDescription get destructiveConfirm =>
      appleSpring(response: 0.40, dampingFraction: 0.95);
  static SpringDescription get sheetPresent =>
      appleSpring(response: 0.45, dampingFraction: 0.85);
  static SpringDescription get sheetDismiss =>
      appleSpring(response: 0.40, dampingFraction: 0.88);
  static SpringDescription get navigationPush =>
      appleSpring(response: 0.50, dampingFraction: 0.90);
  static SpringDescription get heroExpand =>
      appleSpring(response: 0.45, dampingFraction: 0.82);
  static SpringDescription get reveal => // visible ~3-6% overshoot, see §4.7
      appleSpring(response: 0.40, dampingFraction: 0.72);
}
```

| Token | Apple use case | Duration feel |
|---|---|---|
| `tapFeedback` | Button/scale press | 120–180 ms |
| `toggle` | Switch, chip select | 200–280 ms |
| `inlineExpand` | Accordion, inline reveal | 300–380 ms |
| `destructiveConfirm` | Swipe-to-delete confirm | 320–400 ms, no bounce |
| `sheetPresent` / `sheetDismiss` | Modal sheet | 350–420 ms / 300–380 ms |
| `navigationPush` | Full-screen push | 350–450 ms |
| `heroExpand` | Card → full-screen shared element | 400–500 ms |
| `reveal` | Achievement/unlock materialize | 350–500 ms, visible bounce |

### 1.4 Implicit animations — the easy 80% case

For simple state-driven transitions that don't need gesture-velocity handoff, Flutter's implicit animation widgets (`AnimatedContainer`, `AnimatedScale`, `AnimatedOpacity`, `AnimatedPositioned`, `AnimatedSwitcher`) are the equivalent of SwiftUI's `withAnimation(.spring(...))` for simple property changes — **with one caveat**: their `curve:` parameter takes a `Curve` (a cubic-bezier-like easing function sampled over a fixed `duration`), not a physically simulated spring. `Curves.easeOutBack` or `Curves.elasticOut` visually *resemble* a bouncy spring but do not have Apple's core properties from `motion-animation.md` §1.2 — they are not naturally interruptible mid-flight the way a `SpringSimulation`-driven controller is (interrupting an implicit animation snaps to a new `Tween`, which does carry the visual value forward but does not carry true physical velocity into the new curve).

Use implicit animations freely for **non-gestural** micro-interactions (toggles, badges, disabled-state fades). Use `AnimationController` + `SpringSimulation` (§1.1) whenever the motion originates from or must feel continuous with a drag/pan gesture.

```dart
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.lightImpact(); // see §3
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120), // §1.3 tapFeedback timing
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
```

### 1.5 `flutter_animate` — an ergonomic layer, still curve-based

`flutter_animate` [inferred — verify current API on pub.dev] gives a chainable, declarative syntax over the same implicit-animation engine — useful for entry/materialize motion (`motion-animation.md` §4.7) and staggered list reveals (§4.10.2) without hand-rolling `AnimatedBuilder` trees:

```dart
import 'package:flutter_animate/flutter_animate.dart'; // [inferred — verify on pub.dev]

Widget achievementCard(Widget content) {
  return content
      .animate()
      .fadeIn(duration: 350.ms)
      .scale(
        begin: const Offset(0.92, 0.92),
        end: const Offset(1, 1),
        curve: Curves.easeOutBack, // visual approximation of a bouncy spring
      );
}

// Staggered list entry — 30–50 ms per item per §4.10.2's "4–6 items" row
Widget staggeredList(List<Widget> rows) => Column(
      children: [
        for (final (i, row) in rows.indexed)
          row.animate().fadeIn(delay: (i * 40).ms, duration: 300.ms).slideY(
                begin: 0.08,
                curve: Curves.easeOut,
              ),
      ],
    );
```

This is still `Curve`-based under the hood, not a mass-spring simulation — same caveat as §1.4. For a reveal that must be interruptible by a subsequent user action, prefer §1.1's `SpringSimulation` route.

---

## 2. Interruptible, velocity-driven gestures

### 2.1 Draggable-dismiss sheet with velocity handoff

This is the direct Flutter port of the SwiftUI `DragGesture` → spring-dismiss recipe in `gestures-interaction.md` §"SwiftUI: DragGesture with Velocity-Aware Spring Dismiss": track the finger 1:1 during the drag (no animation), then on release feed the release velocity into a `SpringSimulation` so the sheet's momentum continues naturally into the settle — the WWDC18 "momentum preservation" principle from `motion-animation.md` §1.1.

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

class VelocityDismissSheet extends StatefulWidget {
  const VelocityDismissSheet({
    super.key,
    required this.child,
    required this.onDismissed,
  });
  final Widget child;
  final VoidCallback onDismissed;

  @override
  State<VelocityDismissSheet> createState() => _VelocityDismissSheetState();
}

class _VelocityDismissSheetState extends State<VelocityDismissSheet>
    with SingleTickerProviderStateMixin {
  // 0.0 = fully open, 1.0 = fully off-screen (dismissed).
  late final AnimationController _controller =
      AnimationController(vsync: this, value: 0)..addListener(_onTick);

  // See §2.2 — needed to read velocity out of an in-flight spring.
  SpringSimulation? _activeSimulation;
  final Stopwatch _stopwatch = Stopwatch();

  static const double _dismissExtentThreshold = 0.35; // fraction of sheet height
  static const double _dismissVelocityThreshold = 700; // logical px/s [inferred]

  void _onTick() => setState(() {});

  void _onPanDown(DragDownDetails details) {
    // A new gesture grabs the sheet mid-flight — freeze at current position.
    // controller.value already holds the correct in-flight offset.
    _controller.stop();
  }

  void _onPanUpdate(DragUpdateDetails details, double sheetHeight) {
    final next = _controller.value + details.delta.dy / sheetHeight;
    _controller.value = next.clamp(0.0, 1.0);
  }

  void _onPanEnd(DragEndDetails details, double sheetHeight) {
    final releaseVelocity = details.velocity.pixelsPerSecond.dy / sheetHeight;
    final shouldDismiss = _controller.value > _dismissExtentThreshold ||
        details.velocity.pixelsPerSecond.dy > _dismissVelocityThreshold;

    final target = shouldDismiss ? 1.0 : 0.0;
    final spring = shouldDismiss
        ? AppleSprings.sheetDismiss
        : AppleSprings.sheetPresent;

    final simulation = SpringSimulation(
      spring,
      _controller.value,
      target,
      releaseVelocity, // <-- the momentum handoff
    );

    _activeSimulation = simulation;
    _stopwatch
      ..reset()
      ..start();

    _controller.animateWith(simulation).whenComplete(() {
      if (target == 1.0) widget.onDismissed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetHeight = constraints.maxHeight;
        return GestureDetector(
          onPanDown: _onPanDown,
          onPanUpdate: (d) => _onPanUpdate(d, sheetHeight),
          onPanEnd: (d) => _onPanEnd(d, sheetHeight),
          child: Transform.translate(
            offset: Offset(0, _controller.value * sheetHeight),
            child: widget.child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 2.2 Reading velocity out of an in-flight spring (interruption)

`AnimationController` does not expose a general `velocity` getter for an arbitrary in-flight animation — but because `SpringSimulation.dx(time)` is an analytic function you already hold a reference to, you can query it directly at the elapsed time since you started it. This gives an **exact**, not estimated, velocity — cleaner than the frame-delta sampling the vanilla-JS recipe in `motion-animation.md` §3.3 has to do. `[inferred pattern — built from public SpringSimulation/AnimationController APIs, not an officially documented Flutter idiom]`

```dart
double _currentSimulationVelocity() {
  final sim = _activeSimulation;
  if (sim == null || !_stopwatch.isRunning) return 0;
  return sim.dx(_stopwatch.elapsedMilliseconds / 1000);
}

// Call before starting a *new* SpringSimulation mid-flight so the new
// animation inherits the old one's momentum — the "redirectable" property
// from motion-animation.md §1.2.
void _redirectTo(double newTarget) {
  final inheritedVelocity = _currentSimulationVelocity();
  _controller.stop();
  final simulation = SpringSimulation(
    AppleSprings.sheetPresent,
    _controller.value,
    newTarget,
    inheritedVelocity,
  );
  _activeSimulation = simulation;
  _stopwatch
    ..reset()
    ..start();
  _controller.animateWith(simulation);
}
```

### 2.3 Never block input behind an animation

Because `_controller.stop()` in §2.1/§2.2 is non-blocking and `GestureDetector` callbacks fire regardless of whether `_controller` is mid-animation, a new `onPanDown` always wins immediately — matching the WWDC18 rule "no animation blocks input" (`motion-animation.md` §1.1). Never gate a `GestureDetector` behind `if (!_controller.isAnimating)`; that reintroduces exactly the blocking behavior Apple's model forbids.

---

## 3. Haptics

Flutter's `HapticFeedback` class (`package:flutter/services.dart`) [documented] is intentionally coarse compared to `UIFeedbackGenerator` / `CHHapticEngine` — there is no `intensity:` parameter, no `.soft`/`.rigid` variants, no distinct success/warning/error trio, and no `prepare()` latency pre-warming. Treat the mapping below as **best-effort**, not 1:1.

| Flutter `HapticFeedback` | Rough iOS equivalent (`microinteractions-feedback.md` §2.2) | Fire on |
|---|---|---|
| `selectionClick()` | `UISelectionFeedbackGenerator` | Each increment of a continuous value change — custom picker/segmented drag, reorder crossing a row boundary |
| `lightImpact()` | `UIImpactFeedbackGenerator(.light)` | Small item pick, subtle button tap |
| `mediumImpact()` | `UIImpactFeedbackGenerator(.medium)` | Default collision, drag-and-drop land |
| `heavyImpact()` | `UIImpactFeedbackGenerator(.heavy)` | Large element snapping into place |
| `vibrate()` | No clean equivalent — closest to a generic buzz, not `UINotificationFeedbackGenerator`'s multi-tap success/warning/error patterns | Fallback "something happened" cue only |

`[documented]` gaps worth calling out explicitly rather than papering over:
- **No `.soft`/`.rigid` impact styles** and no `impactOccurred(intensity:)` equivalent — Flutter cannot scale force 0.0–1.0 like UIKit can.
- **No `UINotificationFeedbackGenerator` equivalent.** For a genuine three-pattern success/warning/error feel, either accept `vibrate()` as a lowest-common-denominator cue, or drop to a platform channel calling `UINotificationFeedbackGenerator` natively on iOS (and a separate Android path) — there is no portable pure-Dart API for it.
- **No `prepare()` — expect a small first-call latency** on some devices; there is no public workaround in the Flutter SDK.
- **Android haptics differ meaningfully.** Android's `HapticFeedbackConstants` (what Flutter calls through on that platform) vary far more by OEM/vibrator hardware than iOS's Taptic Engine does — don't assume `mediumImpact()` feels the same weight cross-platform. If precise custom vibration patterns matter (e.g., a game), consider the `vibration` package [inferred — verify pub.dev] for direct amplitude/pattern control on Android, kept behind a platform check since it has no iOS equivalent worth relying on.

```dart
import 'package:flutter/services.dart';

GestureDetector(
  onTapDown: (_) => HapticFeedback.lightImpact(),
  onTap: _submit,
  child: submitButton,
);

// Selection-style feedback for a custom continuous control
void _onSegmentDragged(int newIndex) {
  if (newIndex != _lastIndex) {
    HapticFeedback.selectionClick();
    _lastIndex = newIndex;
  }
}
```

Match the "fire on outcome, not on every tap" rule from `microinteractions-feedback.md` §2.2: reserve `mediumImpact()`/`heavyImpact()` for state changes (drop, snap, confirm), not routine button presses, or the app reads as haptic spam (§5, "Anti-Patterns", both source files).

---

## 4. Hero / continuity transitions

Flutter's built-in `Hero` widget is the closest analogue to `matchedGeometryEffect`/`zoom navigationTransition` (`motion-animation.md` §2.4): tag a widget with the same `Hero.tag` on both the source and destination routes, and `Navigator.push` automatically interpolates its frame across the transition. Both `MaterialApp` and `CupertinoApp` install a default `HeroController`, so this works unmodified in a Cupertino-only app. [documented]

```dart
// Source — grid cell
GestureDetector(
  onTap: () => Navigator.of(context).push(
    CupertinoPageRoute(builder: (_) => DetailPage(item: item)),
  ),
  child: Hero(
    tag: item.id,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(item.thumbnailUrl, fit: BoxFit.cover),
    ),
  ),
);

// Destination — detail screen
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.item});
  final Item item;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Hero(
        tag: item.id,
        // Custom shuttle builder lets you drive the in-flight frame with an
        // eased curve rather than Flutter's default linear Rect.lerp — a step
        // closer to Apple's spring-driven geometry morph. [inferred]
        flightShuttleBuilder: (context, animation, direction, from, to) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: to.widget,
          );
        },
        child: Image.network(item.fullUrl, fit: BoxFit.cover),
      ),
    );
  }
}
```

**Where this falls short of native, honestly:**
- `Hero`'s default `RectTween` linearly (or arc-)interpolates position and size; it does **not** interpolate corner radius or produce Apple's continuous-corner ("squircle") morph between a small rounded thumbnail and a sharp-cornered full-screen destination — see `apple-design-materials` for the squircle gap generally. You must build corner-radius interpolation yourself inside a `flightShuttleBuilder` (animate a `ClipRRect`'s radius alongside the hero) if that detail matters. `[inferred]`
- The `zoom` navigation transition's system-controlled spring (`motion-animation.md` §2.4, §4.11.1) is not something Flutter's `Hero` reproduces — you supply the curve/duration yourself; there's no "system default" spring tuned by Apple to fall back on.
- Interactive **back-swipe with Hero in flight** works out of the box on `CupertinoPageRoute` (its built-in back gesture drives the same `Navigator` transition Hero listens to), but redirecting the Hero animation mid-swipe uses the platform's own interruption handling, not the `SpringSimulation` machinery in §2 — the two systems don't currently compose.

---

## 5. Context menus and swipe actions

### 5.1 `CupertinoContextMenu` — long-press preview + menu

This is a direct, SDK-native port of `gestures-interaction.md` §"Context Menus (Long-Press Preview + Menu)": long-press blurs the background, lifts the child into a preview, and shows an actions list. [documented]

```dart
CupertinoContextMenu(
  actions: [
    CupertinoContextMenuAction(
      trailingIcon: CupertinoIcons.square_arrow_up,
      onPressed: () => Navigator.pop(context),
      child: const Text('Share'),
    ),
    CupertinoContextMenuAction(
      trailingIcon: CupertinoIcons.archivebox,
      onPressed: () => Navigator.pop(context),
      child: const Text('Archive'),
    ),
    CupertinoContextMenuAction(
      isDestructiveAction: true,
      trailingIcon: CupertinoIcons.delete,
      onPressed: () => Navigator.pop(context),
      child: const Text('Delete'),
    ),
  ],
  child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(photo.url, fit: BoxFit.cover),
  ),
);
```

Keep the source's rules: destructive actions last and marked (`isDestructiveAction: true`), under ~6 items, one level deep — the widget doesn't enforce any of that for you. One real gap: `CupertinoContextMenu` only offers the full-screen darkened preview presentation; native iOS can also show a compact anchored menu without the full blur treatment in some contexts, which Flutter's version does not distinguish. `[observed]`

### 5.2 `Dismissible` — simple swipe-to-delete

For the common single-action "Mail-style" swipe (`gestures-interaction.md` §"Swipe Actions on List Rows"), the SDK's `Dismissible` covers the full-swipe-commits pattern directly: [documented]

```dart
Dismissible(
  key: ValueKey(item.id),
  direction: DismissDirection.endToStart, // trailing edge = destructive, per HIG
  background: Container(
    color: CupertinoColors.destructiveRed,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
  ),
  onDismissed: (_) => _removeItem(item),
  child: CupertinoListTile(title: Text(item.title)),
);
```

`Dismissible` only supports one commit action per swipe direction and always requires a full-swipe or drop-past-threshold — it has no "reveal buttons that stay put" mode.

### 5.3 `flutter_slidable` — multi-action reveal

For the actual Mail pattern — a short swipe **reveals** multiple tappable buttons (Flag, Archive, Delete) without auto-committing — reach for the `flutter_slidable` package. `[inferred — verify current widget/API names on pub.dev before depending on this exact shape]`

```dart
import 'package:flutter_slidable/flutter_slidable.dart'; // [inferred — verify on pub.dev]

Slidable(
  key: ValueKey(item.id),
  endActionPane: ActionPane(
    motion: const DrawerMotion(), // check pub.dev for the current motion catalog
    children: [
      SlidableAction(
        onPressed: (_) => _archive(item),
        backgroundColor: CupertinoColors.systemOrange,
        icon: CupertinoIcons.archivebox,
        label: 'Archive',
      ),
      SlidableAction(
        onPressed: (_) => _delete(item),
        backgroundColor: CupertinoColors.destructiveRed,
        icon: CupertinoIcons.delete,
        label: 'Delete',
      ),
    ],
  ),
  child: CupertinoListTile(title: Text(item.title)),
);
```

---

## 6. Reduced motion

`MediaQuery.of(context).disableAnimations` reflects the OS-level "Reduce Motion" accessibility toggle on both iOS (`UIAccessibility.isReduceMotionEnabled`) and Android's equivalent setting. [documented] Gate spring/hero/parallax motion behind it exactly per the rule in `motion-animation.md` §2.5: **replace spatial movement with a cross-fade, don't just cut motion to nothing.**

```dart
bool reduceMotionEnabled(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;

/// Returns a spring if motion is allowed, or null to signal "use a plain
/// fade instead" — callers branch on this rather than silently zeroing
/// duration, per the "never just disable" rule.
SpringDescription? motionAwareSpring(BuildContext context, SpringDescription full) =>
    reduceMotionEnabled(context) ? null : full;
```

Applied to the entry/materialize pattern from `motion-animation.md` §4.7:

```dart
Widget materializeCard(BuildContext context, {required bool visible}) {
  final reduceMotion = reduceMotionEnabled(context);
  return AnimatedOpacity(
    opacity: visible ? 1 : 0,
    duration: Duration(milliseconds: reduceMotion ? 200 : 350),
    curve: Curves.easeInOut,
    child: reduceMotion
        ? achievementCardContent // no scale — opacity only
        : AnimatedScale(
            scale: visible ? 1.0 : 0.92,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            child: achievementCardContent,
          ),
  );
}
```

Apply the same gate to §2's `VelocityDismissSheet`: when `reduceMotionEnabled(context)` is true, skip the `SpringSimulation` overshoot entirely and drive `_controller` with a plain `Tween`/`Curves.easeInOut` of ~150–200 ms instead — same destination, no bounce, matching the source's "retain brief functional animation, drop the spatial travel" rule.

---

## 7. Package reference

| Package | Replaces / augments | Confidence |
|---|---|---|
| `flutter/physics.dart` (SDK) | `SpringSimulation`/`SpringDescription` — the actual spring engine used throughout §1–2 | `[documented]` — ships with Flutter, not a pub.dev dependency |
| `flutter/services.dart` `HapticFeedback` (SDK) | `UIFeedbackGenerator` (partial, coarser) | `[documented]` |
| `Hero` (SDK) | `matchedGeometryEffect` / `zoom` transitions (partial — no corner-radius morph) | `[documented]` |
| `CupertinoContextMenu` (SDK) | iOS long-press context menu | `[documented]` |
| `Dismissible` (SDK) | Single-action full-swipe delete | `[documented]` |
| `flutter_animate` | Ergonomic chained implicit animations, staggered reveals | `[inferred — verify on pub.dev]` |
| `flutter_slidable` | Multi-action Mail-style swipe rows | `[inferred — verify on pub.dev]` |
| `vibration` | Custom Android vibration amplitude/patterns beyond `HapticFeedback` | `[inferred — verify on pub.dev]` |

---

## 8. Honest gaps vs. native

- **No true haptic pattern authoring in pure Dart.** `CHHapticEngine`'s custom `hapticIntensity`/`hapticSharpness` curves (`microinteractions-feedback.md` §2.4) have no Flutter equivalent short of a platform channel to native Swift/Kotlin.
- **No system-tuned "zoom" spring to inherit.** Every hero/spring value in this file is one you must choose and tune yourself; there is no OS-provided default the way `zoom navigationTransition` gets one on iOS 18.
- **Curve-based implicit animations are not springs.** `Curves.elasticOut`/`easeOutBack` look bouncy but do not carry real velocity across an interruption — don't use them where §1.1's "interruptible + redirectable" properties actually matter (an in-progress drag, a repeatedly-tapped toggle).
- **Reduce-Motion has one flag, not Apple's finer-grained system.** `MediaQuery.disableAnimations` is a single boolean; there's no separate "Reduce Transparency" or per-animation-class override to branch on the way a native app might combine several `UIAccessibility` flags.
- **No portable equivalent of `prepare()`.** Latency pre-warming for haptics is an iOS-only concept with no Flutter-level hook.

Everything else in this file — spring math, gesture velocity handoff, Hero, context menus, swipe actions, reduced motion gating — has a workable, idiomatic Flutter path; the honest gaps above are narrow and worth calling out to whoever is reviewing the port rather than quietly working around.
