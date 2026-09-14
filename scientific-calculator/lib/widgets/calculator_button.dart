import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/layout_style.dart';
import '../theme/type_voice.dart';

/// A single keypad key. Enforces a minimum touch target (48dp classic,
/// 56dp accessible) and always carries a screen-reader label distinct
/// from its (sometimes symbolic) visible glyph.
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
  });

  final String label;
  final ButtonRole role;
  final LayoutStyle style;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CalculatorPalette>()!;
    final background = palette.forRole(role);
    final isAccent = role == ButtonRole.equals || role == ButtonRole.clear;
    final min = style.minTouchTarget;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: min, minHeight: min),
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(style == LayoutStyle.accessible ? 14 : 10),
            side: BorderSide(
              color: selected ? palette.selectedBorder : Colors.white24,
              width: selected ? 3 : 1,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(style == LayoutStyle.accessible ? 14 : 10),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        Icon(Icons.check, size: 14, color: palette.labelForRole(role)),
                        const SizedBox(width: 4),
                      ],
                      if (icon != null)
                        Icon(icon, size: 22 * style.fontScale, color: palette.labelForRole(role)),
                      if (icon != null && label.isNotEmpty) const SizedBox(width: 4),
                      if (label.isNotEmpty)
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontFamily: AppTypefaces.of(context).uiFamily,
                            color: palette.labelForRole(role),
                            fontSize: 18 * style.fontScale,
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
