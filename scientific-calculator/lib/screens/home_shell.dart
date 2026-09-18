import 'package:flutter/material.dart';

import '../core/calculator_controller.dart';
import '../design/typography.dart';
import '../services/settings_controller.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';
import 'formulas_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// The app's four places, and the bar that switches between them.
///
/// This replaces two earlier attempts. The first was a scrolling bar of
/// eight icon tabs, which broke the guideline that caps a tab bar at five
/// and clipped its own last label. The second was a wall of tiles on a
/// home screen, which fixed the clipping and lost the sense that the
/// calculator *is* the app — you had to go into it, and come back out of
/// it, like any other tool.
///
/// Four destinations, each a noun: the calculator itself, everything else
/// the app can do, what you have already worked out, and your settings.
/// The tools that used to be tabs now live inside Formulas, grouped,
/// which is where a growing list of them can keep growing.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.settings});

  final SettingsController settings;

  static const title = 'Scientific Calculator';

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// Held here rather than inside the calculator screen so that History
  /// is showing the same history — two controllers would mean a history
  /// tab that is always empty, which is the kind of bug that survives to
  /// release because each half works.
  final _calculator = CalculatorController();

  int _tab = 0;

  @override
  void dispose() {
    _calculator.dispose();
    super.dispose();
  }

  static const _destinations = [
    (icon: Icons.calculate_outlined, active: Icons.calculate, label: 'Calculator'),
    (icon: Icons.apps_outlined, active: Icons.apps, label: 'Formulas'),
    (icon: Icons.history_rounded, active: Icons.history_rounded, label: 'History'),
    (icon: Icons.settings_outlined, active: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            CalculatorScreen(
              settings: widget.settings,
              controller: _calculator,
            ),
            FormulasScreen(settings: widget.settings),
            HistoryScreen(
              controller: _calculator,
              onReuse: () => setState(() => _tab = 0),
            ),
            SettingsScreen(settings: widget.settings, embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.separator)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: [
            for (var i = 0; i < _destinations.length; i++)
              NavigationDestination(
                icon: Icon(_destinations[i].icon),
                selectedIcon: Icon(_destinations[i].active),
                label: _destinations[i].label,
              ),
          ],
        ),
      ),
    );
  }
}

/// The large title at the top of a tab, as the mock sets it.
class TabTitle extends StatelessWidget {
  const TabTitle(this.title, {super.key, this.blurb});

  final String title;
  final String? blurb;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.s, bottom: Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppType.largeTitle.copyWith(color: palette.label)),
          if (blurb != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              blurb!,
              style:
                  AppType.subheadline.copyWith(color: palette.secondaryLabel),
            ),
          ],
        ],
      ),
    );
  }
}
