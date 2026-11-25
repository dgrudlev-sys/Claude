import 'package:flutter/material.dart';

import '../core/angle_mode.dart';
import '../core/equation_solver.dart';
import '../core/polynomial_solver.dart';
import '../core/symbolic_math.dart';
import '../theme/app_metrics.dart';
import '../theme/type_voice.dart';
import '../widgets/numeric_field.dart';

class SolveScreen extends StatefulWidget {
  const SolveScreen({super.key});

  @override
  State<SolveScreen> createState() => _SolveScreenState();
}

enum _SolveTab { equation, polynomial, calculus }

class _SolveMode {
  const _SolveMode({
    required this.tab,
    required this.title,
    required this.subtitle,
  });

  final _SolveTab tab;
  final String title;
  final String subtitle;
}

const _modes = [
  _SolveMode(
    tab: _SolveTab.equation,
    title: 'Solve for x',
    subtitle: 'Find every real number that works',
  ),
  _SolveMode(
    tab: _SolveTab.polynomial,
    title: 'Polynomial roots',
    subtitle: 'From the numbers in front of each power of x',
  ),
  _SolveMode(
    tab: _SolveTab.calculus,
    title: 'Derivative & simplify',
    subtitle: 'The derivative, and a simpler form',
  ),
];

class _SolveScreenState extends State<SolveScreen> {
  _SolveTab _tab = _SolveTab.equation;

  final _equation = TextEditingController(text: 'x^2 = 4');
  final _guess = TextEditingController(text: '1');
  String? _equationResult;
  String? _equationError;

  final _calcExpr = TextEditingController(text: 'x^3');
  String? _derivativeResult;
  String? _simplifyResult;
  String? _calcError;

  final _coefficients = TextEditingController(text: '1, -6, 11, -6');
  List<PolynomialRoot>? _polynomialRoots;
  String? _polynomialError;

  @override
  void dispose() {
    _equation.dispose();
    _guess.dispose();
    _calcExpr.dispose();
    _coefficients.dispose();
    super.dispose();
  }

  void _solveEquation() {
    setState(() {
      _equationError = null;
      _equationResult = null;
    });
    try {
      final roots = EquationSolver.findRealRoots(
        _equation.text,
        'x',
        initialGuess: double.tryParse(_guess.text) ?? 1,
        angleMode: AngleMode.radians,
      );
      setState(() => _equationResult = roots.map((x) => x.toStringAsFixed(6)).join('   and   '));
    } on EquationSolverError catch (e) {
      setState(() => _equationError = e.message);
    } catch (_) {
      setState(() => _equationError = 'Could not parse that equation');
    }
  }

  void _solvePolynomial() {
    setState(() {
      _polynomialError = null;
      _polynomialRoots = null;
    });
    try {
      final coeffs = _coefficients.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map(double.parse)
          .toList();
      setState(() => _polynomialRoots = PolynomialSolver.solve(coeffs));
    } on PolynomialError catch (e) {
      setState(() => _polynomialError = e.message);
    } catch (_) {
      setState(() => _polynomialError = 'Could not parse those coefficients');
    }
  }

  void _runCalculus() {
    setState(() {
      _calcError = null;
      _derivativeResult = null;
      _simplifyResult = null;
    });
    try {
      setState(() {
        _derivativeResult = SymbolicMath.derivative(_calcExpr.text, 'x');
        _simplifyResult = SymbolicMath.simplify(_calcExpr.text);
      });
    } on SymbolicError catch (e) {
      setState(() => _calcError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        RadioGroup<_SolveTab>(
          groupValue: _tab,
          onChanged: (value) {
            if (value != null) setState(() => _tab = value);
          },
          child: Column(
            children: [
              for (var i = 0; i < _modes.length; i++) ...[
                RadioListTile<_SolveTab>(
                  key: Key('solve-tab-${_modes[i].tab.name}'),
                  value: _modes[i].tab,
                  title: Text(_modes[i].title, style: theme.textTheme.titleMedium),
                  subtitle: Text(_modes[i].subtitle),
                ),
                if (i < _modes.length - 1) const Divider(),
              ],
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppMetrics.space3,
            AppMetrics.space3,
            AppMetrics.space3,
            AppMetrics.space4,
          ),
          child: AnimatedSize(
            duration: AppMotion.standard,
            curve: AppMotion.inOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: AppMotion.standard,
              switchInCurve: AppMotion.out,
              switchOutCurve: AppMotion.out,
              child: KeyedSubtree(
                key: ValueKey(_tab),
                child: switch (_tab) {
                  _SolveTab.equation => _buildEquationPanel(context),
                  _SolveTab.polynomial => _buildPolynomialPanel(context),
                  _SolveTab.calculus => _buildCalculusPanel(context),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquationPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Type an equation with x, like x^2 = 4. The app looks for every real number that works.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppMetrics.space3),
        TextFormField(
          controller: _equation,
          decoration: const InputDecoration(labelText: 'Equation', isDense: true, border: OutlineInputBorder()),
          style: AppTypefaces.of(context).math(),
        ),
        const SizedBox(height: AppMetrics.space2),
        NumericField(
          controller: _guess,
          labelText: 'Starting guess (if there are two answers, try 1 and also −1)',
        ),
        const SizedBox(height: AppMetrics.space3),
        _SolveActionButton(onPressed: _solveEquation, label: 'Solve'),
        if (_equationError != null) _ErrorCard(message: _equationError!),
        if (_equationResult != null)
          Padding(
            padding: const EdgeInsets.only(top: AppMetrics.space3),
            child: Semantics(
              liveRegion: true,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppMetrics.padCard),
                  child: Text(
                    'x = $_equationResult',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPolynomialPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Type the numbers in front of each power of x, biggest power first. Example: x³ − 6x² + 11x − 6 is 1, -6, 11, -6.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppMetrics.space3),
        TextFormField(
          controller: _coefficients,
          decoration: const InputDecoration(labelText: 'Coefficients', isDense: true, border: OutlineInputBorder()),
          style: AppTypefaces.of(context).math(),
        ),
        const SizedBox(height: AppMetrics.space3),
        _SolveActionButton(onPressed: _solvePolynomial, label: 'Find roots'),
        if (_polynomialError != null) _ErrorCard(message: _polynomialError!),
        if (_polynomialRoots != null)
          Padding(
            padding: const EdgeInsets.only(top: AppMetrics.space3),
            child: Semantics(
              liveRegion: true,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppMetrics.padCard),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _polynomialRoots!.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppMetrics.space1),
                          child: Text(
                            'x${_subscript(i + 1)} = ${_polynomialRoots![i]}',
                            style: AppTypefaces.of(context).math(theme.textTheme.titleMedium),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _subscript(int n) {
    const digits = ['₀', '₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }

  Widget _buildCalculusPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Type an expression in x. The app writes the derivative and a simpler form.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppMetrics.space3),
        TextFormField(
          controller: _calcExpr,
          decoration: const InputDecoration(labelText: 'f(x) =', isDense: true, border: OutlineInputBorder()),
          style: AppTypefaces.of(context).math(),
        ),
        const SizedBox(height: AppMetrics.space3),
        _SolveActionButton(onPressed: _runCalculus, label: 'Compute'),
        if (_calcError != null) _ErrorCard(message: _calcError!),
        if (_derivativeResult != null) _ResultCard(label: "f'(x)", value: _derivativeResult!),
        if (_simplifyResult != null) _ResultCard(label: 'simplified', value: _simplifyResult!),
      ],
    );
  }
}

class _SolveActionButton extends StatelessWidget {
  const _SolveActionButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMetrics.radiusControl),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppMetrics.space3),
      child: Semantics(
        liveRegion: true,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppMetrics.padCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppMetrics.space1),
                SelectableText(value, style: AppTypefaces.of(context).math(theme.textTheme.titleMedium)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppMetrics.space3),
      child: Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppMetrics.padCard),
          child: Text(message),
        ),
      ),
    );
  }
}
