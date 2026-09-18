import 'package:flutter/material.dart';

import '../core/calculator_controller.dart';
import '../theme/app_theme.dart';

/// The expression/result readout plus a scrollable history strip above it —
/// tapping a history line re-enters that result for further calculation.
class CalculatorDisplay extends StatelessWidget {
  const CalculatorDisplay({super.key, required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final history = controller.history;

    return Container(
      color: palette.display.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 64,
            child: history.isEmpty
                ? null
                : ListView.builder(
                    reverse: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Center(
                          child: Semantics(
                            label: '${entry.expression} equals ${entry.result}',
                            child: Text(
                              '${entry.expression} = ${entry.result}',
                              style: TextStyle(
                                color: palette.secondaryLabel,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              liveRegion: true,
              label: controller.errorMessage ?? 'Result: ${controller.display}',
              child: Text(
                controller.errorMessage ?? controller.display,
                key: const Key('calculator-display'),
                style: TextStyle(
                  color: controller.errorMessage != null
                      ? Colors.redAccent
                      : palette.display.foreground,
                  fontSize: 44,
                  fontWeight: FontWeight.w300,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
