import 'package:flutter/material.dart';

import '../services/settings_controller.dart';
import 'calculator_screen.dart';
import 'finance_screen.dart';
import 'graph_screen.dart';
import 'matrix_screen.dart';
import 'settings_screen.dart';
import 'solve_screen.dart';
import 'stats_screen.dart';
import 'surface3d_screen.dart';

const _tabs = [
  (icon: Icons.calculate_outlined, label: 'Calculator'),
  (icon: Icons.show_chart, label: 'Graph'),
  (icon: Icons.view_in_ar_outlined, label: '3D'),
  (icon: Icons.grid_on, label: 'Matrix'),
  (icon: Icons.bar_chart, label: 'Statistics'),
  (icon: Icons.attach_money, label: 'Finance'),
  (icon: Icons.functions, label: 'Solve'),
];

/// Ties every mode (Calculator/Graph/3D/Matrix/Statistics/Finance/Solve)
/// together behind one scrollable tab bar and a single shared settings
/// entry point, mirroring how a physical calculator's APPS menu switches
/// between its built-in tools without leaving "the calculator."
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scientific Calculator'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsScreen(settings: settings)),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final tab in _tabs) Tab(icon: Icon(tab.icon), text: tab.label),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CalculatorScreen(settings: settings),
            const GraphScreen(),
            const Surface3dScreen(),
            const MatrixScreen(),
            const StatsScreen(),
            const FinanceScreen(),
            const SolveScreen(),
          ],
        ),
      ),
    );
  }
}
