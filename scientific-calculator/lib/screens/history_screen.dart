import 'package:flutter/material.dart';

import '../core/calculator_controller.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Dedicated history surface (Samsung Calculator pattern): compact list of
/// the last 30 equations, opened from a History button — not a bulky bar
/// on the main keypad.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final entries = controller.visibleHistory;
        final strings = L10n.stringsOf(context);
        final language = L10n.languageOf(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.history),
          ),
          body: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      strings.noEquations,
                      key: const Key('history-empty'),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  key: const Key('history-list'),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _HistoryRow(
                    entry: entries[index],
                    controller: controller,
                    language: language,
                    strings: strings,
                  ),
                ),
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.controller,
    required this.language,
    required this.strings,
  });

  final HistoryEntry entry;
  final CalculatorController controller;
  final AppLanguage language;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CalculatorPalette>()!;
    final expression = formatForLocale(entry.expression, language);
    final result = formatForLocale(entry.result, language);
    return Semantics(
      container: true,
      label: '$expression equals $result${entry.pinned ? ', ${strings.pin}' : ''}. Double tap to use this result.',
      child: Material(
        color: palette.functionButton,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: entry.pinned ? palette.selectedBorder : palette.onButton.withValues(alpha: 0.35),
            width: entry.pinned ? 3 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            controller.recall(entry);
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expression,
                  style: TextStyle(color: palette.onButton.withValues(alpha: 0.8), fontSize: 14),
                ),
                Text(
                  '= $result',
                  style: TextStyle(color: palette.onButton, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    _Action(
                      icon: entry.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                      label: entry.pinned ? strings.unpin : strings.pin,
                      onPressed: () => entry.pinned
                          ? controller.unpinHistory(entry.id)
                          : controller.pinHistory(entry.id),
                    ),
                    _Action(
                      icon: Icons.visibility_off_outlined,
                      label: strings.hide,
                      onPressed: () => controller.hideHistory(entry.id),
                    ),
                    _Action(
                      icon: Icons.delete_outline,
                      label: strings.delete,
                      onPressed: () => controller.deleteHistory(entry.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
