# Flutter Implementation — Scroll-Driven Storytelling
Scope: an honest scoping note on why this skill's core content doesn't map to a Flutter app, followed by real Flutter recipes for the parts that *do* transfer — scroll-progress-driven animation, pinned/sticky sections, parallax, and bento-style feature grids, for use inside a Flutter Web marketing site or a scroll-driven onboarding/showcase screen in a mobile app. Confidence labels follow the family convention: `[documented]` verifiable API behavior, `[inferred]` reasonable but unconfirmed, `[speculative]` untested idea.

---

## Scope honesty first

This skill (`apple-design-web`) and its four reference files are built around **apple.com**: a public, SEO-indexed marketing website with a sticky translucent nav, full-viewport hero sections, canvas/video scroll-scrubbing, and a fat multi-column footer. That entire page formula — `web-applecom-language.md`'s section anatomy, `scrollytelling-techniques.md`'s interaction inventory, `web-frontend-engineering.md`'s vanilla-JS/progressive-enhancement architecture, `media-assets-and-delivery.md`'s hero-video pipeline — is **website-specific**. None of it describes a Flutter *app's* UI, and forcing a 1:1 mapping (e.g. "here's how to build a sticky translucent nav bar inside your Flutter app") would misrepresent what an app screen actually is: a bounded, task-oriented surface, not a scrollable public document meant to be crawled and shared.

**If what you actually need is an apple.com-style public marketing page — a real website with SEO, shareable URLs, and a hero video — build it as a real website (HTML/CSS/JS, or a framework like Next.js/Astro), not as a Flutter Web app.** Flutter Web renders through a canvas-backed or DOM-backed engine that produces poor search-indexable HTML, has a heavier first-paint cost than a lean marketing page, and gives you none of the `<picture>`/`srcset`/`loading="lazy"`/semantic-HTML machinery `web-frontend-engineering.md` documents as load-bearing for that use case. `[inferred — consistent with Flutter Web's documented rendering model and the source doc's SEO/perf requirements]` Route that request to a real front-end stack; this file will not help you build apple.com in Dart.

**What *does* transfer:** the underlying technique — binding continuous animation values to scroll position — is a general UI pattern, not a web-only one. Two situations where it's legitimately useful in Flutter:

1. **You are building a Flutter Web app** (not a marketing site — an actual app that happens to target the browser) and want a scroll-driven hero or feature section inside it.
2. **You want scroll-driven storytelling inside a native/mobile Flutter app** — most commonly a feature-showcase or onboarding screen that reveals capabilities as the user scrolls, rather than swipes through a `PageView` (see `apple-design-tactics/references/flutter-implementation.md` §2.2 for the swipe-carousel alternative).

The recipes below serve those two cases. They are deliberately shorter than the source doc — a canvas image-sequence flipbook, HLS-authored hero video, and a full nav/footer page formula are not worth reimplementing for an app screen.

---

## 1. Scroll-progress-driven animation

The web doc's core primitive is `mapRange(scrollValue) → animationValue`, read on every scroll tick and applied to `opacity`/`transform`. Flutter's equivalent is a `ScrollController` (or `NotificationListener<ScrollNotification>`) feeding an `AnimatedBuilder`, with the same range-mapping math.

```dart
double mapRange(double value, double inMin, double inMax, double outMin, double outMax) {
  final t = ((value - inMin) / (inMax - inMin)).clamp(0.0, 1.0);
  return outMin + t * (outMax - outMin);
}
```

### 1.1 `ScrollController` + `AnimatedBuilder`

```dart
class ScrollRevealSection extends StatefulWidget {
  const ScrollRevealSection({required this.scrollController, super.key});
  final ScrollController scrollController;

  @override
  State<ScrollRevealSection> createState() => _ScrollRevealSectionState();
}

class _ScrollRevealSectionState extends State<ScrollRevealSection> {
  final _key = GlobalKey();

  double _progressFor(BuildContext context) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return 0;
    // Distance of this section's top from the viewport top, in the scrollable's
    // own coordinate space — the Flutter analogue of getBoundingClientRect().top.
    final position = box.localToGlobal(Offset.zero, ancestor: null).dy;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    // Fully revealed once the section has traveled 60% up the viewport.
    return mapRange(viewportHeight - position, 0, viewportHeight * 0.6, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.scrollController,
      builder: (context, child) {
        final progress = _progressFor(context);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 24),
            child: child,
          ),
        );
      },
      child: Container(key: _key, height: 240, color: Colors.blue.shade50),
    );
  }
}
```
`[inferred]` — reading a `RenderBox`'s global position on every `AnimatedBuilder` rebuild is a per-frame layout query; it is fine for a handful of sections on an onboarding/showcase screen but does not scale to a long content-heavy page the way the web doc's IntersectionObserver-based approach does. For many sections, prefer computing progress from `scrollController.offset` directly against known section extents (see §1.2) rather than re-querying `RenderBox` positions every frame.

### 1.2 `NotificationListener<ScrollNotification>` (no controller needed)

Useful when you don't otherwise need a `ScrollController` (e.g. a `CustomScrollView` you don't own directly):

```dart
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    final metrics = notification.metrics;
    final progress = mapRange(metrics.pixels, 0, metrics.maxScrollExtent, 0, 1);
    setState(() => _scrollProgress = progress);
    return false; // allow the notification to keep bubbling
  },
  child: ListView(children: _sections),
)
```

### 1.3 Damped/lerped scroll value (the "shadow scroll value" from `scrollytelling-techniques.md`)

The web doc's `apple-design-motion` engine lerps a shadow scroll value each frame rather than snapping directly to the raw scroll position, so motion reads as smoothed rather than jittery. The Flutter equivalent uses a `Ticker`:

```dart
class DampedScrollProgress extends ChangeNotifier {
  DampedScrollProgress({this.damping = 0.12});
  final double damping; // 0.08–0.12 mirrors the web doc's α range
  double _target = 0;
  double _current = 0;
  double get value => _current;

  void setTarget(double t) => _target = t.clamp(0.0, 1.0);

  void tick() {
    _current += (_target - _current) * damping;
    if ((_target - _current).abs() > 0.0005) notifyListeners();
  }
}

class DampedScrollHost extends StatefulWidget {
  const DampedScrollHost({required this.child, required this.controller, super.key});
  final Widget child;
  final ScrollController controller;

  @override
  State<DampedScrollHost> createState() => _DampedScrollHostState();
}

class _DampedScrollHostState extends State<DampedScrollHost> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _progress = DampedScrollProgress();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    _ticker = createTicker((_) => _progress.tick())..start();
  }

  void _onScroll() {
    final max = widget.controller.position.maxScrollExtent;
    if (max > 0) _progress.setTarget(widget.controller.offset / max);
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _progress, builder: (_, __) => widget.child);
}
```
`[inferred]` — a `Ticker` running every frame purely to lerp a scalar is a reasonable direct port of the web doc's `requestAnimationFrame` lerp loop, but it does mean the ticker runs continuously while the section is mounted; dispose it with the widget and avoid mounting it on more than one active section at a time.

**Reduced motion:** gate all of the above on `MediaQuery.disableAnimationsOf(context)` exactly as in the accessibility section of `apple-design-tactics/references/flutter-implementation.md` — set the damping factor to `1.0` (i.e. snap instantly) or skip the `Ticker` entirely when the flag is set, mirroring the web doc's "reduced motion → discrete snap" rule.

---

## 2. Pinned / sticky sections

`scrollytelling-techniques.md`'s CSS `position: sticky` chapters map to `SliverPersistentHeader` inside a `CustomScrollView`. Unlike CSS sticky (which pins within its own parent's scroll budget), Flutter's sliver pins relative to the whole scroll view — closer to a chaptered "sticky-stack" than a per-section pin, so budget the design accordingly.

```dart
class _StickySectionHeader extends SliverPersistentHeaderDelegate {
  _StickySectionHeader({required this.title, this.extent = 64});
  final String title;
  final double extent;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySectionHeader old) => old.title != title;
}

CustomScrollView(
  slivers: [
    SliverPersistentHeader(
      pinned: true,
      delegate: _StickySectionHeader(title: 'Camera'),
    ),
    SliverList(delegate: SliverChildListDelegate(_cameraFeatureRows)),
    SliverPersistentHeader(
      pinned: true,
      delegate: _StickySectionHeader(title: 'Battery'),
    ),
    SliverList(delegate: SliverChildListDelegate(_batteryFeatureRows)),
  ],
)
```

For a plain scrollable *list* (not a full `CustomScrollView`) with section headers that stick as you scroll past them — the more common "sticky-stack" use case — the community package `sticky_headers` wraps this pattern without hand-writing a sliver delegate. `[inferred — verify current maintenance status and API against pub.dev before depending on it; the manual `SliverPersistentHeader` approach above has no third-party dependency and is the more durable choice for production code]`.

---

## 3. Parallax effects

`Transform.translate` driven by scroll offset, inside a `Stack` so the parallax layer and the normally-scrolling content occupy the same space:

```dart
class ParallaxHero extends StatelessWidget {
  const ParallaxHero({required this.scrollController, required this.heroAsset, super.key});
  final ScrollController scrollController;
  final String heroAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: scrollController,
          builder: (context, child) {
            final offset = scrollController.hasClients ? scrollController.offset : 0.0;
            // Background layer moves at 0.3x scroll speed — same conservative
            // differential the web doc recommends (≤40–80px, paired with a fade).
            return Transform.translate(
              offset: Offset(0, offset * 0.3),
              child: child,
            );
          },
          child: Image.asset(heroAsset, fit: BoxFit.cover, width: double.infinity),
        ),
      ),
    );
  }
}
```

Inside a `CustomScrollView`, a `SliverAppBar` with `flexibleSpace` gives you a similar effect for free for the common "parallax hero image behind a collapsing title" pattern, without hand-rolling the `Transform.translate` math:

```dart
CustomScrollView(
  slivers: [
    SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('MacBook Pro'),
        background: Image.asset('assets/macbook_hero.jpg', fit: BoxFit.cover),
      ),
    ),
    SliverList(delegate: SliverChildListDelegate(_specRows)),
  ],
)
```
`[documented]` — `FlexibleSpaceBar`'s built-in parallax/stretch/fade behavior on its `background` widget is standard Material SDK behavior and is the lowest-effort way to get an apple.com-style hero-image-behind-title effect in an app.

Only `Transform`/`Opacity` should drive per-frame changes here, mirroring the web doc's "only `transform` and `opacity`, never layout properties" rule — Flutter's own equivalent hazard is rebuilding a whole subtree or touching `Positioned`'s `top`/`left` every frame, which forces layout instead of a cheap compositor-level transform.

---

## 4. Bento-grid feature showcase

A hand-rolled asymmetric grid (no extra dependency) is usually enough for a single feature-showcase screen:

```dart
Widget bentoGrid(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _BentoCard(title: 'Camera', subtitle: '48MP Fusion', height: 220)),
            const SizedBox(width: 12),
            Expanded(child: _BentoCard(title: 'Battery', subtitle: 'All-day', height: 220)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _BentoCard(title: 'Chip', subtitle: 'A19 Pro', height: 160)),
            const SizedBox(width: 12),
            Expanded(child: _BentoCard(title: 'Display', subtitle: 'ProMotion', height: 160)),
            const SizedBox(width: 12),
            Expanded(child: _BentoCard(title: 'Durability', subtitle: 'Titanium', height: 160)),
          ],
        ),
      ],
    ),
  );
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.title, required this.subtitle, required this.height});
  final String title;
  final String subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.bottomLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
```

For a *dynamic* set of cards with irregular spans decided at runtime (rather than a fixed hand-laid-out grid like above), the community package `flutter_staggered_grid_view` provides a `StaggeredGrid`/quilted-grid API purpose-built for this. `[inferred — verify current API surface and maintenance status on pub.dev; for a small, fixed number of feature cards the manual Row/Column composition above is simpler and dependency-free]`.

---

## 5. What this file deliberately omits

No canvas image-sequence flipbook, no `video.currentTime` scroll-scrub, no WebGL/three.js product viewer, no HLS authoring, and no sticky translucent nav-bar recipe. These are meaningful engineering investments on a public marketing website with a dedicated media pipeline (see `media-assets-and-delivery.md`) and have no equivalent payoff inside a bounded app screen — a Flutter app showcase section is better served by a short Lottie/Rive animation, a `PageView` carousel (`apple-design-tactics/references/flutter-implementation.md` §2.2), or the `FlexibleSpaceBar` hero pattern above than by reimplementing a frame-scrubbing video pipeline in Dart. `[inferred scoping judgment]`
