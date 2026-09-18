import 'package:flutter/material.dart';

import '../core/calculator_controller.dart';
import '../design/typography.dart';
import '../expression/expression.dart';
import '../expression/parse/expression_parser.dart';
import '../theme/app_theme.dart';
import 'math/math_view.dart';

/// The readout, and the largest single thing on the calculator.
///
/// It used to be a tall empty area with a small numeral in the corner,
/// which wasted the most valuable space on the screen and told you
/// nothing about how you had got to the number. It is now a panel of its
/// own with three things in it, in the order the eye should meet them:
/// the running history above, the expression you are entering, and the
/// answer.
///
/// The expression is drawn through [MathView] where it parses — so a
/// square root is written under a radical and a fraction is stacked,
/// rather than shown back as the `sqrt(16)` you had to type. Where it
/// does not parse yet, because you are halfway through typing it, it
/// falls back to the raw text. That fallback is the normal case while
/// typing, not an error, so it is styled the same and says nothing.
class CalculatorDisplay extends StatelessWidget {
  const CalculatorDisplay({super.key, required this.controller});

  final CalculatorController controller;

  /// Height of the panel as a share of the screen. A quarter is what the
  /// mock allots it and what makes the result read as the subject of the
  /// screen rather than a status line.
  static const _minHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final history = controller.history;
    final error = controller.errorMessage;

    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      decoration: BoxDecoration(
        color: palette.display.background,
        borderRadius: BorderRadius.circular(Radii.card + 6),
      ),
      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _HistoryStrip(history: history, palette: palette),
          const SizedBox(height: Space.m),
          // Not Flexible: this panel is sized by its contents against a
          // minimum, so its height is unbounded and a flex child would
          // be asking to fill a space with no end to it.
          Align(
            alignment: Alignment.bottomRight,
            child: _Entry(
              // After an evaluation this is the working that produced
              // the answer; while typing it is what you have typed.
              text: controller.evaluatedExpression ?? controller.expression,
              palette: palette,
            ),
          ),
          const SizedBox(height: Space.s),
          Semantics(
            liveRegion: true,
            label: error ?? 'Result: ${controller.display}',
            child: ExcludeSemantics(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  // Scaled down rather than wrapped or ellipsised: a
                  // result with its tail cut off is worse than a small
                  // one, because it looks like a whole number.
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    error ?? controller.display,
                    key: const Key('calculator-display'),
                    textAlign: TextAlign.right,
                    style: AppType.displayResult.copyWith(
                      color: error != null
                          ? palette.errorSurface.foreground
                          : palette.display.foreground,
                      fontSize: error != null ? 22 : null,
                      fontWeight: error != null ? FontWeight.w500 : null,
                      letterSpacing: error != null ? -0.2 : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What is being entered, drawn as maths where it can be.
class _Entry extends StatelessWidget {
  const _Entry({required this.text, required this.palette});

  final String text;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    ExpressionNode? parsed;
    try {
      parsed = const ExpressionParser().parse(text);
    } on ParseError {
      // Half-typed is the normal state of this field, not a mistake.
      parsed = null;
    }

    if (parsed == null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: AppType.displayExpression
              .copyWith(color: palette.secondaryLabel),
        ),
      );
    }

    return MathView(
      expression: parsed,
      style: AppType.displayExpression.copyWith(color: palette.secondaryLabel),
    );
  }
}

/// The last few results, oldest furthest away, tappable to bring one back.
class _HistoryStrip extends StatelessWidget {
  const _HistoryStrip({required this.history, required this.palette});

  final List<HistoryEntry> history;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox(height: 20);

    return SizedBox(
      height: 20,
      child: ListView.separated(
        reverse: true,
        scrollDirection: Axis.horizontal,
        itemCount: history.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.m),
        itemBuilder: (context, index) {
          final entry = history[index];
          return Semantics(
            label: '${entry.expression} equals ${entry.result}',
            child: ExcludeSemantics(
              child: Center(
                child: Text(
                  '${entry.expression} = ${entry.result}',
                  style: AppType.footnote.copyWith(
                    color: palette.secondaryLabel,
                    fontFeatures: AppType.tabular,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
