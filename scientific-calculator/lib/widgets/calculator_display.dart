import 'package:flutter/material.dart';

import '../core/calculator_controller.dart';
import '../l10n/app_language.dart';
import '../l10n/l10n.dart';
import '../screens/history_screen.dart';
import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';
import '../theme/type_voice.dart';
import 'steps_panel.dart';

/// Expression editor (with a visible caret), live-region result, a compact
/// last-equation line, and a History button that opens the full list.
class CalculatorDisplay extends StatelessWidget {
  const CalculatorDisplay({super.key, required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CalculatorPalette>()!;
    final error = controller.errorMessage;
    final language = L10n.languageOf(context);
    final strings = L10n.stringsOf(context);
    final shownExpression = controller.expression.isEmpty
        ? '0'
        : formatForLocale(controller.expressionWithCursor, language);
    final shownResult = formatForLocale(controller.display, language);
    final last = controller.visibleHistory.isEmpty ? null : controller.visibleHistory.first;
    final steps = controller.lastExplanation;

    return Container(
      color: palette.displayBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Wrap(
                spacing: 4,
                children: [
                  Semantics(
                    button: true,
                    label: strings.history,
                    child: TextButton.icon(
                      key: const Key('history-button'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HistoryScreen(controller: controller),
                        ),
                      ),
                      icon: const Icon(Icons.history),
                      label: Text(strings.history),
                    ),
                  ),
                  if (steps != null)
                    Semantics(
                      button: true,
                      label: strings.howWeGotThis,
                      child: TextButton.icon(
                        key: const Key('how-we-got-this'),
                        onPressed: () => showStepsSheet(context, steps),
                        icon: const SizedBox(
                          width: AppMetrics.iconSize,
                          height: AppMetrics.iconSize,
                          child: Icon(Icons.menu_book_outlined, size: AppMetrics.iconSize),
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(strings.howWeGotThis),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (last != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(
                '${formatForLocale(last.expression, language)} = ${formatForLocale(last.result, language)}',
                key: const Key('history-compact'),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.onButton.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Semantics(
              label: controller.cursorAnnouncement,
              child: Text(
                controller.expression.isEmpty ? '0' : shownExpression,
                key: const Key('calculator-expression'),
                textAlign: TextAlign.right,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypefaces.of(context).math(
                  TextStyle(
                    color: palette.onButton.withValues(alpha: 0.85),
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                liveRegion: true,
                label: error != null ? '${strings.error}: $error' : '${strings.result}: $shownResult',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (error != null) ...[
                      Icon(Icons.warning_amber_rounded, color: palette.errorForeground),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        error != null ? '${strings.error}: $error' : shownResult,
                        key: const Key('calculator-display'),
                        style: AppTypefaces.of(context).math(
                          TextStyle(
                            color: error != null ? palette.errorForeground : palette.onButton,
                            fontSize: 40,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
