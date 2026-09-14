import 'package:flutter/material.dart';

import '../core/calculator_mode.dart';
import '../l10n/l10n.dart';
import '../services/settings_controller.dart';
import 'language_picker_screen.dart';
import 'settings_screen.dart';

/// First screen: pick which calculator to use. Large targets, spoken
/// labels that include a short description — a screen-reader user should
/// never have to guess what a tab icon means.
class ModePickerScreen extends StatelessWidget {
  const ModePickerScreen({
    super.key,
    required this.settings,
    required this.onChosen,
  });

  final SettingsController settings;
  final ValueChanged<CalculatorMode> onChosen;

  @override
  Widget build(BuildContext context) {
    final last = settings.lastMode;
    final strings = L10n.stringsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(strings.chooseCalculator),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: strings.language,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LanguagePickerScreen(settings: settings),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: strings.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsScreen(settings: settings)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              strings.chooseCalculatorHint,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            for (final mode in CalculatorMode.values.where((m) => m.isEveryday))
              _modeCard(mode, last),
            for (final groupId in CalculatorMode.chooserGroupOrder) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Semantics(
                  header: true,
                  child: Text(
                    strings.groupLabel(groupId),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              for (final mode in CalculatorMode.values.where((m) => m.chooserGroup == groupId))
                _modeCard(mode, last),
            ],
          ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard(CalculatorMode mode, CalculatorMode? last) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _ModeCard(
        mode: mode,
        isLastUsed: last == mode,
        onChosen: () {
          settings.setLastMode(mode);
          onChosen(mode);
        },
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.isLastUsed,
    required this.onChosen,
  });

  final CalculatorMode mode;
  final bool isLastUsed;
  final VoidCallback onChosen;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.stringsOf(context);
    final label = strings.modeLabel(mode.name);
    final description = strings.modeDescription(mode.name);
    return Semantics(
      button: true,
      label: '$label. $description${isLastUsed ? '. ${strings.lastUsed}.' : ''}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isLastUsed
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: isLastUsed ? 3 : 1,
            ),
          ),
          child: InkWell(
            key: Key('mode-${mode.name}'),
            onTap: onChosen,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(mode.icon, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (isLastUsed)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              strings.lastUsed,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
