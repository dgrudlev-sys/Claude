import 'package:flutter/material.dart';

import '../core/calculator_controller.dart';
import '../design/components.dart';
import '../design/typography.dart';
import '../expression/expression.dart';
import '../expression/parse/expression_parser.dart';
import '../theme/app_theme.dart';
import '../widgets/math/math_view.dart';
import 'home_shell.dart';

/// Everything worked out this session, newest first.
///
/// The calculator already kept a history and showed it as a strip of
/// grey text above the display, which is enough to glance at and not
/// enough to use. Here each line is drawn as maths, and tapping one puts
/// its result back into the calculator to carry on with — which is the
/// only thing anyone ever wants from a history.
///
/// It is honest about its own limit: this history lives in memory and
/// goes when the app does. Saying so in the empty state is better than
/// letting someone find out by losing something.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.controller,
    required this.onReuse,
  });

  final CalculatorController controller;

  /// Called after a line is sent back to the calculator, so the shell can
  /// switch to the tab where it landed. Reusing a result and staying on
  /// a list that has not changed would look like nothing happened.
  final VoidCallback onReuse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final entries = controller.history;

        return PageBody(
          children: [
            const TabTitle(
              'History',
              blurb: 'Everything you have worked out, ready to pick up again.',
            ),
            if (entries.isEmpty)
              const _Empty()
            else
              for (var i = 0; i < entries.length; i++) ...[
                _HistoryCard(
                  entry: entries[i],
                  onTap: () {
                    controller.clear();
                    controller.input(entries[i].result);
                    onReuse();
                  },
                ),
                const SizedBox(height: Space.s),
              ],
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.m,
        vertical: Space.xl,
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 34, color: palette.secondaryLabel),
          const SizedBox(height: Space.m),
          Text(
            'Nothing yet',
            style: AppType.headline.copyWith(color: palette.label),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Work something out and it will appear here. This history is '
            'kept while the app is open and is not saved to your device.',
            style: AppType.subheadline.copyWith(color: palette.secondaryLabel),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    ExpressionNode? parsed;
    try {
      parsed = const ExpressionParser().parse(entry.expression);
    } on ParseError {
      parsed = null;
    }

    return Semantics(
      button: true,
      label: '${entry.expression} equals ${entry.result}',
      hint: 'Use this result',
      child: ExcludeSemantics(
        child: AppCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 30,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: parsed == null
                      ? Text(
                          entry.expression,
                          style: AppType.callout
                              .copyWith(color: palette.secondaryLabel),
                        )
                      : MathView(
                          expression: parsed,
                          style: AppType.callout
                              .copyWith(color: palette.secondaryLabel),
                        ),
                ),
              ),
              const SizedBox(height: Space.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entry.result,
                        style: AppType.title2.copyWith(
                          color: palette.label,
                          fontFeatures: AppType.tabular,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.north_west_rounded,
                    size: 18,
                    color: palette.accentOnSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
