import 'package:flutter/material.dart';

import '../core/calculator_mode.dart';
import '../l10n/l10n.dart';
import '../services/settings_controller.dart';
import 'calculator_screen.dart';
import 'convert_screen.dart';
import 'finance_screen.dart';
import 'fractions_screen.dart';
import 'geometry_screen.dart';
import 'graph_screen.dart';
import 'matrix_screen.dart';
import 'percentage_screen.dart';
import 'settings_screen.dart';
import 'solve_screen.dart';
import 'stats_screen.dart';
import 'surface3d_screen.dart';

/// Hosts the chosen calculator. Other tools are reached by going back to
/// the chooser — a screen-reader user is not dropped into a tab bar
/// with unlabeled icons.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.settings,
    required this.mode,
    required this.onChangeCalculator,
  });

  final SettingsController settings;
  final CalculatorMode mode;
  final VoidCallback onChangeCalculator;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.stringsOf(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('switch-calculator'),
          icon: const Icon(Icons.apps),
          tooltip: strings.switchCalculator,
          onPressed: onChangeCalculator,
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(strings.modeLabel(mode.name)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: strings.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsScreen(settings: settings)),
            ),
          ),
        ],
      ),
      body: _screenFor(mode),
    );
  }

  Widget _screenFor(CalculatorMode mode) {
    return switch (mode) {
      CalculatorMode.calculator => CalculatorScreen(settings: settings),
      CalculatorMode.convert => const ConvertScreen(),
      CalculatorMode.percentage => const PercentageScreen(),
      CalculatorMode.fractions => const FractionsScreen(),
      CalculatorMode.graph => const GraphScreen(),
      CalculatorMode.surface3d => const Surface3dScreen(),
      CalculatorMode.geometry => const GeometryScreen(),
      CalculatorMode.matrix => const MatrixScreen(),
      CalculatorMode.statistics => const StatsScreen(),
      CalculatorMode.finance => const FinanceScreen(),
      CalculatorMode.solve => const SolveScreen(),
    };
  }
}
