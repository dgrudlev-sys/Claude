import 'package:flutter/material.dart';

import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';

/// Settings-style chooser row: full-bleed, 24×24 leading glyph, 8px gap,
/// icon vertically centered on the title+subtitle block. No chevron.
///
/// Selected state colours the leading icon (and the check) with the look's
/// ColorStory **highlight** — [CalculatorPalette.equalsButton], which is
/// `tokens.accent` (gold on Panther, laterite on Africa, and so on).
class ChooserTile extends StatelessWidget {
  const ChooserTile({
    super.key,
    required this.title,
    this.subtitle,
    this.caption,
    this.icon,
    this.leading,
    this.selected = false,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? caption;
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  /// ColorStory highlight (`accent` / equals key). Gold on Panther.
  static Color highlightOf(BuildContext context) {
    return Theme.of(context).extension<CalculatorPalette>()!.equalsButton;
  }

  static Color iconColor(BuildContext context, {required bool selected}) {
    if (selected) return highlightOf(context);
    return Theme.of(context).colorScheme.onSurface;
  }

  static List<Widget> separated(List<Widget> tiles) {
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) out.add(const ChooserDivider());
      out.add(tiles[i]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highlight = highlightOf(context);
    final glyphColor = iconColor(context, selected: selected);
    final semantic = [
      title,
      if (subtitle != null) subtitle,
      if (caption != null) caption,
      if (selected) 'Selected',
    ].join('. ');

    return Semantics(
      button: true,
      selected: selected,
      label: semantic,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppMetrics.space3,
                vertical: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppMetrics.space2),
                  ] else if (icon != null) ...[
                    AlignedGlyph(icon: icon!, color: glyphColor),
                    const SizedBox(width: AppMetrics.space2),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            height: AppMetrics.titleHeight,
                            letterSpacing: AppMetrics.titleTracking,
                            color: scheme.onSurface,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: AppMetrics.bodyHeight,
                              color: scheme.onSurface,
                            ),
                          ),
                        if (caption != null)
                          Text(
                            caption!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: AppMetrics.captionHeight,
                              letterSpacing: AppMetrics.captionTracking,
                              color: scheme.onSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: AppMetrics.space2),
                    AlignedGlyph(icon: Icons.check, color: highlight),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChooserDivider extends StatelessWidget {
  const ChooserDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppMetrics.hairline,
      thickness: AppMetrics.hairline,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
    );
  }
}

/// 24×24 square, glyph optically centered. Use in lists and AppBars.
class AlignedGlyph extends StatelessWidget {
  const AlignedGlyph({
    super.key,
    required this.icon,
    this.color,
    this.size = AppMetrics.iconSize,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Align(
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
