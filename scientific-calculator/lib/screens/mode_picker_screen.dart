import 'package:flutter/material.dart';

import '../core/calculator_mode.dart';
import '../l10n/l10n.dart';
import '../services/settings_controller.dart';
import '../theme/app_metrics.dart';
import '../widgets/chooser_tile.dart';
import 'language_picker_screen.dart';
import 'settings_screen.dart';

/// Apps list: Calculator through Solve up front; Statistics, Matrix,
/// Geometry, and 3D under More. Finance is not listed here.
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
    final moreOpen = settings.chooserMoreExpanded;
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(strings.chooseCalculator),
        ),
        actions: [
          IconButton(
            icon: AlignedGlyph(
              icon: Icons.translate,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: strings.language,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LanguagePickerScreen(settings: settings),
              ),
            ),
          ),
          IconButton(
            icon: AlignedGlyph(
              icon: Icons.settings_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: strings.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsScreen(settings: settings)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppMetrics.space3,
                12,
                AppMetrics.space3,
                AppMetrics.space2,
              ),
              child: Text(
                strings.chooseCalculatorHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: AppMetrics.bodyHeight,
                    ),
              ),
            ),
            ...ChooserTile.separated([
              for (final mode in CalculatorMode.primaryChooserOrder) _modeTile(mode, last),
            ]),
            const ChooserDivider(),
            _MoreHeader(
              expanded: moreOpen,
              onToggle: () => settings.setChooserMoreExpanded(!moreOpen),
            ),
            AnimatedSize(
              duration: AppMotion.standard,
              curve: AppMotion.inOut,
              alignment: Alignment.topCenter,
              child: moreOpen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ChooserDivider(),
                        ...ChooserTile.separated([
                          for (final mode in CalculatorMode.moreChooserOrder) _modeTile(mode, last),
                        ]),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: AppMetrics.space4),
          ],
        ),
      ),
    );
  }

  Widget _modeTile(CalculatorMode mode, CalculatorMode? last) {
    return _ModeTile(
      mode: mode,
      isLastUsed: last == mode,
      onChosen: () {
        settings.setLastMode(mode);
        onChosen(mode);
      },
    );
  }
}

class _MoreHeader extends StatelessWidget {
  const _MoreHeader({
    required this.expanded,
    required this.onToggle,
  });

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.stringsOf(context);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final expandIcon = expanded ? Icons.expand_less : Icons.expand_more;
    final nudge = expanded ? 1.5 : -1.5;
    return Semantics(
      button: true,
      header: true,
      expanded: expanded,
      label: strings.groupLabel('more'),
      child: InkWell(
        key: const Key('chooser-more'),
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppMetrics.space3,
              12,
              AppMetrics.space3,
              AppMetrics.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.groupLabel('more'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.20,
                        letterSpacing: -0.3,
                        color: onSurface,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: AppMetrics.iconSize,
                  height: AppMetrics.iconSize,
                  child: Transform.translate(
                    offset: Offset(0, nudge),
                    child: Icon(expandIcon, size: AppMetrics.iconSize, color: onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
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
    return ChooserTile(
      key: Key('mode-${mode.name}'),
      icon: mode.icon,
      title: strings.modeLabel(mode.name),
      subtitle: strings.modeDescription(mode.name),
      caption: isLastUsed ? strings.lastUsed : null,
      selected: isLastUsed,
      onTap: onChosen,
    );
  }
}
