import 'package:flutter/material.dart';

import '../finance/tvm_solver.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _n = TextEditingController(text: '12');
  final _rate = TextEditingController(text: '5');
  final _pv = TextEditingController(text: '1000');
  final _pmt = TextEditingController(text: '0');
  final _fv = TextEditingController(text: '0');

  TvmVariable _solveFor = TvmVariable.fv;
  int _type = 0;
  String? _result;
  String? _error;

  @override
  void dispose() {
    for (final c in [_n, _rate, _pv, _pmt, _fv]) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController c) => double.tryParse(c.text) ?? 0;

  void _solve() {
    setState(() {
      _error = null;
      _result = null;
    });
    try {
      final n = _parse(_n);
      final rate = _parse(_rate);
      final pv = _parse(_pv);
      final pmt = _parse(_pmt);
      final fv = _parse(_fv);

      final value = switch (_solveFor) {
        TvmVariable.n => TvmSolver.solveN(ratePercent: rate, pv: pv, pmt: pmt, fv: fv, type: _type),
        TvmVariable.ratePercent =>
          TvmSolver.solveRatePercent(n: n, pv: pv, pmt: pmt, fv: fv, type: _type),
        TvmVariable.pv => TvmSolver.solvePv(n: n, ratePercent: rate, pmt: pmt, fv: fv, type: _type),
        TvmVariable.pmt => TvmSolver.solvePmt(n: n, ratePercent: rate, pv: pv, fv: fv, type: _type),
        TvmVariable.fv => TvmSolver.solveFv(n: n, ratePercent: rate, pv: pv, pmt: pmt, type: _type),
      };
      setState(() => _result = value.toStringAsFixed(6));
    } on TvmError catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not compute a result with these values');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Enter the four known values, choose which one to solve for, and Calculate. '
          'Cash paid out is negative, cash received is positive.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        RadioGroup<TvmVariable>(
          groupValue: _solveFor,
          onChanged: (v) {
            if (v != null) setState(() => _solveFor = v);
          },
          child: Column(
            children: [
              _tvmField('N (periods)', _n, TvmVariable.n),
              _tvmField('I% (rate per period)', _rate, TvmVariable.ratePercent),
              _tvmField('PV (present value)', _pv, TvmVariable.pv),
              _tvmField('PMT (payment per period)', _pmt, TvmVariable.pmt),
              _tvmField('FV (future value)', _fv, TvmVariable.fv),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('End of period')),
            ButtonSegment(value: 1, label: Text('Start of period')),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _solve,
          icon: const Icon(Icons.calculate_outlined),
          label: Text('Solve for ${_variableLabel(_solveFor)}'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
            ),
          ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${_variableLabel(_solveFor)} = $_result',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _tvmField(String label, TextEditingController controller, TvmVariable variable) {
    final isTarget = _solveFor == variable;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Radio<TvmVariable>(value: variable),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: !isTarget,
              decoration: InputDecoration(
                labelText: isTarget ? '$label — solving for this' : label,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ),
        ],
      ),
    );
  }

  String _variableLabel(TvmVariable v) => switch (v) {
        TvmVariable.n => 'N',
        TvmVariable.ratePercent => 'I%',
        TvmVariable.pv => 'PV',
        TvmVariable.pmt => 'PMT',
        TvmVariable.fv => 'FV',
      };
}
