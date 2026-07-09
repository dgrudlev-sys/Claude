import 'package:flutter/material.dart';

import '../core/angle_mode.dart';
import '../core/equation_solver.dart';
import '../core/symbolic_math.dart';

class SolveScreen extends StatefulWidget {
  const SolveScreen({super.key});

  @override
  State<SolveScreen> createState() => _SolveScreenState();
}

enum _SolveTab { equation, calculus }

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

  @override
  void dispose() {
    _equation.dispose();
    _guess.dispose();
    _calcExpr.dispose();
    super.dispose();
  }

  void _solveEquation() {
    setState(() {
      _equationError = null;
      _equationResult = null;
    });
    try {
      final x = EquationSolver.solve(
        _equation.text,
        'x',
        initialGuess: double.tryParse(_guess.text) ?? 1,
        angleMode: AngleMode.radians,
      );
      setState(() => _equationResult = x.toStringAsFixed(8));
    } on EquationSolverError catch (e) {
      setState(() => _equationError = e.message);
    } catch (_) {
      setState(() => _equationError = 'Could not parse that equation');
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SegmentedButton<_SolveTab>(
            segments: const [
              ButtonSegment(value: _SolveTab.equation, label: Text('Solve for x')),
              ButtonSegment(value: _SolveTab.calculus, label: Text('Derivative & simplify')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
            showSelectedIcon: false,
          ),
        ),
        Expanded(
          child: _tab == _SolveTab.equation ? _buildEquationPanel(context) : _buildCalculusPanel(context),
        ),
      ],
    );
  }

  Widget _buildEquationPanel(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Enter an equation in x — either set equal to 0 (e.g. x^2-4) or '
          'with both sides written out (e.g. x^2=4). A numeric solver needs '
          'a starting guess, the same way a physical calculator\'s equation '
          'solver does.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _equation,
          decoration: const InputDecoration(labelText: 'Equation', isDense: true, border: OutlineInputBorder()),
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _guess,
          decoration: const InputDecoration(labelText: 'Starting guess for x', isDense: true, border: OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _solveEquation, child: const Text('Solve')),
        if (_equationError != null) _ErrorCard(message: _equationError!),
        if (_equationResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('x = $_equationResult', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalculusPanel(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _calcExpr,
          decoration: const InputDecoration(labelText: 'f(x) =', isDense: true, border: OutlineInputBorder()),
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _runCalculus, child: const Text('Compute')),
        if (_calcError != null) _ErrorCard(message: _calcError!),
        if (_derivativeResult != null)
          _ResultCard(label: "f'(x)", value: _derivativeResult!),
        if (_simplifyResult != null)
          _ResultCard(label: 'simplified', value: _simplifyResult!),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              SelectableText(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 15)),
            ],
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
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(padding: const EdgeInsets.all(12), child: Text(message)),
      ),
    );
  }
}
