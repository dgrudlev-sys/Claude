import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/layout_style.dart';

/// A single keypad key. Enforces a minimum touch target (Android's 48dp
/// accessibility guideline) regardless of layout density, and always
/// carries a screen-reader label distinct from its (sometimes symbolic)
/// visible glyph.
class CalculatorButton extends StatelessWidget {
  const CalculatorButton({
    super.key,
    required this.label,
    required this.role,
    required this.style,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final ButtonRole role;
  final LayoutStyle style;
  final VoidCallback onPressed;
  final String? semanticLabel;

  static const double _minTouchTarget = 48.0;

  @override
  Widget build(BuildContext context) {
    // The surface and its text arrive together, so they cannot be
    // mismatched the way they were when the amber key took white text.
    final surface = Theme.of(context).extension<AppPalette>()!.forRole(role);
    final isAccent = role == ButtonRole.equals;

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: _minTouchTarget,
          minHeight: _minTouchTarget,
        ),
        child: Material(
          color: surface.background,
          borderRadius: BorderRadius.circular(style == LayoutStyle.accessible ? 14 : 10),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(style == LayoutStyle.accessible ? 14 : 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: surface.foreground,
                  fontSize: 18 * style.fontScale,
                  fontWeight: isAccent ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
