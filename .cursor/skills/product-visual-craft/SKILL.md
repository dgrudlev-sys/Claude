---
name: product-visual-craft
description: Use when designing, laying out, styling, or reviewing Flutter UI in this repo — screens, cards, panels, themes, icons, spacing, type, motion, visual copy, or anything the user will see and touch.
---

# Product visual craft

Apple product-design-team standard. The UI should feel inevitable: driving a Ferrari, not assembling a kit. Operational rules below — follow them on every visual change. Do not ship a “good enough” card or panel and redo it later.

**Scope:** raise the shared system and the surfaces you touch. Do not restyle every screen from scratch. Small coherent upgrades beat a theme rewrite that breaks tests.

## Before you draw

1. Name the job of the surface in one sentence (what the person needs to know or do).
2. Choose one primary object. Everything else is supporting.
3. Use tokens from `scientific-calculator/lib/theme/app_metrics.dart` (`AppMetrics`, `AppMotion`). No new magic numbers unless you are adding a token.
4. Check the 8pt grid, optical icon alignment, motion, and copy against this skill before calling the UI done.

## Spacing (8pt grid)

| Token | px | Use |
|-------|----|-----|
| `AppMetrics.space1` | 4 | Tight related pairs (label → value) |
| `AppMetrics.space2` | 8 | Default gap inside a card |
| `AppMetrics.space3` | 16 | Card padding, section gap |
| `AppMetrics.space4` | 24 | Screen inset bottom, major sections |
| `AppMetrics.space5` | 32 | Rare: isolated hero blocks |

Screen horizontal inset: **16**. Card padding: **16**. List row vertical: **12–16**. Related items: 8. Unrelated groups: 16 or 24.

Forbidden: 6, 10, 14, 18, 20 as padding (14 was an old radius — do not reintroduce it for space). If something looks “almost,” it is wrong; snap to the grid.

## Cards, radius, chrome

- **Radius:** cards `16`, controls/fields `12`, pills `20`.
- **Hairline:** 1px `colorScheme.outline` at ~35% opacity on dark surfaces. Use for resting cards.
- **Fill / tint:** slightly lifted surface vs scaffold (see `AppMetrics.cardFill`). Use for grouped content.
- **Elevation:** 0 at rest. No floating Material shadows on dark calculator chrome. Elevation only for modal sheets / overlays that must leave the plane.
- **Padding:** 16 all sides unless the card is a dense keypad (then follow keypad metrics).

Pick one chrome language per surface: hairline **or** tint **or** (sheets) elevation — not all three.

## Type

Use `Theme.textTheme`. Do not invent font sizes.

| Role | Style | Line-height | Letter-spacing |
|------|--------|-------------|----------------|
| Card headline / rate | `titleMedium` w600 | 1.25 | −0.2 |
| Body / walkthrough sentence | `bodyMedium` | 1.40 | 0 |
| Supporting (“as of…”) | `bodySmall` | 1.30 | 0.1 |
| Equation | `titleMedium` w600, tabular/monospace | 1.20 | 0 |
| Section title | `titleLarge` w700 | 1.20 | −0.3 |

Never cramped labels. `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft)` when a label might overflow. Avoid a one-word widow on the last line when a short rewrite or a line break before the last 2–3 words fixes it. Copy like “as of 27 August 2026” stays on one line if it fits; do not split the date.

## Icons

- Size **24** in lists/headers; **28** for a status glyph beside a rate line.
- `Align`/`Center` the icon in a fixed square (`SizedBox(width: size, height: size)`). The tap target stays ≥ 48 even if the glyph is 28.
- Optical center, not bounding-box center: Material `arrow_drop_up` sits high — nudge **+1.5 dy**; `arrow_drop_down` sits low — nudge **−1.5 dy**; square/stop: no nudge.
- Icon color matches the text it sits beside unless it is a status glyph (then use the status color + a shape).
- Gap from icon to text: **8**. Cap-height of the icon should match the cap-height of `titleMedium`, not the line box.

## Motion

| Token | Value |
|-------|--------|
| Fast | 200ms |
| Standard | 240ms |
| Emphasized | 280ms |
| Out | `Curves.easeOutCubic` |
| In/out | `Curves.easeInOutCubic` |

- Expand/collapse panels: 240ms, `easeInOutCubic`, `AnimatedSize` or `SizeTransition`.
- Swap of rate/result text: `AnimatedSwitcher` 240ms `easeOutCubic` + `FadeTransition` (no scale bounce).
- Pair/amount changes must not jump layout: reserve glyph width; wrap variable-height blocks in `AnimatedSize`.
- Forbidden: `Curves.linear`, `Duration.zero` pops, ≥ 600ms sluggishness, elastic/bouncy gimmicks, staggered sparkle on every key.

## Color-blind and contrast

Shape + words are the signal. Color is reinforcement.

- Up: `Icons.arrow_drop_up`, `AppMetrics.fxUp` (`0xFF2E7D32`), semantics **up from yesterday**
- Down: `Icons.arrow_drop_down`, `AppMetrics.fxDown` (`0xFFC62828`), semantics **down from yesterday**
- Flat: `Icons.square`, `AppMetrics.fxFlat` (`0xFFF9A825`), semantics **unchanged from yesterday**

Do not encode state with color alone. Body text stays on the theme `onSurface` (not gray-on-gray). Status green/red is for the glyph, not paragraphs.

## Copy on screen

Plain adult English that also sounds smart. Not kid-talk, not CAS jargon, not “Step 1 / Step 2”.

- Walkthrough title: **How this was worked out**
- Hint: **Plain language, with the arithmetic beside it.**
- Screen reader: paragraph, then equation. Join beats with ** Then **. Never announce “Step N”.
- Rate card: `1 {From} = {rate} {To}, as of {day month year}` using the ECB table date (honest if it is a weekend/holiday). Amount conversion is extra, not a prerequisite.

## Accessibility

- Semantics on every status glyph and every walkthrough beat.
- Tap targets ≥ 48 (accessible layout: 56 — `LayoutStyle.minTouchTarget`).
- `liveRegion` for results that change.
- Contrast: theme tokens; do not place amber-on-amber or gray-on-charcoal for primary text.
- Keep test `Key`s (`how-we-got-this`, convert keys). Styling must not rename them.

## Flutter

- Tokens, not scattered literals.
- `FittedBox` for overflow labels; `Align`/`Center` for icons.
- `AnimatedSwitcher` / `AnimatedSize` for panel and rate changes.
- Prefer `Theme.of(context).colorScheme` + `AppMetrics` over new hex in widgets (exception: the three FX status colors, already tokens).
- Do not dump raw `ExpansionTile` / default `Card` chrome onto a product surface. If you need expand/collapse, build a header + animated body that matches this skill.

## What not to do

- Material defaults left on screen (thick shadows, divider lines through tiles, “Step 1” headers, uneven 12/14/18 padding)
- Misaligned icons (glyph sitting on the baseline, different visual centers in one row)
- Gimmicky animation (bounce, rotate, color cycle)
- Kid-talk or “per hundred” lessons
- Redesigning unrelated screens to “match” in one pass
- Shipping a rate card that is empty until an amount is typed
- Color-only up/down

## Checklist (every visual PR)

- [ ] 8pt spacing; card 16 pad / 16 radius; hairline or tint, not both plus shadow
- [ ] Type roles and line-heights from the table
- [ ] Icons in fixed squares, optically nudged, 8px to text
- [ ] Motion 200–280ms, easeOutCubic / easeInOutCubic
- [ ] Status: shape + semantics + color
- [ ] Copy: adult, no Step N
- [ ] Keys and tests still find the widgets
- [ ] `flutter analyze` and the tests for the surface you touched
