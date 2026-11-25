import 'package:flutter/material.dart';

import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';
import '../theme/layout_style.dart';
import '../theme/type_voice.dart';

/// A single keypad key. Sized by its parent so the pad can keep square
/// keys; always carries a screen-reader label distinct from its glyph.
class CalculatorButton extends StatelessWidget {
  const CalculatorButton({
    super.key,
    required this.label,
    required this.role,
    required this.style,
    required this.onPressed,
    this.semanticLabel,
    this.selected = false,
    this.icon,
    this.sizeBoost = 1,
  });

  final String label;
  final ButtonRole role;
  final LayoutStyle style;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final bool selected;
  final IconData? icon;
  /// Extra type scale for larger keys.
  final double sizeBoost;

  static Offset _opticalNudge(IconData? icon) {
    if (icon == Icons.arrow_drop_up) return const Offset(0, 1.5);
    if (icon == Icons.arrow_drop_down) return const Offset(0, -1.5);
    return Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CalculatorPalette>()!;
    final background = palette.forRole(role);
    final isAccent = role == ButtonRole.equals || role == ButtonRole.clear;
    const radius = AppMetrics.radiusKey;
    final ink = palette.labelForRole(role);
    final scale = style.fontScale * sizeBoost;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: SizedBox.expand(
        child: Material(
          color: background,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: selected
                ? BorderSide(color: palette.selectedBorder, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(radius),
            splashColor: ink.withValues(alpha: 0.12),
            highlightColor: ink.withValues(alpha: 0.06),
            splashFactory: InkRipple.splashFactory,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space1),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        SizedBox(
                          width: AppMetrics.iconSize,
                          height: AppMetrics.iconSize,
                          child: Icon(Icons.check, size: AppMetrics.iconSize, color: ink),
                        ),
                        const SizedBox(width: AppMetrics.space2),
                      ],
                      if (icon != null)
                        SizedBox(
                          width: AppMetrics.iconSize,
                          height: AppMetrics.iconSize,
                          child: Transform.translate(
                            offset: _opticalNudge(icon),
                            child: Icon(icon, size: AppMetrics.iconSize, color: ink),
                          ),
                        ),
                      if (icon != null && label.isNotEmpty)
                        const SizedBox(width: AppMetrics.space2),
                      if (label.isNotEmpty)
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontFamily: AppTypefaces.of(context).uiFamily,
                            color: ink,
                            fontSize: 18 * scale,
                            fontWeight: isAccent || selected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
