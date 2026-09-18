import 'package:flutter/material.dart';

import '../design/typography.dart';
import '../theme/app_theme.dart';
import '../theme/layout_style.dart';

/// A single keypad key.
///
/// Three things here are load-bearing rather than decorative. The surface
/// and its text arrive together as one [SurfacePair], so they cannot be
/// mismatched the way they were when the amber key took white text. The
/// label's *size* is chosen from what it says — a digit is set at digit
/// size, `sin` at word size — because a three-letter word set as large as
/// a numeral crowds its key and makes the whole pad look cramped. And the
/// screen-reader label is always separate from the glyph, since "√" read
/// aloud is not a word.
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

  /// A label that is a word rather than a symbol drops a size. One
  /// character is a glyph however exotic it is; two or more is a word,
  /// except for the handful of two-character numerals and operators that
  /// still read as symbols.
  bool get _isWord => label.length > 2 || const {'1/x', 'x²', '2nd'}.contains(label);

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).extension<AppPalette>()!.forRole(role);
    final radius = BorderRadius.circular(
      style == LayoutStyle.accessible ? Radii.key : Radii.large,
    );

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _minTouchTarget,
            minHeight: _minTouchTarget,
          ),
          child: Material(
            color: surface.background,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    // A key label shrinks rather than wrapping or
                    // clipping: "sin⁻¹" at double text size still has to
                    // fit on the key it names.
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: (_isWord ? AppType.keyFunction : AppType.key)
                          .copyWith(
                        color: surface.foreground,
                        fontSize: (_isWord ? 16.0 : 21.0) * style.fontScale,
                        fontWeight: role == ButtonRole.equals
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
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
