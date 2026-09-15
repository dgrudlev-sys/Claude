# Flutter Implementation — Accessibility & Marketing Tactics
Scope: translating this skill's HIG-derived accessibility bar and marketing/brand tactics into Flutter/Dart. The "why" (curb-cut effect, POUR, feeling-before-feature) lives in `accessibility-inclusive.md` and `marketing-tactics-brand.md` — this file is the "how" for a Flutter app, not a website. Claims follow the same confidence convention: `[documented]` = verifiable Flutter/Dart API behavior, `[inferred]` = reasonable but unconfirmed recommendation, `[speculative]` = untested idea.

---

## Part 1 — Accessibility in Flutter

Flutter does not use the DOM's ARIA model or UIKit's `UIAccessibility` protocol directly — it builds its own **semantics tree**, which the engine then bridges to VoiceOver on iOS and TalkBack on Android through platform accessibility APIs. [documented] The design obligations from `accessibility-inclusive.md` (labels, hints, traits, grouping, reading order, custom actions, dynamic announcements) all have a direct Flutter counterpart via the `Semantics` widget and the semantics properties built into Material/Cupertino widgets.

### 1.1 The `Semantics` widget — VoiceOver/TalkBack contract

| HIG concept (accessibility-inclusive.md) | Flutter equivalent |
|---|---|
| Accessibility label | `Semantics(label: ...)` or a widget's own `semanticLabel` (e.g. `Icon(semanticLabel: ...)`) |
| Accessibility hint | `Semantics(hint: ...)` |
| Trait `.isButton` | `Semantics(button: true)` |
| Trait `.isHeader` | `Semantics(header: true)` |
| Trait `.isSelected` | `Semantics(selected: true)` |
| Trait `.isImage` | `Semantics(image: true)` |
| Accessibility value (range/state) | `Semantics(value: '...')` |
| Element grouping | `MergeSemantics` / `ExcludeSemantics` |
| Custom actions (Actions rotor) | `Semantics(customSemanticsActions: {...})` |
| Dynamic content announcement | `SemanticsService.announce(...)` |
| Reading order override | `Semantics(sortKey: OrdinalSortKey(...))` |

Most built-in Material and Cupertino widgets (`ElevatedButton`, `IconButton`, `Checkbox`, `Switch`) already populate sensible semantics (`button: true`, `enabled`, `checked`) — the gap that needs manual work is almost always **icon-only buttons, custom-painted controls, and decorative images**, exactly as the source doc calls out for `heart.fill`-style icons.

```dart
// Icon-only button: the icon glyph is not a label.
Semantics(
  label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
  hint: 'Double tap to toggle',
  button: true,
  child: IconButton(
    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
    onPressed: toggleFavorite,
  ),
)
```

```dart
// Header trait — makes the element reachable via TalkBack/VoiceOver
// heading navigation, the rotor equivalent on Android/iOS. [documented]
Semantics(
  header: true,
  child: Text('Recent Orders', style: Theme.of(context).textTheme.headlineSmall),
)
```

### 1.2 Grouping visual clusters — `MergeSemantics` / `ExcludeSemantics`

The source doc's SwiftUI `.accessibilityElement(children: .combine/.ignore)` pattern maps to two distinct Flutter widgets:

```dart
// Combine icon + text into ONE spoken node instead of two disconnected reads.
MergeSemantics(
  child: Row(
    children: [
      ExcludeSemantics(child: Icon(Icons.mail)), // decorative — hidden from the tree
      const Text('3 unread messages'),
    ],
  ),
)

// A purely decorative image: never announced.
ExcludeSemantics(
  child: Image.asset('assets/hero_bg.jpg'),
)
```

### 1.3 Custom actions and dynamic updates

```dart
// Custom actions — TalkBack "Explore by touch" / VoiceOver rotor equivalent.
Semantics(
  customSemanticsActions: {
    const CustomSemanticsAction(label: 'Mark as read'): markRead,
    const CustomSemanticsAction(label: 'Delete'): deleteMessage,
  },
  child: MessageRow(message: message),
)

// Announce a state change that isn't tied to a focus move — the
// UIAccessibility.post(notification:) equivalent. [documented]
SemanticsService.announce('Signed in successfully', TextDirection.ltr);
```

### 1.4 Dynamic Type — reflow via `MediaQuery.textScalerOf`

Flutter has no direct equivalent of iOS's five discrete Dynamic Type "Accessibility sizes" — it exposes a continuous `TextScaler` instead, driven by the OS text-size setting on both iOS and Android. [documented] The design obligation is the same as the source doc: **no fixed-height text containers, and a horizontal→vertical layout pivot at large scale.**

```dart
// Read the current OS-driven scale factor.
final TextScaler scaler = MediaQuery.textScalerOf(context);

// Flutter has no built-in "isAccessibilitySize" boolean (unlike SwiftUI's
// dynamicTypeSize.isAccessibilitySize) — approximate the same threshold by
// scaling a representative body size and comparing. [inferred]
bool isLargeTextScale(BuildContext context) {
  final scaled = MediaQuery.textScalerOf(context).scale(17); // 17pt ~ iOS body default
  return scaled >= 30; // heuristic threshold — tune against your own type scale
}
```

```dart
// The HStack → VStack pivot from accessibility-inclusive.md, in Flutter.
class AdaptiveRow extends StatelessWidget {
  const AdaptiveRow({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isLargeTextScale(context)) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    return Row(children: children);
  }
}
```

Layout rules that follow from this, mirroring the source doc's constraints:
- Never wrap text in a `SizedBox`/`Container` with a fixed `height` — let it grow. Use `Flexible`/`Expanded` inside `Row`/`Column`, not fixed pixel heights.
- Prefer `Wrap` over a fixed-width `Row` for label/chip clusters that must reflow at large text scale.
- SF Symbols' automatic Dynamic-Type scaling has no Flutter equivalent for `Icon` glyphs — icon size does not scale with text by default. Scale it manually if the icon sits beside scaled text: `Icon(Icons.star, size: 20 * MediaQuery.textScalerOf(context).scale(1.0))` `[inferred]`.
- Avoid `FontWeight.w300` (Light) or thinner for body text; `FontWeight.w400`/`w500` minimum, matching the source doc's "avoid light font weights" rule.

**Testing at large text scale** — override the platform's scale factor in a widget test rather than relying on a physical device:

```dart
testWidgets('feature row reflows to a Column at large text scale', (tester) async {
  tester.platformDispatcher.textScaleFactorTestValue = 3.0;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(const MaterialApp(home: AdaptiveRow(children: [Text('A'), Text('B')])));

  expect(find.byType(Column), findsOneWidget);
});
```
`[documented]` — `platformDispatcher.textScaleFactorTestValue` is the supported `flutter_test` hook for this; verify the exact API surface against your installed Flutter SDK version, since test-harness APIs move between stable channels.

### 1.5 Reduce Motion — `MediaQuery.disableAnimationsOf`

Flutter exposes the OS-level Reduce Motion preference (iOS Settings → Accessibility → Motion; Android's "Remove animations") as a single boolean on `MediaQuery`. [documented] This is the direct equivalent of SwiftUI's `@Environment(\.accessibilityReduceMotion)` and the web's `prefers-reduced-motion`.

```dart
final reduceMotion = MediaQuery.disableAnimationsOf(context);

AnimatedContainer(
  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
  curve: Curves.easeOut,
  color: isSelected ? Colors.blue : Colors.grey.shade200,
)
```

```dart
// Gating a spring-driven micro-interaction (see apple-design-motion for the
// spring recipes themselves) — snap instead of animate.
class PulsingBadge extends StatefulWidget {
  const PulsingBadge({super.key});
  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    if (!MediaQuery.disableAnimationsOf(context)) {
      _controller.repeat(reverse: true);
    }
    // If disableAnimationsOf can change mid-session, re-check in didChangeDependencies
    // and stop()/repeat() the controller accordingly. [inferred]
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ScaleTransition(
      scale: reduceMotion
          ? const AlwaysStoppedAnimation(1.0)
          : Tween(begin: 1.0, end: 1.15).animate(_controller),
      child: const CircleAvatar(radius: 8, backgroundColor: Colors.blue),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

Gate `Hero` transitions and page-route animations the same way: check `MediaQuery.disableAnimationsOf(context)` before wrapping a widget in `Hero`, or supply a custom `PageTransitionsTheme` that substitutes a fade for a slide/zoom when the flag is set `[inferred]`. Flutter's default `PageTransitionsTheme` does **not** automatically honor Reduce Motion — this is a gap you must close explicitly, unlike SwiftUI where system-provided transitions do respect it more often.

### 1.6 Reduce Transparency — the gap, and the workaround

**There is no `MediaQuery.disableTransparencyOf` or equivalent flag in the Flutter SDK as of this writing.** [documented — absence] Flutter surfaces Reduce Motion, bold text (`MediaQuery.boldTextOf`), high contrast (`MediaQuery.highContrastOf`), and invert colors, but **not** Reduce Transparency. A `BackdropFilter`-blurred glass surface (the Flutter equivalent of `UIVisualEffectView`/`backdrop-filter`) has no first-party signal to fall back to opaque.

Two workarounds, in order of fidelity:

1. **Read the OS setting via a plugin.** A community plugin such as `flutter_accessibility_service` (Android-focused; verify current iOS support and maintenance status on pub.dev before depending on it) can expose some OS accessibility settings through platform channels. `[inferred — exact API and Reduce-Transparency coverage unconfirmed; check the plugin's README against your target OS versions]`
2. **Build a manual in-app toggle.** Ship your own Settings → Accessibility → "Reduce Transparency" switch, persisted with `shared_preferences`, and gate every `BackdropFilter`/glass surface on that app-level flag instead of an OS one. This does not read the user's system-wide preference, but it closes the practical gap and is the more reliably shippable option. `[inferred]`

```dart
// App-level Reduce Transparency flag, following the source doc's requirement
// that every glass surface has a documented opaque fallback.
class AccessibilityPrefs extends InheritedWidget {
  const AccessibilityPrefs({required this.reduceTransparency, required super.child, super.key});
  final bool reduceTransparency;

  static AccessibilityPrefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccessibilityPrefs>()!;

  @override
  bool updateShouldNotify(AccessibilityPrefs old) => old.reduceTransparency != reduceTransparency;
}

Widget glassCard(BuildContext context, {required Widget child}) {
  final reduceTransparency = AccessibilityPrefs.of(context).reduceTransparency;
  if (reduceTransparency) {
    // Solid fallback — pick a real color for this context, not the blurred
    // RGBA value with alpha stripped, per the source doc's warning.
    return Container(color: Theme.of(context).colorScheme.surface, child: child);
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(color: Colors.white.withValues(alpha: 0.72), child: child),
    ),
  );
}
```

`MediaQuery.highContrastOf(context)` **is** available `[documented]` and is the closer analogue to "Increase Contrast" — use it to swap semantic colors to higher-contrast variants, the same pattern as `.isDarkerSystemColorsEnabled` in the source doc.

### 1.7 Minimum tap targets — 44×48dp via `SizedBox`

Flutter's Material spec defaults to a 48×48dp minimum interactive area (`kMinInteractiveDimension`); Apple's HIG asks for 44×44pt. Treat **48dp as the safe cross-platform floor** and never ship below it.

```dart
// Small glyph, full-size tap target — the invisible-padding pattern from
// accessibility-inclusive.md, done via explicit sizing rather than padding math.
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    padding: EdgeInsets.zero,
    icon: const Icon(Icons.close, size: 20),
    onPressed: onClose,
  ),
)
```

```dart
// Verify a custom widget meets the minimum — useful in a design-system test suite.
Widget ensureMinTapTarget({required Widget child, double min = 48}) {
  return ConstrainedBox(
    constraints: BoxConstraints(minWidth: min, minHeight: min),
    child: child,
  );
}
```

`Theme.of(context).materialTapTargetSize` (`MaterialTapTargetSize.padded` vs `.shrinkWrap`) controls whether Material widgets enforce this automatically — leave it at the default `padded` for any control a real thumb will tap. `[documented]`

### 1.8 Contrast checking

Flutter has no bundled contrast-ratio utility. Options, cheapest first:

1. **Manual WCAG formula** — useful for a design-token lint script or a debug overlay:

```dart
double _linearize(double channel) =>
    channel <= 0.03928 ? channel / 12.92 : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double relativeLuminance(Color c) {
  final r = _linearize(c.r);
  final g = _linearize(c.g);
  final b = _linearize(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG contrast ratio, 1.0–21.0. ≥4.5 for normal text, ≥3.0 for large text/UI.
double contrastRatio(Color a, Color b) {
  final l1 = relativeLuminance(a) + 0.05;
  final l2 = relativeLuminance(b) + 0.05;
  return l1 > l2 ? l1 / l2 : l2 / l1;
}
```
`[inferred convenience utility — the WCAG relative-luminance formula itself is documented; this Dart port is unverified against an official test vector, so spot-check a few known pairs before trusting it in CI.]`

2. **External tools against your design tokens** — run your `ColorScheme` values through WebAIM's contrast checker or a design-tool plugin (Stark, Contrast) before they ever reach code; this is cheaper than writing a Dart checker and catches issues earlier.

### 1.9 Testing: `flutter test` semantics + platform accessibility inspectors

```dart
testWidgets('favorite button exposes correct semantics', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(const MaterialApp(home: FavoriteButton()));

  expect(
    tester.getSemantics(find.byIcon(Icons.favorite_border)),
    matchesSemantics(label: 'Add to favorites', isButton: true, hasTapAction: true),
  );

  handle.dispose();
});
```
`tester.ensureSemantics()` + `matchesSemantics(...)` is the supported `flutter_test` pattern for asserting on the semantics tree without a real screen reader. `[documented]`

Visual/manual debugging layers:
- `MaterialApp(showSemanticsDebugger: true)` — a debug-only overlay that draws every semantics node's bounds and label directly on screen. `[documented]`
- **Flutter DevTools** ships an accessibility/semantics tree inspector for a running app — walk the tree the same way you'd audit a VoiceOver rotor. `[documented]`
- Because Flutter bridges into the real platform accessibility APIs, **Xcode's Accessibility Inspector** (iOS/macOS) and **Android's Accessibility Scanner / TalkBack** both work against a running Flutter app exactly as they would against a native one — run the actual assistive technology, not just the Flutter-side debugger, before shipping. `[documented]`

### 1.10 A11y checklist (Flutter-specific delta from the source checklist)

```
[ ] Every icon-only IconButton/InkWell has an explicit Semantics label
[ ] Decorative images/icons are wrapped in ExcludeSemantics
[ ] Related icon+text clusters use MergeSemantics, not left as separate nodes
[ ] No fixed-height Container/SizedBox around user-facing text
[ ] Tested with platformDispatcher.textScaleFactorTestValue at 2.0–3.0
[ ] AnimatedContainer/AnimationController durations gated on MediaQuery.disableAnimationsOf
[ ] Hero/page-route transitions have a reduced-motion fallback (no built-in default — verify manually)
[ ] Every BackdropFilter glass surface has a solid fallback gated on an app-level or plugin-read "reduce transparency" flag
[ ] All tappable targets ≥ 48×48dp (SizedBox/ConstrainedBox enforced, not eyeballed)
[ ] Color-only state (error red, selected tint) paired with an icon or text change — MediaQuery.highContrastOf checked for a high-contrast palette swap
[ ] Semantics tree asserted in widget tests via tester.ensureSemantics() + matchesSemantics()
[ ] Manually tested with VoiceOver (real iOS device) and TalkBack (real Android device) — the Flutter-side debugger is not a substitute
```

---

## Part 2 — Marketing/Brand Tactics, Scoped to an App

The source doc (`marketing-tactics-brand.md`) is built for **apple.com**, a public marketing website with full-viewport scroll sections, hero video, and pricing pages. A Flutter app has no equivalent surface for most of that — there is no "landing page" inside the app binary. The tactics that *do* transfer are the ones that apply to an app's own persuasive surfaces: **the App Store listing copy, first-run onboarding, empty states, and any in-app paywall.** Everything else in the source doc (keynote narrative arc, retail store design, unboxing ritual) has no Flutter runtime equivalent and is out of scope here.

### 2.1 Whitespace discipline in widget padding

The "restraint signals premium" principle becomes a padding discipline in Flutter. Anchor spacing to a small token scale instead of ad hoc pixel values, mirroring the 8pt-grid logic from `apple-design-foundations`:

```dart
abstract final class Space {
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 32.0;
  static const lg = 64.0;
  static const xl = 96.0;
}

// A paywall or onboarding screen that actually uses the whitespace,
// not just adds a default 16px Scaffold padding.
Padding(
  padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xl),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Unlock everything.', style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: Space.sm),
      Text('One subscription. Every feature.', style: Theme.of(context).textTheme.bodyLarge),
    ],
  ),
)
```
The anti-pattern from the source doc — "padding: 20px and calling it Apple-style" — has a direct Flutter form: a single `Padding(padding: EdgeInsets.all(16))` around a dense `Column` is not restraint. Restraint means empty `SizedBox` space is a deliberate layout element, not an afterthought.

### 2.2 Product-as-hero onboarding via `PageView`

apple.com's "one idea per section" reveal cadence maps onto a first-run onboarding carousel: one screen, one claim, one supporting visual, forward progress the user controls.

```dart
class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key});
  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (headline: 'See everything.', body: 'Search your whole library in a tap.', asset: 'assets/onboarding_search.png'),
    (headline: 'Never lose a draft.', body: 'Everything syncs the moment you stop typing.', asset: 'assets/onboarding_sync.png'),
    (headline: 'Yours, privately.', body: 'End-to-end encrypted. Always.', asset: 'assets/onboarding_privacy.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: Image.asset(slide.asset, fit: BoxFit.contain)),
                        const SizedBox(height: Space.lg),
                        Text(slide.headline, textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: Space.xs),
                        Text(slide.body, textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  );
                },
              ),
            ),
            _PageDots(count: _slides.length, current: _page),
            const SizedBox(height: Space.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: FilledButton(
                onPressed: () {
                  if (_page == _slides.length - 1) {
                    Navigator.of(context).pushReplacementNamed('/home');
                  } else {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                },
                child: Text(_page == _slides.length - 1 ? 'Get Started' : 'Continue'),
              ),
            ),
            const SizedBox(height: Space.md),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```
One slide = one claim, product/feature visual centered, minimal copy — the same discipline as an apple.com feature chapter, compressed into a swipeable app screen instead of a scroll zone.

### 2.3 Confident, benefit-led microcopy for app surfaces

The FAB template (Feature → Advantage → Benefit) and the "you/your" saturation rule from the source doc apply directly to empty states and paywalls — these are the only places a Flutter app "sells" anything to the user mid-session.

| App surface | Weak (feature-dumping) | Apple-style (benefit-led) |
|---|---|---|
| Empty list state | "No items. Tap + to add an item." | "Nothing here yet. Add your first note and it's synced everywhere." |
| Paywall headline | "Subscribe to Pro — $9.99/mo" | "Do more with Pro." (then price, then features, in that order) |
| Permission prompt | "This app needs notification access" | "Get notified the moment your download finishes." |
| Error state | "Error: network request failed" | "Couldn't reach the server. Check your connection and try again." |

```dart
// Empty-state widget written to the FAB template: benefit first, action second.
class EmptyNotesState extends StatelessWidget {
  const EmptyNotesState({required this.onCreate, super.key});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_add_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: Space.sm),
            Text('Nothing here yet.', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            Text(
              'Add your first note — it syncs everywhere the moment you save it.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Space.md),
            FilledButton(onPressed: onCreate, child: const Text('New Note')),
          ],
        ),
      ),
    );
  }
}
```
`[inferred]` — the copy discipline (superlative-with-proof, "you/your" framing, one CTA per surface) is directly portable from the source doc's Recipe 4; the specific wording above is illustrative, not prescriptive.

### 2.4 App Store screenshots and preview video

Product-as-hero photography, the pricing-anchor tactics, and the App Store screenshot/preview video **are release-asset concerns, not Flutter widget-tree concerns** — they are captured (via a design tool, Fastlane `snapshot`/`screengrab`, or manual device capture) from a running build, not rendered live inside the app. This is out of this file's scope; treat screenshot/preview production as a separate design-and-release workflow that consumes your onboarding/hero screens as source material, not something to build in Dart. `[inferred scoping note]`
