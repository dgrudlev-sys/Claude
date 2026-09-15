# Flutter Implementation — Navigation, State & Feedback, Performance, Input

**Scope**: Dart/Flutter equivalents for the behavioral decisions in `navigation-models.md`, `state-and-feedback-logic.md`, and `perceived-performance-and-input.md`. Those files remain authoritative on *when* to push vs. sheet vs. modal, *when* a skeleton beats a spinner, *when* optimistic UI is safe. This file is the *how*, in Cupertino-flavored Flutter.

Package names are current as of this writing but not version-pinned — verify current API shape on pub.dev before depending on exact method signatures. Anything not in the Flutter SDK itself is marked `[inferred]`.

---

## 1. Navigation models

### 1.1 Decision table → Flutter API

| Decision (`navigation-models.md`) | Flutter API |
|---|---|
| Push/pop, parent-child drill-down | `Navigator.push(context, CupertinoPageRoute(...))` |
| Sheet, self-contained sub-task | `showCupertinoModalPopup` / `showCupertinoSheet` (iOS 16+ style), or `modal_bottom_sheet` package for finer detent control |
| Full-screen cover, immersive/gated flow | `Navigator.push` with a route that has `fullscreenDialog: true` |
| Modal alert, blocking decision | `showCupertinoDialog` |
| Tab bar, 2–5 peer sections | `CupertinoTabScaffold` + `CupertinoTabBar` |
| Popover, transient contextual options (iPad/desktop) | `showCupertinoModalPopup` anchored via `CupertinoPopoverMenu`-style positioning, or a plain `Overlay` entry — Flutter has no first-class anchored-popover widget as polished as UIKit's `UIPopoverPresentationController` |
| Split view, sidebar + detail (iPad/Mac) | `NavigationRail`/side `Row` layout keyed off `MediaQuery` width, or a bespoke two-pane `Row`; no direct `NavigationSplitView` port exists in Cupertino widgets |

### 1.2 Push — `CupertinoPageRoute`

`CupertinoPageRoute` already gives you the iOS slide-in transition **and** the interactive edge-swipe-back gesture for free — this is the one piece of `navigation-models.md` §2.1's "back behavior" that requires zero extra code. [documented]

```dart
Navigator.of(context).push(
  CupertinoPageRoute(
    title: 'Item Detail', // used as the back-button label, matching HIG's
                           // rule that back always shows the PREVIOUS title
    builder: (context) => ItemDetailPage(item: item),
  ),
);
```

Value-based / typed navigation (the modern `NavigationStack(path:)` equivalent from `navigation-models.md` §2.1) is best handled with **`go_router`** [inferred — verify current API on pub.dev], which also covers deep-linking and state restoration in one package rather than three separate mechanisms:

```dart
import 'package:go_router/go_router.dart'; // [inferred — verify on pub.dev]

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ProductListPage(),
      routes: [
        GoRoute(
          path: 'product/:id',
          builder: (context, state) =>
              ProductDetailPage(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);

// Deep link / programmatic navigation both go through the same typed API —
// mirrors the source rule "always express destination as data, never a
// hard-coded push sequence."
context.go('/product/42');
```

### 1.3 Sheets and detents

Flutter's built-in `showCupertinoModalPopup` gives you a bottom sheet with the correct dim/scrim behavior, but **not** iOS 16's resizable `.medium`/`.large` detents — there is no first-party Cupertino widget that exposes drag-between-snap-points the way `presentationDetents` does. [documented gap]

```dart
// Fixed-height sheet — closest built-in equivalent to a single detent.
showCupertinoModalPopup<void>(
  context: context,
  builder: (context) => Container(
    height: MediaQuery.of(context).size.height * 0.5, // approximates .medium
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: CupertinoColors.systemBackground,
      borderRadius: BorderRadius.vertical(top: Radius.circular(13)), // HIG's 13pt sheet radius
    ),
    child: const ComposeView(),
  ),
);
```

For real multi-detent, draggable-between-snap-points sheets (the actual `presentationDetents([.medium, .large])` behavior), reach for a dedicated package rather than reimplementing drag physics — `wolt_modal_sheet` or the `sheet` package are the commonly cited options. `[inferred — verify current API and detent-configuration shape on pub.dev; this is a real gap in Flutter's own SDK surface, not a matter of taste]`

```dart
// Illustrative shape only — confirm exact API against the package's current docs.
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart'; // [inferred — verify on pub.dev]

WoltModalSheet.show<void>(
  context: context,
  pageListBuilder: (context) => [
    WoltModalSheetPage(
      child: const ComposeView(),
      // Detent-like behavior is configured via this package's own sizing
      // API — check pub.dev for the current property names.
    ),
  ],
);
```

Cancel/Done placement rules from `navigation-models.md` §2.2 (right = primary/bold, left = explicit Cancel, confirm before discarding unsaved input) are pure UI convention and port directly regardless of which sheet mechanism you use:

```dart
CupertinoNavigationBar(
  leading: CupertinoButton(
    padding: EdgeInsets.zero,
    child: const Text('Cancel'),
    onPressed: () => _confirmDiscardIfDirty(context),
  ),
  trailing: CupertinoButton(
    padding: EdgeInsets.zero,
    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
    onPressed: _isValid ? _save : null, // disabled until valid, per source rule
  ),
);
```

### 1.4 Full-screen cover — no drag dismiss

```dart
Navigator.of(context).push(
  CupertinoPageRoute(
    fullscreenDialog: true, // suppresses swipe-back, forces an explicit close control
    builder: (context) => CameraPage(
      onClose: () => Navigator.of(context).pop(),
    ),
  ),
);
```
Matches `navigation-models.md` §2.3's rule precisely: `fullscreenDialog: true` disables the interactive pop gesture, so you must supply an explicit "Cancel"/"Done" — the framework does not let this be dismissed by an accidental swipe. [documented]

### 1.5 Modal alerts

```dart
showCupertinoDialog<void>(
  context: context,
  builder: (context) => CupertinoAlertDialog(
    title: const Text('Delete Item?'),
    content: const Text('This action cannot be undone.'),
    actions: [
      CupertinoDialogAction(
        isDestructiveAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Delete'),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  ),
);
```

### 1.6 Tabs — `CupertinoTabScaffold`

`CupertinoTabScaffold` already gives you per-tab navigation-stack preservation (`navigation-models.md` §2.5's "each tab preserves its own navigation state") for free, because each `CupertinoTabView` owns its own `Navigator`: [documented]

```dart
CupertinoTabScaffold(
  tabBar: CupertinoTabBar(
    items: const [
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.news), label: 'Feed'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: 'Search'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.book), label: 'Library'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
    ],
  ),
  tabBuilder: (context, index) {
    final pages = [
      const FeedPage(),
      const SearchPage(),
      const LibraryPage(),
      const ProfilePage(),
    ];
    return CupertinoTabView(
      builder: (context) => pages[index],
    );
  },
);
```
Keep to 2–5 items; Flutter enforces nothing about tab count or "tabs are not actions" — those rules from `navigation-models.md` §2.5 remain the developer's responsibility.

### 1.7 State restoration and deep linking

- **`go_router`** (§1.2) doubles as the deep-link entry point: parse the inbound URL/intent, translate to a route, `context.go(...)`. Never hand-chain pushes — same "always express destination as data" rule.
- Flutter's `RestorationMixin` + `RestorationProperty` (SDK) [documented] is the native equivalent of `@SceneStorage` for surviving background/foreground cycles — attach a `restorationId` to `MaterialApp`/`CupertinoApp` and to individual routes/state objects that need to rehydrate.
- Scroll position is not auto-preserved any more than in SwiftUI — use a `PageStorageKey` on scrollable widgets (SDK, [documented]) so `ListView`/`CustomScrollView` remember offset across rebuilds/tab switches, or track a target item id yourself and `scrollController.jumpTo`/`animateTo` it on restore, mirroring the source's `ScrollViewReader` pattern.

```dart
ListView.builder(
  key: const PageStorageKey('feed-list'), // preserves scroll offset across tab switches
  itemBuilder: (context, index) => FeedRow(items[index]),
  itemCount: items.length,
);
```

---

## 2. State & feedback logic

### 2.1 Skeleton / shimmer loading

Flutter has no built-in `.redacted(reason: .placeholder)`; the `shimmer` package is the standard substitute. `[inferred — verify current API on pub.dev]` Size the placeholder to match real content dimensions exactly, per `state-and-feedback-logic.md` §1's rule.

```dart
import 'package:shimmer/shimmer.dart'; // [inferred — verify on pub.dev]

Widget skeletonRow() {
  return Shimmer.fromColors(
    baseColor: CupertinoColors.systemGrey5,
    highlightColor: CupertinoColors.systemGrey6,
    period: const Duration(milliseconds: 1400), // 1-2s cycle per source guidance
    child: Container(
      height: 72,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

Widget feedList(bool isLoading, List<Item> items) {
  if (isLoading) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => skeletonRow(),
    );
  }
  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, i) => FeedRow(items[i]),
  );
}
```

Respect the latency thresholds from `perceived-performance-and-input.md`/`state-and-feedback-logic.md` §1: don't show any loading UI under ~100 ms; show a skeleton (not a bare spinner) whenever the content shape is known; use `CupertinoActivityIndicator` only for genuinely indeterminate waits with unknown layout.

```dart
FutureBuilder<List<Item>>(
  future: _future,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      // A real app would additionally delay showing this for ~100ms via a
      // debounce Timer, so sub-100ms responses never flash a skeleton at all.
      return skeletonList();
    }
    if (snapshot.hasError) return ErrorStateView(onRetry: _retry);
    final items = snapshot.data!;
    if (items.isEmpty) return const EmptyStateView();
    return FeedList(items: items);
  },
);
```

### 2.2 Empty and error state widgets

Flutter has no `ContentUnavailableView` equivalent shipped in the SDK — build one small reusable widget once and reuse it everywhere, which also enforces the source's rule that every empty/error state gets an icon + title + description + action:

```dart
class ContentUnavailableView extends StatelessWidget {
  const ContentUnavailableView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: CupertinoColors.systemGrey),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CupertinoColors.secondaryLabel),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              CupertinoButton.filled(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// Usage — load failure, matches state-and-feedback-logic.md §3's copy rule:
// state what happened + what the user can do, never blame the user.
ContentUnavailableView(
  icon: CupertinoIcons.wifi_slash,
  title: "Couldn't Load Feed",
  message: 'Check your connection and try again.',
  actionLabel: 'Try Again',
  onAction: _retry,
);
```

Overlay it on an otherwise-empty scroll container rather than replacing the container's layout, matching the source's "must not change the scroll container's dimensions" rule:

```dart
Stack(
  children: [
    ListView(children: rows), // present even when rows is empty, keeps scroll physics stable
    if (rows.isEmpty)
      const ContentUnavailableView(
        icon: CupertinoIcons.tray,
        title: 'No Items Yet',
        message: 'Items you add will appear here.',
      ),
  ],
);
```

### 2.3 Optimistic UI with rollback

The three-phase contract from `state-and-feedback-logic.md` §5 (apply immediately → reconcile → roll back gracefully, never silently) ports directly to local state mutation ahead of an async call:

```dart
Future<void> toggleLike(Item item) async {
  final previousValue = item.isLiked;
  setState(() => item.isLiked = !previousValue); // 1. apply immediately

  try {
    await api.setLiked(item.id, item.isLiked); // 2. reconcile with server
  } catch (e) {
    setState(() => item.isLiked = previousValue); // 3. roll back gracefully
    if (mounted) {
      _showToast("Couldn't update — try again."); // never fail silently
    }
  }
}
```

Only apply this to low-risk, reversible, idempotent actions (like/bookmark/reorder) per the source's "when it is safe" list — never to financial or destructive operations.

### 2.4 Pull-to-refresh

`CupertinoSliverRefreshControl` is the native-feeling built-in for Cupertino scroll views — do not hand-roll custom pull physics, matching the source's explicit anti-pattern warning: [documented]

```dart
CustomScrollView(
  slivers: [
    CupertinoSliverRefreshControl(
      onRefresh: () async {
        await viewModel.reload(); // the indicator stays visible until this resolves
      },
    ),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => FeedRow(items[index]),
        childCount: items.length,
      ),
    ),
  ],
);
```
Material-styled apps would use `RefreshIndicator` instead, but for a Cupertino-consistent feel `CupertinoSliverRefreshControl` is the correct choice.

### 2.5 Pagination and infinite scroll

Plain `ListView.builder` + a scroll-position listener is the minimal approach; `infinite_scroll_pagination` [inferred — verify pub.dev] is the standard package when you also want built-in loading/error/empty page states without hand-rolling them:

```dart
// Minimal hand-rolled version
final ScrollController _scrollController = ScrollController()
  ..addListener(() {
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 400 && !_isLoadingMore) {
      _loadNextPage(); // sentinel-based fetch, matches source's "spinner at
                        // bottom sentinel while fetching" rule
    }
  });
```

```dart
// infinite_scroll_pagination — handles the loading/error/empty sentinel states
// for you [inferred — verify current API shape on pub.dev]
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

final PagingController<int, Item> _pagingController =
    PagingController(firstPageKey: 0);

PagedListView<int, Item>(
  pagingController: _pagingController,
  builderDelegate: PagedChildBuilderDelegate<Item>(
    itemBuilder: (context, item, index) => FeedRow(item),
  ),
);
```

For content types the source recommends a "Load more" button over infinite scroll for (search results, catalogs), just gate the sentinel fetch behind an explicit `CupertinoButton` tap instead of a scroll listener — same underlying page-fetch logic either way.

---

## 3. Perceived performance

### 3.1 Precaching images

`precacheImage` (SDK) [documented] is Flutter's direct equivalent of prefetching the next screen's hero image before navigation, per `perceived-performance-and-input.md`'s "preload the next screen's content while the user is still on the current one" rule:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  for (final item in upcomingItems) {
    precacheImage(NetworkImage(item.thumbnailUrl), context);
  }
}
```

### 3.2 Prefetch-on-intent

There is no Flutter equivalent of the web's Speculation Rules API (`perceived-performance-and-input.md` recipe "prefetch on hover intent") because there is no hover-intent signal on touch devices — the nearest analogue is prefetching a detail page's data as soon as its list row is built (or becomes visible), not waiting for the tap:

```dart
ListView.builder(
  itemBuilder: (context, index) {
    final item = items[index];
    unawaited(detailRepository.warmCache(item.id)); // fire-and-forget prefetch
    return FeedRow(item);
  },
  itemCount: items.length,
);
```
`[inferred]` — this trades some wasted network/CPU for perceived latency; gate it behind connectivity/data-saver checks in a real app.

### 3.3 Skeleton timing threshold in code

Encode the Nielsen/Norman thresholds from `perceived-performance-and-input.md` as a small debounce so sub-100 ms responses never flash a skeleton, matching the source's explicit rule "never show a spinner for sub-100ms operations":

```dart
class DebouncedLoadingState extends StatefulWidget {
  const DebouncedLoadingState({super.key, required this.future, required this.builder});
  final Future<void> future;
  final Widget Function(bool showLoading) builder;

  @override
  State<DebouncedLoadingState> createState() => _DebouncedLoadingStateState();
}

class _DebouncedLoadingStateState extends State<DebouncedLoadingState> {
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showLoading = true);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(_showLoading);
}
```

---

## 4. Focus, keyboard, and hit targets

### 4.1 Minimum 44×44 tap targets

Flutter draws visuals at whatever size you specify; nothing enforces the 44×44 pt minimum from `perceived-performance-and-input.md`'s Hit Targets section. Wrap small visual elements in `SizedBox`/`Padding` (or use `GestureDetector.behavior: HitTestBehavior.opaque` over a larger invisible area) rather than shrinking the tap area to match a small icon:

```dart
SizedBox(
  width: 44,
  height: 44,
  child: CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: _delete,
    child: const Icon(CupertinoIcons.delete, size: 20), // visual smaller than the hit box
  ),
);
```
`CupertinoButton`'s default padding already tends toward comfortable targets for text buttons, but icon-only buttons need this check explicitly. Maintain ≥8 pt spacing between adjacent tap targets per the source's practitioner rule.

### 4.2 Focus order and traversal

`FocusNode` + `FocusTraversalGroup` (SDK) [documented] is the direct port of `perceived-performance-and-input.md`'s focus model — every action reachable by touch must also be reachable via hardware keyboard/Tab, especially relevant for iPad-with-keyboard and desktop Flutter targets:

```dart
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(
        order: const NumericFocusOrder(1),
        child: CupertinoTextField(focusNode: _emailFocus),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(2),
        child: CupertinoTextField(focusNode: _passwordFocus),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(3),
        child: CupertinoButton.filled(onPressed: _submit, child: const Text('Sign In')),
      ),
    ],
  ),
);
```

### 4.3 Semantics for assistive tech

`Semantics` (SDK) [documented] is where hit-target intent and reading order become visible to VoiceOver/TalkBack — wrap custom-painted or gesture-only controls that have no default semantic meaning:

```dart
Semantics(
  button: true,
  label: 'Delete item',
  hint: 'Removes this item from your list',
  child: GestureDetector(
    onTap: _delete,
    child: const Icon(CupertinoIcons.delete),
  ),
);
```

### 4.4 Keyboard type and submit hints

Match `perceived-performance-and-input.md`'s "match the keyboard type to the content" rule via `CupertinoTextField`'s `keyboardType` and `textInputAction`:

```dart
CupertinoTextField(
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.next, // closest analogue to enterKeyHint="next"
  placeholder: 'Email',
  autocorrect: false,
);

CupertinoTextField(
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  textInputAction: TextInputAction.done,
  placeholder: 'Price',
);
```
Flutter's `autofillHints` property (SDK) [documented] is the equivalent of `UITextContentType`/`autocomplete` — annotate fields so the platform's password/address autofill can engage:

```dart
CupertinoTextField(
  autofillHints: const [AutofillHints.email],
  keyboardType: TextInputType.emailAddress,
);
```

---

## 5. Package reference

| Package | Replaces / augments | Confidence |
|---|---|---|
| `go_router` | `NavigationStack(path:)` value-based nav, deep linking, state restoration | `[inferred — verify on pub.dev]` |
| `wolt_modal_sheet` / `sheet` | `presentationDetents([.medium, .large])` draggable multi-detent sheets | `[inferred — verify on pub.dev]` — genuine SDK gap |
| `modal_bottom_sheet` | Alternate route to sheet styles beyond the SDK's fixed `showCupertinoModalPopup` | `[inferred — verify on pub.dev]` |
| `shimmer` | `.redacted(reason: .placeholder)` shimmer skeletons | `[inferred — verify on pub.dev]` |
| `infinite_scroll_pagination` | Boilerplate-free infinite-scroll loading/error/empty page states | `[inferred — verify on pub.dev]` |
| `CupertinoSliverRefreshControl` (SDK) | `.refreshable { }` pull-to-refresh | `[documented]` |
| `precacheImage`, `RestorationMixin`, `PageStorageKey`, `Semantics`, `FocusTraversalGroup` (all SDK) | Prefetching, state restoration, scroll-position memory, accessibility semantics, keyboard focus order | `[documented]` |

---

## 6. Honest gaps vs. native

- **No first-party multi-detent sheet.** This is the single biggest navigation-model gap: Flutter's own SDK cannot reproduce `presentationDetents([.medium, .large])` with drag-between-snap-points behavior without a third-party package. Evaluate `wolt_modal_sheet`/`sheet` (or build a custom `DraggableScrollableSheet`-based one, which the SDK does ship and can be configured with `snapSizes` — a partial, lower-level answer worth knowing about `[documented]`) before assuming a package is required.
- **No `NavigationSplitView` port.** Sidebar+content+detail three-column adaptive layouts have no direct Cupertino widget; you assemble one from `Row`/`NavigationRail`/breakpoint checks by hand.
- **No polished anchored popover.** iPad/desktop Flutter apps wanting a `UIPopoverPresentationController`-style anchored, arrow-pointing overlay have to build it from `CompositedTransformTarget`/`CompositedTransformFollower` (SDK primitives, [documented]) or an `Overlay` entry — there's no drop-in equivalent.
- **`ContentUnavailableView` must be hand-rolled.** Not hard, but every app rebuilds the same small widget — worth centralizing once, as shown in §2.2.
- **Prefetch-on-hover-intent has no touch analogue.** The web's speculation-rules recipe simply doesn't map to a touch-first platform; §3.2's "prefetch on row build" is the practical substitute, not an equivalent.

Everything else — pushes, tabs, alerts, pull-to-refresh, pagination, optimistic UI, hit targets, focus order — has a solid, idiomatic SDK-level or well-established-package path.
