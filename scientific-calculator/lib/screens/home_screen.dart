import 'package:flutter/material.dart';

import '../design/typography.dart';
import '../navigation/calculator_mode.dart';
import '../services/settings_controller.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';
import 'convert_screen.dart';
import 'finance_screen.dart';
import 'geometry_screen.dart';
import 'graph_screen.dart';
import 'input_methods_screen.dart';
import 'matrix_screen.dart';
import 'settings_screen.dart';
import 'solve_screen.dart';
import 'stats_screen.dart';
import 'surface3d_screen.dart';

/// The way in: one labelled button per tool.
///
/// This replaces a scrolling bar of eight icon tabs. Every tool now says
/// its own name and what it is for, nothing is clipped at any text size,
/// and opening one is an ordinary push with a back button that names
/// where it came from.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.settings});

  final SettingsController settings;

  static const title = 'Scientific Calculator';

  @override
  Widget build(BuildContext context) {
    final preferences = AccessibilityPreferences.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(settings: settings),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = _columnsFor(constraints.maxWidth, preferences);
            final margin = constraints.maxWidth >= 600
                ? Space.tabletMargin
                : Space.phoneMargin;

            return Center(
              child: ConstrainedBox(
                // Beyond a readable width a grid of tiles stops being a
                // list and becomes a wall, so it is centred rather than
                // stretched across a tablet.
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: EdgeInsets.all(margin),
                  children: [
                    _ModeButton(
                      mode: CalculatorMode.primary,
                      prominent: true,
                      onOpen: () => _open(context, CalculatorMode.primary),
                    ),
                    const SizedBox(height: Space.m),
                    _SectionLabel(label: 'Other tools'),
                    const SizedBox(height: Space.s),
                    for (final row in _rows(CalculatorMode.secondary, columns))
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.s),
                        // Tiles in a row match the tallest one, so a
                        // longer sentence does not leave its neighbour
                        // short. IntrinsicHeight is what makes that legal
                        // inside a list: stretching against an unbounded
                        // height asks each tile to be infinitely tall.
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < row.length; i++) ...[
                                if (i > 0) const SizedBox(width: Space.s),
                                Expanded(
                                  child: _ModeButton(
                                    mode: row[i],
                                    onOpen: () => _open(context, row[i]),
                                  ),
                                ),
                              ],
                              // Keeps the last row aligned with the ones
                              // above it rather than stretching a lone
                              // tile across the full width.
                              for (var i = row.length; i < columns; i++) ...[
                                const SizedBox(width: Space.s),
                                const Expanded(child: SizedBox()),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// One column on a narrow phone or at large text sizes, two on an
  /// ordinary phone, three on a tablet. Text that has grown needs the
  /// width more than the grid does.
  static int _columnsFor(double width, AccessibilityPreferences preferences) {
    if (preferences.needsVerticalLayout) return 1;
    if (width < 380) return 1;
    if (width < 600) return 2;
    return 3;
  }

  static List<List<CalculatorMode>> _rows(
    List<CalculatorMode> modes,
    int columns,
  ) {
    final rows = <List<CalculatorMode>>[];
    for (var i = 0; i < modes.length; i += columns) {
      rows.add(modes.sublist(i, (i + columns).clamp(0, modes.length)));
    }
    return rows;
  }

  void _open(BuildContext context, CalculatorMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModeScaffold(mode: mode, settings: settings),
      ),
    );
  }
}

/// A tool, opened from the home screen.
///
/// The back button carries the title of the screen it returns to, which
/// is what the Human Interface Guidelines ask for and what tells a
/// screen-reader user where they are about to end up.
class ModeScaffold extends StatelessWidget {
  const ModeScaffold({
    super.key,
    required this.mode,
    required this.settings,
    this.initialInputMethod = InputMethod.voice,
  });

  final CalculatorMode mode;
  final SettingsController settings;

  /// Only meaningful for [CalculatorMode.input]: which panel to open on.
  final InputMethod initialInputMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mode.title),
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        // The other ways in, where they are actually needed. Voice and
        // camera were reachable only from the home screen, which is the
        // one place you are not when you want to dictate a sum — so the
        // calculator carries them itself.
        actions: mode == CalculatorMode.calculator
            ? [
                for (final method in InputMethod.values)
                  IconButton(
                    icon: Icon(method.icon),
                    tooltip: method.label,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ModeScaffold(
                          mode: CalculatorMode.input,
                          settings: settings,
                          initialInputMethod: method,
                        ),
                      ),
                    ),
                  ),
              ]
            : null,
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() => switch (mode) {
        CalculatorMode.calculator => CalculatorScreen(settings: settings),
        CalculatorMode.graph => const GraphScreen(),
        CalculatorMode.surface3d => const Surface3dScreen(),
        CalculatorMode.geometry => const GeometryScreen(),
        CalculatorMode.matrix => const MatrixScreen(),
        CalculatorMode.statistics => const StatsScreen(),
        CalculatorMode.finance => const FinanceScreen(),
        CalculatorMode.solve => const SolveScreen(),
        CalculatorMode.convert => const ConvertScreen(),
        CalculatorMode.input => InputMethodsScreen(initial: initialInputMethod),
      };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      header: true,
      child: Text(
        label,
        style: AppType.footnote.copyWith(
          color: palette.secondaryLabel,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.onOpen,
    this.prominent = false,
  });

  final CalculatorMode mode;
  final VoidCallback onOpen;

  /// The one tool people came for gets more weight than the rest.
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final preferences = AccessibilityPreferences.of(context);

    final background = prominent ? palette.accent : palette.elevatedSurface;
    final foreground = prominent ? palette.onAccent : palette.label;
    final supporting = prominent
        ? palette.onAccent.withValues(alpha: 0.85)
        : palette.secondaryLabel;

    return Semantics(
      button: true,
      label: mode.title,
      // The sentence is a hint rather than part of the label, so a screen
      // reader announces the name first and the explanation after.
      hint: mode.summary,
      child: ExcludeSemantics(
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(Radii.large),
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(Radii.large),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: TouchTarget.comfortable,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Space.m),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(mode.icon, color: foreground, size: prominent ? 32 : 26),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mode.title,
                            style: (prominent ? AppType.title3 : AppType.headline)
                                .copyWith(
                              color: foreground,
                              fontWeight: preferences.resolveWeight(
                                prominent ? FontWeight.w600 : FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: Space.xs),
                          Text(
                            mode.summary,
                            // No maxLines: a label that grows has to wrap
                            // rather than be cut off, which is the whole
                            // reason the tab bar had to go.
                            style: AppType.subheadline.copyWith(color: supporting),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
