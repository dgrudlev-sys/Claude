# Flutter Implementation — Materials & Iconography

Scope: translating this skill's Liquid Glass/materials and SF Symbols/squircle references into idiomatic Flutter/Dart. Read `references/materials-liquid-glass.md` and `references/iconography-sf-symbols.md` first — the fidelity limits, anti-patterns, and rationale documented there apply identically here; this file only adds the Dart implementation layer. Confidence labels follow the family convention: `[documented]` for verifiable Flutter/Dart SDK API behavior, `[inferred]` for a reasonable but unconfirmed recommendation, `[speculative]` for an untested idea.

---

## 1. Glass / vibrancy / frosted materials

### The baseline primitive: `BackdropFilter` + `ImageFilter.blur`

Flutter's `BackdropFilter` widget is the direct equivalent of CSS `backdrop-filter` — it samples whatever is painted behind it in the same `Stack`/layer and applies an `ImageFilter` (typically a Gaussian blur) to that sampled content before compositing the child on top [documented — `package:flutter/widgets.dart`, `BackdropFilter`]. This is the reliable, SDK-only baseline the materials-liquid-glass reference's own "what CSS can achieve" table maps onto for Flutter — same ceiling (frosted diffuse blur: high fidelity; real-time lensing/refraction: not achievable without custom shaders) [inferred — same fidelity limits as the CSS analysis, translated to Flutter's compositor model].

```dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // see squircle section for a truer corner
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // ~= CSS blur(20px)
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1E1E23) : Colors.white)
                .withOpacity(isDark ? 0.55 : 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.12 : 0.55),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
```

Notes translating the CSS recipe directly:

- `ImageFilter.blur(sigmaX:, sigmaY:)`'s `sigma` is not numerically identical to CSS `blur(Npx)`, but the same relative guidance applies: ~8 for a minimal/thin material, ~20 for a standard control, ~28–32 for a heavy panel/sidebar, mirroring the materials reference's own blur-radius guidance bands [inferred — `sigma` and CSS px blur radius are different units but the practical "thin/standard/heavy" tiering transfers].
- `ClipRRect` around the `BackdropFilter` is required — without it, the blur samples/paints past the intended shape's bounds [documented — `BackdropFilter` has no implicit clip].
- `saturate()`/vibrancy has no direct Flutter `ImageFilter` equivalent; `ImageFilter.blur` alone gives you the blur but not the saturation boost. A `ColorFilter.matrix` saturation matrix layered via `ColorFiltered` can approximate it, or accept the blur-only look as the SDK-only baseline [inferred — Flutter has no built-in one-line "saturate" filter analogous to CSS].
- **Never stack two `BackdropFilter`s** — same glass-on-glass prohibition as the native and CSS references; each nested `BackdropFilter` re-samples an already-blurred layer and produces the same "milky, low-contrast mess" the materials reference warns against [inferred — same compositor-level cause, translated].
- **Reduce Transparency fallback:** since `MediaQueryData` has no confirmed first-class Reduce-Transparency flag in the stable Flutter SDK (see the foundations Flutter reference), the practical mitigation is the same one used there — branch on `MediaQuery.highContrastOf(context)` as a proxy, or expose an app-level "reduce transparency" setting that swaps the glass `Container` for a solid `CupertinoColors.secondarySystemBackground` fill, mirroring the CSS `@media (prefers-reduced-transparency: reduce)` fallback structurally even without the exact same OS signal [inferred].

### A living backdrop — glass needs something to blur

Exactly as the materials-liquid-glass reference stresses for CSS, `BackdropFilter` blurring a flat `Container(color: Colors.white)` behind it produces a flat blurred wash indistinguishable from a plain semi-transparent fill — there must be a spatially varied backdrop (a gradient mesh, an image, or real scrolling content) beneath the glass for the effect to read as glass at all [inferred — identical underlying cause: blur of a uniform-color source is visually a no-op beyond opacity]. Reuse the CSS recipe's radial-gradient-mesh idea as a Flutter `DecoratedBox`:

```dart
DecoratedBox(
  decoration: const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0.6, -0.9),
      radius: 1.2,
      colors: [Color(0x8CFFB48C), Colors.transparent],
    ),
  ),
  // Stack multiple RadialGradient-backed layers, or use a single
  // ShaderMask/CustomPainter with several radial gradients composited,
  // to build the multi-hue mesh the CSS recipe describes.
)
```

### Optional packages (unverified — confirm on pub.dev)

`liquid_glass_renderer`, `glassmorphism`, and `blur` are commonly cited Flutter package names for pre-built glass/blur widgets [inferred — this environment has no live pub.dev access; treat every claim about these three package names, their current API, and even their continued existence on pub.dev as unverified]. Before depending on any of them:

1. Confirm the exact package name and that it is still published/maintained on pub.dev.
2. Check whether its API wraps `BackdropFilter`/`ImageFilter` (likely) or does something materially different (e.g. a custom shader for true refraction, which would be a meaningfully higher-fidelity offering worth the dependency).
3. Prefer the hand-rolled `BackdropFilter` recipe above unless a package clearly buys you something the SDK primitive doesn't (e.g. `liquid_glass_renderer`, if its name is accurate, may target real lensing/refraction via `dart:ui` fragment shaders — verify before trusting the name as a description of its actual capability).

### Reaching for real refraction — `FragmentShader`

The one path to something closer to genuine Liquid Glass lensing (rather than flat blur) is Flutter's fragment shader support (`dart:ui`'s `FragmentProgram`/`FragmentShader`, `.frag` files compiled via the `shaders` section of `pubspec.yaml`) [documented — Flutter supports custom fragment shaders as an `ImageFilter`/`Shader` source]. Writing a displacement-map shader mirrors the CSS reference's Chromium-only `feDisplacementMap` SVG filter recipe conceptually, but as a real GPU shader rather than an SVG filter graph — this is a substantial undertaking (GLSL-like shader authoring) appropriate only when lensing fidelity is a hard product requirement, not a default recommendation [speculative — no verified end-to-end recipe here; flagging the capability exists rather than providing an unverified shader].

---

## 2. Squircle / continuous-corner shape

### Why `RoundedRectangleBorder`/`BorderRadius.circular` is not a squircle

Flutter's default rounded-rectangle primitives (`BorderRadius.circular`, `RoundedRectangleBorder`, `ClipRRect`) produce the same **tangent-join** curvature the iconography reference identifies as the core problem with plain CSS `border-radius`: the arc meets the straight edge at a single point with an abrupt curvature jump, rather than the G2 continuous-curvature transition of Apple's actual icon/shape mask [documented — `BorderRadius`/`RoundedRectangleBorder` are simple circular-arc corners, not superellipse-based; inferred that this produces the identical visually-perceptible "kink" the iconography reference describes for CSS `border-radius`, since the underlying geometry (circular arc tangent to a straight edge) is the same construction].

```dart
// This is a rounded rectangle, NOT a squircle — same limitation as
// plain CSS border-radius, per the iconography reference.
ClipRRect(
  borderRadius: BorderRadius.circular(180), // 22% of a ~820px icon, e.g.
  child: iconArt,
)
```

At large sizes (app icon badges, hero tiles) on a high-DPI screen this reads the same way the CSS reference describes: a perceptible kink at each corner rather than Apple's smooth continuous curve [inferred].

### Option A: `figma_squircle` package (unverified — confirm on pub.dev)

`figma_squircle` is commonly cited as a Flutter package providing a `SmoothRectangleBorder`-style shape that mirrors Figma's own "corner smoothing" slider (the same 60%-smoothing approximation the iconography reference cites as a credible Apple-mask approximation) [inferred — package name and API unverified against a live pub.dev listing; confirm before use]. If verified current on pub.dev, usage looks approximately like:

```dart
// Illustrative — confirm exact class name/constructor against the
// current figma_squircle API on pub.dev before shipping.
import 'package:figma_squircle/figma_squircle.dart';

Container(
  decoration: ShapeDecoration(
    color: CupertinoColors.systemBackground,
    shape: SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: 180,      // ~22% of icon width, per the HIG measurement
        cornerSmoothing: 0.6,   // matches the Figma 60% approximation cited in iconography.md
      ),
    ),
  ),
  child: iconArt,
)
```

### Option B: hand-rolled `CustomClipper` implementing a superellipse path

For a dependency-free approach, or to reproduce the iconography reference's own SVG `clipPath` Bézier approximation exactly, implement a `CustomClipper<Path>` using the same cubic-Bézier control-point structure as the reference's Approach B (SVG) recipe [inferred — direct translation of the documented Bézier path into Flutter's `Path` API]:

```dart
import 'package:flutter/cupertino.dart';

class SquircleClipper extends CustomClipper<Path> {
  const SquircleClipper({this.cornerRadius = 0.22});

  /// Fraction of the shorter side used as the corner "radius" — 0.22
  /// matches the ~22% measurement the iconography reference cites for
  /// Apple's app-icon mask.
  final double cornerRadius;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius * (w < h ? w : h);

    // Cubic-Bézier continuous-corner approximation, restated from the
    // iconography reference's SVG objectBoundingBox path (Approach B),
    // scaled from 0–1 unit space to this widget's actual pixel size.
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.726, 0, w * 0.860, 0, w - r * 0.927, r * 0.073 / cornerRadius * cornerRadius)
      ..lineTo(w - r * 0.2, r * 0.2) // simplified midpoint — see note below
      ..cubicTo(w, h * 0.274, w, h * 0.5, w, h * 0.5)
      ..cubicTo(w, h * 0.726, w, h * 0.726, w - r * 0.2, h - r * 0.2)
      ..cubicTo(w * 0.860, h, w * 0.726, h, w * 0.5, h)
      ..cubicTo(w * 0.274, h, w * 0.2, h, r * 0.2, h - r * 0.2)
      ..cubicTo(0, h * 0.726, 0, h * 0.5, 0, h * 0.5)
      ..cubicTo(0, h * 0.274, 0, r * 0.2, r * 0.2, r * 0.2)
      ..cubicTo(w * 0.274, 0, w * 0.4, 0, w * 0.5, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
```

The control-point arithmetic above is a structural sketch, not a verified pixel-exact port — the iconography reference itself flags its SVG path as "visually close but not mathematically identical to Apple's exact control-point ratios," and that same caveat applies here, compounded by the unit-space-to-pixel-space translation [inferred — treat this clipper as a starting point to refine against the Rosenfeld constants cited in the iconography reference (§5), not as a drop-in exact reproduction]. For pixel-exact reproduction, port the seven normalized control-point offsets the iconography reference cites (`1.528665, 1.088493, 0.868407, 0.631494, 0.374824, 0.169060, 0.074911`) directly into a `Path` construction rather than approximating from the simplified SVG path [inferred].

```dart
// Usage
ClipPath(
  clipper: const SquircleClipper(cornerRadius: 0.2237), // 22.37%, per the reference
  child: iconArt,
)
```

### Shadows on a squircle-clipped widget

Same caveat as the CSS reference: `ClipPath`/`ClipRRect` clips whatever is painted as part of the clipped child, including a `BoxShadow` declared on that same widget's `Container`. Route shadows through a `DecoratedBox`/`Container` with the shadow applied to a *parent* that is not itself clipped, or use Flutter's `PhysicalShape` widget, which paints a shape with an accurate ambient/elevation shadow while clipping its child to that same shape in one step [documented — `PhysicalShape` computes its shadow from the clipper's outline, unlike a naive `ClipPath` + separate `BoxShadow`]:

```dart
PhysicalShape(
  clipper: const SquircleClipper(cornerRadius: 0.2237),
  color: CupertinoColors.systemBackground,
  elevation: 8, // Material-style elevation shadow, still usable in a Cupertino tree
  shadowColor: CupertinoColors.black.withOpacity(0.2),
  child: iconArt,
)
```

---

## 3. SF Symbols equivalents

### `cupertino_icons` — the default, design-matched subset

`cupertino_icons` ships as a default dependency in every new Flutter project's `pubspec.yaml` (referenced via the `CupertinoIcons` class) and provides a curated subset of glyphs stylistically matched to iOS's system iconography [documented — `cupertino_icons` is the standard Flutter starter dependency, and its glyphs are designed to look native alongside Cupertino widgets]. It is **not** the full SF Symbols library (which runs to 6,900+ symbols per the iconography reference) — it covers common, generic glyph needs (chevrons, tab-bar icons, common actions), not domain-specific or rare symbols [inferred — `cupertino_icons`' documented scope is a curated common subset, smaller than SF Symbols' full library].

```dart
import 'package:flutter/cupertino.dart';

const Icon(CupertinoIcons.heart_fill, color: CupertinoColors.systemRed, size: 24)
const Icon(CupertinoIcons.gear, color: CupertinoColors.label)
const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.tertiaryLabel)
```

This is the legally clean path: `cupertino_icons` is an independently licensed, open icon font — not a redistribution of Apple's proprietary SF Symbols glyphs — so it carries none of the licensing restriction the iconography reference documents for SF Symbols itself [documented — `cupertino_icons` is a separate, freely licensed font, distinct from Apple's proprietary SF Symbols].

### Material Symbols via `flutter_symbols` or custom icon fonts

For a broader glyph set than `cupertino_icons` covers, options include Google's Material Symbols (via a Flutter wrapper package such as `flutter_symbols` [inferred — package name unverified against a live pub.dev listing]) or a hand-picked open icon set (Phosphor Icons, Lucide — both explicitly named in the iconography reference's own web-replication section as SF-Symbols-adjacent alternatives) bundled as a custom icon font [inferred — same alternatives the iconography reference recommends for CSS, ported to Flutter's font-based icon mechanism]:

```yaml
# pubspec.yaml — bundling a custom icon font (e.g. an exported Phosphor/Lucide subset)
flutter:
  fonts:
    - family: AppIcons
      fonts:
        - asset: assets/fonts/AppIcons.ttf
```

```dart
class AppIcons {
  AppIcons._();
  static const IconData bell = IconData(0xe900, fontFamily: 'AppIcons');
  static const IconData heart = IconData(0xe901, fontFamily: 'AppIcons');
}

const Icon(AppIcons.bell, size: 24, color: CupertinoColors.label)
```

Weight-matching discipline transfers directly: if body text renders at `FontWeight.w600`, pick or generate the icon font's semibold-equivalent stroke weight rather than mixing a thin icon glyph next to bold text — the same "visual harmony collapses when icon stroke weight diverges from text weight" rule the iconography reference states for SF Symbols [inferred — same typographic-harmony principle, no Flutter-specific mechanism changes it].

### Approximating rendering modes — no direct equivalent

SF Symbols' four rendering modes (monochrome, hierarchical, palette, multicolor) and its variable-color/effects system have **no direct Flutter equivalent** — `Icon` in Flutter is fundamentally a single-color glyph render (`Icon(icon, color: ...)` accepts exactly one `Color`) [documented — `Icon` widget's `color` parameter is a single `Color?`, not a per-layer palette]. Approximate each mode as follows:

| SF Symbols mode | Flutter approximation |
|---|---|
| **Monochrome** | Native — `Icon(icon, color: singleColor)` [documented] |
| **Hierarchical** (single hue, multi-opacity layers) | Stack two copies of a layered icon (a background/foreground pair from an icon set that ships them separately), or apply `.withOpacity()` to sub-elements of a custom multi-path icon widget built from several `Icon`/`CustomPaint` layers [inferred — requires a multi-layer source asset, which most icon fonts do not provide out of the box] |
| **Palette** (2–3 independently colored layers) | Compose the glyph from multiple stacked `Icon` widgets in a `Stack`, each using a different `IconData` (a matching layer from a multi-layer icon set) and a distinct `color` [inferred — same "layered `Icon` widgets" approach the task brief anticipates; only works if the source icon set ships separable layers] |
| **Multicolor** (fixed semantic per-glyph colors) | Use a full-color vector asset instead of a font glyph — render as an SVG (`flutter_svg` package [inferred — unverified name/API]) or a raster image, since a single-color `IconData` glyph cannot carry Apple's baked-in per-shape colors | 
| **Gradient** rendering | `ShaderMask` wrapping an `Icon`, applying a `LinearGradient`/`RadialGradient` shader over the glyph's alpha channel [documented — `ShaderMask` is the standard Flutter technique for gradient-filling an icon or text glyph] |

```dart
// Approximating SF Symbols' "Gradient" rendering mode with ShaderMask
ShaderMask(
  shaderCallback: (bounds) => const LinearGradient(
    colors: [CupertinoColors.systemOrange, CupertinoColors.systemRed],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  ).createShader(bounds),
  child: const Icon(CupertinoIcons.flame_fill, size: 64, color: CupertinoColors.white),
)

// Approximating "Palette" mode by stacking two layers of a multi-layer icon set
Stack(
  alignment: Alignment.center,
  children: [
    Icon(AppIcons.personGroupBackground, size: 64, color: CupertinoColors.systemBlue),
    Icon(AppIcons.personGroupForeground, size: 64, color: CupertinoColors.systemTeal),
  ],
)
```

### Symbol effects (bounce, pulse, variable color, draw-on) — animate by hand

None of SF Symbols' `.bounce`/`.pulse`/`.variableColor`/`.draw.on` effects exist as a Flutter API — each must be hand-built with Flutter's own animation primitives (`AnimationController` + `Tween`, or `flutter_animate` as a higher-level DSL — see `apple-design/references/flutter-implementation.md`'s package table) [inferred — no SDK or verified package provides an SF-Symbols-effect-compatible API]. A minimal `.pulse`-style approximation:

```dart
class PulsingIcon extends StatefulWidget {
  const PulsingIcon({super.key, required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Icon(widget.icon, color: widget.color, size: 24),
    );
  }
}
```

Respect `MediaQuery.disableAnimationsOf(context)` (Reduce Motion) by skipping `.repeat()` and rendering a static frame when it is true — same accessibility contract the rest of this family applies to every animation [inferred — direct application of the family's universal Reduce Motion rule to this specific effect].

---

## Confidence summary

`BackdropFilter`, `ImageFilter.blur`, `ClipRRect`/`ClipPath`, `PhysicalShape`, `ShaderMask`, `cupertino_icons`/`CupertinoIcons`, custom `IconData`/font bundling via `pubspec.yaml`, and `AnimationController`-based animation are `[documented]` Flutter/Dart SDK or standard-toolchain behavior. `figma_squircle`, `liquid_glass_renderer`, `glassmorphism`, `blur`, `flutter_symbols`, and `flutter_svg` are named as commonly cited packages but their exact names, current APIs, and pub.dev status are `[inferred]`/unverified in this environment — confirm each on pub.dev before depending on it. The hand-rolled squircle `CustomClipper` path math is a structural approximation, not a verified pixel-exact port of Apple's mask.
