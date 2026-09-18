/// The handful of shapes every screen is assembled from.
///
/// The screens before this one were built from Material's defaults —
/// outlined dropdowns with floating labels, bordered chips, a segmented
/// button straight out of the box. Each is fine on its own and together
/// they read as an un-customised toolkit rather than a product, because
/// the toolkit's job is to be recognisable and a product's job is not.
///
/// So: one card, one row, one badge, one search field, one button, one
/// tab strip. Everything in the app is made of these, which is what makes
/// a screen you have not seen before still feel like the same app.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tokens.dart';
import 'typography.dart';

/// A rounded panel that sits above the page.
///
/// The shadow is deliberately almost invisible — a card is separated from
/// the page by its shape and its lightness, and a drop shadow strong
/// enough to notice is the fastest way to make an interface look a decade
/// old. In dark appearances there is no shadow at all, because a shadow
/// on a near-black page is a smudge.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.m),
    this.onTap,
    this.color,
    this.radius = Radii.card,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shape = BorderRadius.circular(radius);

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? palette.elevatedSurface,
        borderRadius: shape,
        boxShadow: palette.appearance.isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0C1220).withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Material(
              color: Colors.transparent,
              borderRadius: shape,
              child: InkWell(
                onTap: onTap,
                borderRadius: shape,
                child: Padding(padding: padding, child: child),
              ),
            ),
    );

    return surface;
  }
}

/// The tinted rounded square that sits in front of a category name.
///
/// Its colour comes from the palette's tint list rather than from the
/// caller, so a new category cannot introduce a colour the appearance has
/// not been checked for.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.tintIndex,
    this.size = 40,
  });

  final IconData icon;

  /// Which tint to use. Wrapped into range, so a list longer than the
  /// tint set cycles instead of crashing.
  final int tintIndex;

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final tints = palette.categoryTints;
    final tint = tints[tintIndex % tints.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: tint.foreground),
    );
  }
}

/// A browsable row: badge, name, one line about it, chevron.
///
/// This is the single most repeated shape in the design — the whole
/// Formulas browser is a stack of these, at every depth. The subtitle is
/// a screen-reader *hint* rather than part of the label, so the name is
/// announced first and the explanation after.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.title,
    required this.icon,
    required this.tintIndex,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final int tintIndex;
  final VoidCallback onTap;

  /// Replaces the chevron. A row that toggles rather than pushes uses
  /// this to show which way it is pointing.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: ExcludeSemantics(
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.m,
            vertical: 14,
          ),
          child: Row(
            children: [
              IconBadge(icon: icon, tintIndex: tintIndex),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      // No maxLines anywhere in this file: a label that
                      // has grown with the user's text size wraps rather
                      // than being cut off.
                      style: AppType.headline.copyWith(color: palette.label),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppType.subheadline
                            .copyWith(color: palette.secondaryLabel),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Space.s),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.secondaryLabel,
                    size: 22,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pill search field at the top of every browsing screen.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppType.body.copyWith(color: palette.label),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: palette.secondaryLabel,
          size: 20,
        ),
        filled: true,
        fillColor: palette.groupedBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
          borderSide: BorderSide(color: palette.accent, width: 2),
        ),
      ),
    );
  }
}

/// A small caps-ish label over a group of cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(left: Space.xs, bottom: Space.s),
        child: Text(
          label,
          style: AppType.sectionLabel.copyWith(color: palette.secondaryLabel),
        ),
      ),
    );
  }
}

/// The underlined tab strip used to switch between two views of the same
/// thing — Steps and Result, Exact and Decimal.
///
/// Underlined rather than filled because these are two readings of one
/// answer, not two destinations; a filled pill would suggest you had gone
/// somewhere.
class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selected,
              child: InkWell(
                onTap: () => onSelected(i),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: TouchTarget.minimum,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: Space.s),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == selected
                            ? palette.accent
                            : palette.separator,
                        width: i == selected ? 2.5 : 1,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: AppType.callout.copyWith(
                      color: i == selected
                          ? palette.accentOnSurface
                          : palette.secondaryLabel,
                      fontWeight:
                          i == selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A row of pills where exactly one is chosen — a unit category, a
/// language, an input method.
class PillGroup<T> extends StatelessWidget {
  const PillGroup({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.iconOf,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final IconData? Function(T)? iconOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Wrap(
      spacing: Space.s,
      runSpacing: Space.s,
      children: [
        for (final value in values)
          _Pill(
            label: labelOf(value),
            icon: iconOf?.call(value),
            isSelected: value == selected,
            palette: palette,
            onTap: () => onSelected(value),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        isSelected ? palette.accent : palette.elevatedSurface;
    final foreground = isSelected ? palette.onAccent : palette.label;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: background,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.m,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppType.subheadline.copyWith(
                      color: foreground,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A screen that scrolls, with the page margins and reading width the
/// rest of the app uses.
///
/// Centred past [Space.readableWidth] rather than stretched: a row of
/// cards spread across a tablet stops being a list and becomes a wall.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.controller});

  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = width >= 600 ? Space.tabletMargin : Space.phoneMargin;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(margin, Space.s, margin, Space.xl),
          children: children,
        ),
      ),
    );
  }
}
