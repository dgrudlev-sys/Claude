# Flutter Implementation — OS Surfaces & Components

**Scope**: Dart/Flutter equivalents for the component anatomy and per-platform surfaces in `app-component-anatomy.md`, `ios-ipados.md`, `macos.md`, and `visionos-watchos.md`. Those files remain authoritative on *what* the native component looks like and *why* (metrics, HIG rules, iOS 26 Liquid Glass behavior). This file maps that catalog onto Cupertino widgets, and is honest about where Flutter simply cannot reach a surface at all.

Package names are current as of this writing but not version-pinned — verify current API shape on pub.dev before depending on exact signatures. Anything not in the Flutter SDK itself is marked `[inferred]`.

---

## 1. Component anatomy → Cupertino widget map

| Native component (`app-component-anatomy.md` / `ios-ipados.md`) | Flutter/Cupertino equivalent | Fidelity |
|---|---|---|
| Navigation bar, large title | `CupertinoNavigationBar` (inline) / `CupertinoSliverNavigationBar` (large-title-collapses-on-scroll) | High — the collapse behavior matches natively |
| Tab bar | `CupertinoTabBar` + `CupertinoTabScaffold` | High |
| Toolbar (bottom bar) | `CupertinoPageScaffold` bottom area, or a custom `SafeArea`-wrapped `Row` | Medium — no auto Liquid-Glass floating capsule (§6) |
| Grouped / inset-grouped list | `CupertinoListSection.insetGrouped` + `CupertinoListTile` | High |
| Plain list | `CupertinoListSection` (no grouping) or plain `ListView` | High |
| Segmented control | `CupertinoSlidingSegmentedControl` | High |
| Toggle (`UISwitch`) | `CupertinoSwitch` | High |
| Slider | `CupertinoSlider` | High |
| Stepper | `CupertinoStepper` — **not in the SDK**; see §1.6 | Low — must hand-build |
| Date/time picker | `CupertinoDatePicker` (`.date`, `.time`, `.dateAndTime`) | High |
| Wheel picker | `CupertinoPicker` | High |
| Menu (pull-down) | `CupertinoContextMenu` (long-press) or a custom `showCupertinoModalPopup` action list — no direct pull-down-button `Menu` port | Medium |
| Search field | `CupertinoSearchTextField` | High |
| Sheet | `showCupertinoModalPopup` / `showCupertinoSheet` — no native multi-detent; see §2 | Medium |
| Alert | `CupertinoAlertDialog` via `showCupertinoDialog` | High |
| Action sheet / confirmation dialog | `CupertinoActionSheet` via `showCupertinoModalPopup` | High |
| Popover | No SDK widget — build from `CompositedTransformTarget`/`Follower` | Low |
| Button hierarchy | `CupertinoButton.filled` / `CupertinoButton` (tinted) / `CupertinoButton` (plain, no background) | Medium — no direct `.bordered` middle tier; see §1.5 |
| Empty state (`ContentUnavailableView`) | No SDK widget — hand-roll (see `apple-design-interaction`'s flutter-implementation.md §2.2) | N/A |

### 1.1 Navigation bar with large title

```dart
CupertinoPageScaffold(
  child: CustomScrollView(
    slivers: [
      const CupertinoSliverNavigationBar(
        largeTitle: Text('Library'),
        // Collapses to an inline 17pt title on scroll, matching the
        // ~96pt-expanded / 44pt-collapsed behavior in ios-ipados.md
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => CupertinoListTile(title: Text(items[index].title)),
          childCount: items.length,
        ),
      ),
    ],
  ),
);
```
`CupertinoSliverNavigationBar` reproduces the collapse mechanic described in `ios-ipados.md` §"Navigation Patterns" reasonably closely, but it does **not** apply the iOS 26 Liquid Glass frosted-strip treatment — see §6.

### 1.2 Tab bar

```dart
CupertinoTabScaffold(
  tabBar: CupertinoTabBar(
    items: const [
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: 'Search'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
    ],
  ),
  tabBuilder: (context, index) => CupertinoTabView(
    builder: (context) => [HomePage(), SearchPage(), ProfilePage()][index],
  ),
);
```
Metrics (`app-component-anatomy.md`: 49 pt + safe area, 2–5 item limit) are the developer's responsibility — Flutter does not clamp item count or enforce the height.

### 1.3 Grouped lists and forms — `CupertinoListSection`

```dart
CupertinoListSection.insetGrouped(
  header: const Text('ACCOUNT'), // SDK does not auto-uppercase; do it yourself if matching HIG exactly
  footer: const Text("Items you've starred appear here."),
  children: [
    CupertinoListTile(
      title: const Text('Email'),
      trailing: const CupertinoListTileChevron(),
      onTap: () {},
    ),
    CupertinoListTile.notched(
      title: const Text('Notifications'),
      trailing: CupertinoSwitch(
        value: notificationsEnabled,
        onChanged: (v) => setState(() => notificationsEnabled = v),
      ),
    ),
  ],
);
```
This is a direct, high-fidelity port of the `Form`/`.insetGrouped` list style cataloged in `app-component-anatomy.md` §"Lists & Tables" — rounded-corner card sections, correct row height, correct header/footer typography role. Swipe actions on a `CupertinoListTile` are not built in; layer `Dismissible` or `flutter_slidable` (see the `apple-design-motion` flutter-implementation.md §5) around each tile.

### 1.4 Search field

```dart
CupertinoSearchTextField(
  placeholder: 'Search messages',
  onChanged: (query) => setState(() => _query = query),
  onSuffixTap: () => setState(() => _query = ''),
);
```
This reproduces the rounded-rect + magnifying-glass + clear-button anatomy from `app-component-anatomy.md` §"Search" directly, but has no built-in scope bar (segmented filter row) or `.searchable`-style automatic placement/collapse-on-scroll integration with a nav bar — compose those by hand with a `CupertinoSlidingSegmentedControl` beneath it if needed.

### 1.5 Button hierarchy

Cupertino's button vocabulary is thinner than SwiftUI's four-tier `.borderedProminent`/`.bordered`/`.borderless`/`.automatic` system (`app-component-anatomy.md` §"Buttons"). Map it explicitly rather than assuming a 1:1 widget exists:

```dart
// Primary CTA — .borderedProminent equivalent
CupertinoButton.filled(
  onPressed: _download,
  child: const Text('Download'),
);

// Secondary — approximates .bordered (tinted border + tinted label); the SDK
// has no dedicated tinted-outline button style, so build it explicitly.
CupertinoButton(
  color: CupertinoColors.systemGrey5,
  onPressed: _preview,
  child: const Text('Preview'),
);

// Tertiary / plain — .borderless equivalent
CupertinoButton(
  onPressed: _cancel,
  child: const Text('Cancel'),
);

// Destructive
CupertinoButton.filled(
  color: CupertinoColors.destructiveRed,
  onPressed: _deleteAccount,
  child: const Text('Delete Account'),
);
```
`[inferred]` — the "secondary/tinted-outline" recipe above is a reasonable hand-built approximation, not an SDK-provided style; verify it still matches current Cupertino design tokens (colors, corner radius) before shipping.

### 1.6 Widgets the SDK doesn't ship at all

`CupertinoStepper` does not exist in the Flutter SDK. Build the `+`/`−` capsule from two `CupertinoButton`s in a bordered `Row`:

```dart
Widget stepper({required int value, required ValueChanged<int> onChanged}) {
  return CupertinoSlidingSegmentedControl<String>(
    groupValue: null,
    children: {
      'minus': Container(padding: const EdgeInsets.all(8), child: const Icon(CupertinoIcons.minus)),
      'plus': Container(padding: const EdgeInsets.all(8), child: const Icon(CupertinoIcons.plus)),
    },
    onValueChanged: (key) {
      if (key == 'minus') onChanged(value - 1);
      if (key == 'plus') onChanged(value + 1);
    },
  );
}
```
`[inferred]` — this is one workable shape, not a canonical widget; a plain `Row` with two `CupertinoButton`s and a shared rounded-rect `Container` background is equally valid and arguably simpler.

### 1.7 Anchored popover — no drop-in widget

`app-component-anatomy.md` §"Modals, Sheets, Alerts, Popovers" describes an arrow-anchored floating card for iPad/Mac contextual options. Flutter's SDK has no `UIPopoverPresentationController` equivalent; build one from `CompositedTransformTarget`/`CompositedTransformFollower` (SDK, [documented]) plus an `OverlayEntry`:

```dart
final LayerLink _link = LayerLink();
OverlayEntry? _popoverEntry;

void _showPopover(BuildContext context) {
  _popoverEntry = OverlayEntry(
    builder: (context) => Positioned(
      width: 280,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        offset: const Offset(0, 44), // below the anchor; add arrow art yourself
        child: Material( // Material only used for the elevation shadow/clip;
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          elevation: 8,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: SortOptionsView(),
          ),
        ),
      ),
    ),
  );
  Overlay.of(context).insert(_popoverEntry!);
}

void _dismissPopover() {
  _popoverEntry?.remove();
  _popoverEntry = null;
}

// Wrap the trigger control:
CompositedTransformTarget(
  link: _link,
  child: CupertinoButton(onPressed: () => _showPopover(context), child: const Text('Sort')),
);
```
`[inferred]` — this is a workable shape, not a canonical widget; you own the arrow graphic, dismiss-on-tap-outside logic (a full-screen transparent `GestureDetector` behind the popover in the `Overlay`), and iPhone-vs-iPad fallback-to-sheet behavior that `.popover()` gives for free in SwiftUI (`navigation-models.md` §2.7's "iPhone: system converts popovers to action sheets automatically" has no automatic equivalent here — branch on screen width yourself).

### 1.8 Status components — badges and activity indicators

```dart
// Tab bar badge
BottomNavigationBarItem(
  icon: Stack(
    clipBehavior: Clip.none,
    children: [
      const Icon(CupertinoIcons.tray),
      Positioned(
        right: -6,
        top: -4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: CupertinoColors.destructiveRed,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$unreadCount',
            style: const TextStyle(color: CupertinoColors.white, fontSize: 11),
          ),
        ),
      ),
    ],
  ),
  label: 'Inbox',
);

// Indeterminate activity indicator — CupertinoActivityIndicator is the SDK's
// direct port of UIActivityIndicatorView, auto-adapts to Dark/Light mode.
const CupertinoActivityIndicator(radius: 14);

// Determinate progress — no direct Cupertino progress bar; Material's
// LinearProgressIndicator is commonly reused even in Cupertino-styled apps,
// tinted to match, since the SDK has no Cupertino-specific bar widget.
LinearProgressIndicator(
  value: uploadedCount / totalCount,
  color: CupertinoColors.activeBlue,
  backgroundColor: CupertinoColors.systemGrey5,
);
```
`[observed]` — reusing `LinearProgressIndicator` in an otherwise-Cupertino app is a common pragmatic choice, not a purist one; there is no `Cupertino`-namespaced determinate progress bar in the SDK as of this writing.

---

## 2. Sheet detents

As covered in the `apple-design-interaction` flutter-implementation.md §1.3, Flutter's own SDK has **no** direct port of `presentationDetents([.medium, .large])` with drag-between-snap-points behavior. Three tiers, roughest to closest:

1. **`showCupertinoModalPopup`** — fixed-height sheet only, no drag-to-resize. Fine for a single, known height.
2. **`DraggableScrollableSheet`** (SDK, [documented]) — genuinely supports `snapSizes`, so it is the SDK's actual lower-level answer to detents, just not exposed through a route-presentation API the way `presentationDetents` is:
   ```dart
   showCupertinoModalPopup<void>(
     context: context,
     builder: (context) => DraggableScrollableSheet(
       initialChildSize: 0.5,
       minChildSize: 0.3,
       maxChildSize: 0.95,
       snap: true,
       snapSizes: const [0.5, 0.95], // approximates [.medium, .large]
       builder: (context, scrollController) => Container(
         decoration: const BoxDecoration(
           color: CupertinoColors.systemBackground,
           borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
         ),
         child: ListView(controller: scrollController, children: sheetContent),
       ),
     ),
   );
   ```
3. **`wolt_modal_sheet`** or the **`sheet`** package — third-party, purpose-built for iOS-style multi-detent sheets with a grabber and drag physics closer to native feel. `[inferred — verify current API on pub.dev]`

Choose (2) when you control the content and just need snap points; choose (3) when you want the grabber, corner-radius, and drag-velocity feel handled for you without reimplementing it.

---

## 3. Widgets, lock screen, and Dynamic Island — not reachable from pure Flutter

This is a hard boundary, not a missing-package problem. Be direct with anyone planning around it:

- **Home-screen widgets** (`ios-ipados.md` §"Home Screen" widget sizes) require a native `WidgetKit` extension target written in Swift — there is no Dart API that renders into that surface, because widgets run in a separate host process outside the Flutter engine entirely. `[documented]` The `home_widget` package `[inferred — verify on pub.dev]` is the standard bridge: it lets your Flutter app **write data** (via shared `UserDefaults`/App Group storage) that a **separately-written native WidgetKit extension** reads and renders. Flutter code does not draw the widget UI; it only supplies data to native code that does.
- **Lock screen widgets** are the same WidgetKit surface, same constraint — native extension required, Flutter only supplies data through `home_widget` or an equivalent platform channel.
- **Live Activities and the Dynamic Island** (`ios-ipados.md` §"Status Bar and Dynamic Island", `gestures-interaction.md` §"Dynamic Island Interactions") have **no Flutter API at all**, not even a bridging package with meaningful reach — `ActivityKit` is an iOS-only, Swift-only framework tied to a native app extension's lifecycle, and the compact/expanded/minimal pill states are rendered entirely by the OS, not by any app process. `[documented]` A Flutter app can at best: (a) trigger a Live Activity's *start/update/end* through a platform channel that calls into a small native Swift shim which itself calls `ActivityKit`, and (b) supply that shim with the data to display. The actual Dynamic Island rendering, morphing, and interaction handling remains 100% native Swift — there is no partial-Flutter path into that surface.

```dart
// The realistic Flutter-side shape: coordinate, don't render.
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.example.app/live_activity');

Future<void> startDeliveryActivity(String orderId, String eta) {
  // This call reaches a native Swift MethodChannel handler that owns the
  // actual ActivityKit Activity<DeliveryAttributes>.start(...) call.
  // [documented — this hand-off pattern is required, not optional]
  return _channel.invokeMethod('start', {'orderId': orderId, 'eta': eta});
}
```

If a client's app concept genuinely depends on Dynamic Island presence as a differentiator, say so plainly up front: it needs a native iOS engineer writing a WidgetKit/ActivityKit extension regardless of how much of the rest of the app is Flutter.

---

## 4. macOS desktop specifics (Flutter desktop target)

When the same Flutter codebase also targets macOS as a desktop app (`macos.md`'s window/sidebar/menu-bar surfaces), plain Cupertino widgets stop being enough — those are phone/tablet-shaped components, not macOS window chrome.

### 4.1 Custom window chrome (traffic lights, draggable title bar)

Flutter desktop does not draw macOS's native traffic-light buttons or title-bar drag region for you by default in a frameless/custom-chrome window. Two commonly cited packages:

- **`bitsdojo_window`** `[inferred — verify on pub.dev]` — cross-platform custom window chrome (works across macOS/Windows/Linux), gives you drag regions and min/max/close hookups you wire to your own UI.
- **`window_manager`** `[inferred — verify on pub.dev]` — lower-level window control (size, position, always-on-top, title-bar style) that is also cross-platform.

Neither package reproduces Apple's exact traffic-light colors/spacing/hover-symbol behavior (`macos.md` §"Traffic Light Buttons" gives precise hex values and spacing) automatically — if pixel-accurate native traffic lights matter more than a custom-styled control cluster, prefer `setWindowButtonVisibility`-style APIs that keep the **real** native traffic lights visible and only control their position, rather than painting fake ones. `[inferred]` A hand-painted traffic-light triplet is one of `macos.md`'s explicit anti-patterns ("Fake Traffic Lights with Wrong Metrics") — don't recreate that mistake in Flutter by eyeballing the colors.

### 4.2 Sidebar and macOS-native widget fidelity — `macos_ui`

Plain `CupertinoTabScaffold`/`NavigationRail` can approximate a sidebar layout structurally, but neither reproduces macOS's actual sidebar vibrancy material, row metrics, or menu-bar-adjacent conventions from `macos.md` §"Sidebars"/§"Menu Bar and Menus". The **`macos_ui`** package `[inferred — verify current widget catalog on pub.dev]` is the closest thing to a native-macOS Flutter widget set — it specifically ports macOS-style sidebars, toolbars, and controls rather than reusing iOS-shaped Cupertino widgets on a desktop window:

```dart
import 'package:macos_ui/macos_ui.dart'; // [inferred — verify on pub.dev]

MacosWindow(
  sidebar: Sidebar(
    minWidth: 200,
    builder: (context, scrollController) => SidebarItems(
      currentIndex: _selectedIndex,
      onChanged: (i) => setState(() => _selectedIndex = i),
      items: const [
        SidebarItem(leading: MacosIcon(CupertinoIcons.mail), label: Text('Inbox')),
        SidebarItem(leading: MacosIcon(CupertinoIcons.archivebox), label: Text('Archive')),
      ],
    ),
  ),
  child: MacosScaffold(
    toolBar: const ToolBar(title: Text('Mail')),
    children: [
      ContentArea(builder: (context, scrollController) => const InboxView()),
    ],
  ),
);
```

For a Flutter macOS app, plain `NavigationRail` (Material, generic-looking) is the fallback when you don't want the `macos_ui` dependency; it will read as "cross-platform app," not "native Mac app" — a legitimate choice, just not the one that satisfies `macos.md`'s fidelity bar.

### 4.3 What doesn't port at all on macOS desktop

- **Global menu bar** (`macos.md` §"Menu Bar and Menus" — App/File/Edit/View/Window/Help) has no direct Cupertino-widget equivalent; `PlatformMenuBar` (SDK, [documented]) is Flutter's actual mechanism for populating the real macOS menu bar, separate from anything `macos_ui` or Cupertino widgets provide.
- **Tahoe-era Liquid Glass vibrancy on sidebars/toolbars** (`NSGlassEffectView`) has no Flutter rendering equivalent — `macos_ui`'s sidebar can approximate translucency with `BackdropFilter`, but it will not track the OS's live glass material the way a native AppKit view does.

---

## 5. visionOS and watchOS — reality check

State this plainly rather than inventing a fake API: **Flutter has no visionOS support and an extremely limited watchOS story.** `[documented, as of this writing]`

- **visionOS**: Flutter does not run on visionOS as a first-class target. There is no Cupertino-widget path to spatial windows, ornaments, immersive spaces, or eye/pinch input (`visionos-watchos.md` §"visionOS") — the rendering model (system-composited glass windows, real-time environmental lighting response, depth/Z-layering enforced by the OS) is fundamentally not something Flutter's single-surface Skia/Impeller rendering targets. If a project genuinely needs a visionOS presence, that is native SwiftUI/RealityKit work, full stop — not a Flutter port, not a plugin, not a "coordinate via platform channel" workaround the way Dynamic Island (§3) at least partially allows. Do not present any Flutter-side code as a visionOS solution.
- **watchOS**: Flutter does not target watchOS as an app surface at all. A companion Apple Watch app for a Flutter-based iPhone app is native code (SwiftUI + WatchConnectivity to talk back to the phone app) — Flutter's role, if any, is limited to the iOS-side `WatchConnectivity` platform-channel plumbing on the phone, never to anything rendered on the watch face itself. Complications (`visionos-watchos.md` §"watchOS" `WidgetKit` complication families) are exactly as unreachable from Dart as Dynamic Island widgets are (§3), for the same reason: they render in a native extension process.

If a client asks for "the Flutter app, but also on Vision Pro / Apple Watch," the honest answer is a separate native app sharing, at best, a backend/API layer with the Flutter codebase — not a shared UI layer.

---

## 6. Liquid Glass — what Cupertino widgets do and don't give you

`ios-ipados.md` and `macos.md` describe iOS 26/macOS Tahoe's Liquid Glass material extensively (frosted nav bars, floating capsule tab bars, glass buttons). Flutter's Cupertino widgets are **not** automatically updated to render this material — `CupertinoNavigationBar`/`CupertinoTabBar` render the pre-Liquid-Glass translucent-blur style (a `BackdropFilter` blur, which does predate Liquid Glass and still looks reasonable), not the newer specular-highlight glass. `[observed]` Approximating the newer look manually with `BackdropFilter` + `ImageFilter.blur` + a subtle gradient overlay is possible but will not track Apple's system-tuned frosting the way a native SwiftUI app compiled against the iOS 26 SDK does automatically. Treat any hand-built "Liquid Glass" Flutter widget as a visual approximation, not a material system — see `apple-design-materials` for the broader glass-rendering gap on non-native platforms.

---

## 7. Package reference

| Package / API | Replaces / augments | Confidence |
|---|---|---|
| `CupertinoNavigationBar`, `CupertinoSliverNavigationBar`, `CupertinoTabBar`, `CupertinoTabScaffold`, `CupertinoListSection`, `CupertinoListTile`, `CupertinoSearchTextField`, `CupertinoActionSheet`, `CupertinoAlertDialog`, `CupertinoSlidingSegmentedControl`, `CupertinoSwitch`, `CupertinoPicker`, `CupertinoDatePicker` (all SDK) | Standard iOS component anatomy | `[documented]` |
| `DraggableScrollableSheet` (SDK) | Lower-level building block for detent-like snap sizes | `[documented]` |
| `wolt_modal_sheet` / `sheet` | Full multi-detent sheet UX with grabber + drag physics | `[inferred — verify on pub.dev]` |
| `home_widget` | Data bridge to a native iOS WidgetKit / Android home-screen widget extension | `[inferred — verify on pub.dev]` |
| `bitsdojo_window` / `window_manager` | Custom desktop window chrome, drag regions, traffic-light positioning | `[inferred — verify on pub.dev]` |
| `macos_ui` | Native-feeling macOS sidebar/toolbar/controls | `[inferred — verify on pub.dev]` |
| `PlatformMenuBar` (SDK) | Populating the real macOS global menu bar | `[documented]` |

---

## 8. Honest gaps vs. native, summarized

- **Dynamic Island and Live Activities: no Flutter rendering path, ever.** Coordinate via platform channel into native Swift/ActivityKit at best.
- **Home/lock-screen widgets: no Flutter rendering path.** `home_widget`-style packages move data, not UI, across the boundary to a separately written native extension.
- **visionOS: no Flutter support at all.** Native SwiftUI/RealityKit only.
- **watchOS: no meaningful Flutter app surface.** A watch companion app is native; Flutter's role stops at phone-side `WatchConnectivity` plumbing.
- **Sheet detents: partial.** `DraggableScrollableSheet` gets you snap sizes; the polished grabber/drag-physics/corner-radius package is third-party.
- **Liquid Glass: visual approximation only.** No Cupertino widget renders the actual iOS 26/Tahoe material; hand-built `BackdropFilter` approximations will drift from what Apple ships as the OS is updated.
- **True continuous-corner squircles: not available.** (See `apple-design-materials`.) Flutter's `BorderRadius`/`RoundedRectangleBorder` are true rounded rectangles, not Apple's continuous corner-radius curve — relevant to icon/card shapes referenced throughout `app-component-anatomy.md`.

Component anatomy for standard iOS/iPadOS screens — nav bars, lists, forms, buttons, alerts, search — has strong, idiomatic Cupertino coverage. The gaps above are specifically the surfaces that live outside the app's own view hierarchy (widgets, lock screen, Dynamic Island) or outside iOS altogether (visionOS, watchOS, macOS's native chrome) — say so plainly rather than stretching a Cupertino widget to cover something it structurally cannot reach.
