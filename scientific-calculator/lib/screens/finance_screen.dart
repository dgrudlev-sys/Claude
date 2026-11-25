import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../finance/money_math.dart';
import '../convert/tool_explainers.dart';
import '../theme/app_metrics.dart';
import '../widgets/chooser_tile.dart';
import '../widgets/numeric_field.dart';
import '../widgets/steps_panel.dart';

enum _FinanceJob { simple, compound, loan, savings }

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  _FinanceJob? _job;
  final _principal = TextEditingController(text: '1000');
  final _rate = TextEditingController(text: '5');
  final _years = TextEditingController(text: '2');
  final _months = TextEditingController(text: '12');
  final _times = TextEditingController(text: '1');
  final _monthlyAdd = TextEditingController(text: '50');
  String? _result;
  Explanation? _explanation;
  String? _error;
  String? _lastAnnounced;

  @override
  void dispose() {
    for (final c in [_principal, _rate, _years, _months, _times, _monthlyAdd]) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  int _parseInt(TextEditingController c) => _parse(c).round();

  void _announce(String text) {
    if (text == _lastAnnounced) return;
    _lastAnnounced = text;
    SemanticsService.announce(text, TextDirection.ltr); // ignore: deprecated_member_use
  }

  String _fmt(double v) {
    if ((v - v.roundToDouble()).abs() < 1e-9 && v.abs() < 1e12) {
      return v.round().toString();
    }
    return v.toStringAsFixed(2);
  }

  void _calculate() {
    setState(() {
      _error = null;
      _result = null;
      _explanation = null;
    });
    try {
      switch (_job) {
        case _FinanceJob.simple:
          final interest = MoneyMath.simpleInterest(
            principal: _parse(_principal),
            ratePercent: _parse(_rate),
            years: _parse(_years),
          );
          final total = _parse(_principal) + interest;
          _result = 'Interest ${_fmt(interest)}. Total ${_fmt(total)}.';
          _explanation = ToolExplainers.simpleInterest(
            principal: _parse(_principal),
            ratePercent: _parse(_rate),
            years: _parse(_years),
          );
        case _FinanceJob.compound:
          final amount = MoneyMath.compoundAmount(
            principal: _parse(_principal),
            ratePercent: _parse(_rate),
            years: _parse(_years),
            timesPerYear: _parseInt(_times).clamp(1, 365),
          );
          _result = 'It grows to ${_fmt(amount)}.';
          _explanation = ToolExplainers.compoundInterest(
            principal: _parse(_principal),
            ratePercent: _parse(_rate),
            years: _parse(_years),
            timesPerYear: _parseInt(_times).clamp(1, 365),
          );
        case _FinanceJob.loan:
          final payment = MoneyMath.monthlyLoanPayment(
            principal: _parse(_principal),
            annualRatePercent: _parse(_rate),
            months: _parseInt(_months),
          );
          _result = 'Monthly payment ${_fmt(payment)}.';
          _explanation = ToolExplainers.loan(
            principal: _parse(_principal),
            annualRatePercent: _parse(_rate),
            months: _parseInt(_months),
          );
        case _FinanceJob.savings:
          final future = MoneyMath.savingsFutureValue(
            startAmount: _parse(_principal),
            monthlyAdd: _parse(_monthlyAdd),
            annualRatePercent: _parse(_rate),
            months: _parseInt(_months),
          );
          _result = 'You will have ${_fmt(future)}.';
          _explanation = ToolExplainers.savings(
            startAmount: _parse(_principal),
            monthlyAdd: _parse(_monthlyAdd),
            annualRatePercent: _parse(_rate),
            months: _parseInt(_months),
          );
        case null:
          return;
      }
      _announce('$_result ${_explanation?.spoken ?? ''}');
      setState(() {});
    } on MoneyMathError catch (e) {
      setState(() => _error = e.message);
      _announce(e.message);
    } catch (_) {
      setState(() => _error = 'Could not compute a result with these values.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    if (job == null) return _picker(context);
    return _form(context, job);
  }

  Widget _picker(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: AppMetrics.space2, bottom: AppMetrics.space4),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppMetrics.space3, 0, AppMetrics.space3, AppMetrics.space2),
          child: Text(
            'What do you want to know?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: AppMetrics.titleHeight,
                  letterSpacing: AppMetrics.titleTracking,
                ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(AppMetrics.space3, 0, AppMetrics.space3, AppMetrics.space2),
          child: Text('Pick one money question. Numbers only in every box.'),
        ),
        ...ChooserTile.separated([
          ChooserTile(
            key: const Key('finance-simple'),
            title: 'Simple interest',
            subtitle: 'How much extra money at a plain yearly percent?',
            onTap: () => setState(() => _job = _FinanceJob.simple),
          ),
          ChooserTile(
            key: const Key('finance-compound'),
            title: 'Compound interest',
            subtitle: 'How much will it grow if interest earns interest?',
            onTap: () => setState(() => _job = _FinanceJob.compound),
          ),
          ChooserTile(
            key: const Key('finance-loan'),
            title: 'Loan payment',
            subtitle: 'What is my monthly payment?',
            onTap: () => setState(() => _job = _FinanceJob.loan),
          ),
          ChooserTile(
            key: const Key('finance-savings'),
            title: 'Savings',
            subtitle: 'How much will I have saved later?',
            onTap: () => setState(() => _job = _FinanceJob.savings),
          ),
        ]),
      ],
    );
  }

  Widget _form(BuildContext context, _FinanceJob job) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() {
              _job = null;
              _result = null;
              _explanation = null;
              _error = null;
            }),
            child: const Text('All money questions'),
          ),
        ),
        Text(
          switch (job) {
            _FinanceJob.simple => 'Simple interest',
            _FinanceJob.compound => 'Compound interest',
            _FinanceJob.loan => 'Loan payment',
            _FinanceJob.savings => 'Savings',
          },
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        NumericField(
          key: const Key('finance-principal'),
          controller: _principal,
          labelText: job == _FinanceJob.loan ? 'How much is the loan?' : 'Starting amount',
        ),
        const SizedBox(height: 12),
        NumericField(
          key: const Key('finance-rate'),
          controller: _rate,
          labelText: 'Yearly percent',
        ),
        const SizedBox(height: 12),
        if (job == _FinanceJob.simple || job == _FinanceJob.compound)
          NumericField(
            key: const Key('finance-years'),
            controller: _years,
            labelText: 'How many years?',
          ),
        if (job == _FinanceJob.compound) ...[
          const SizedBox(height: 12),
          NumericField(
            key: const Key('finance-times'),
            controller: _times,
            labelText: 'Times it grows each year',
          ),
        ],
        if (job == _FinanceJob.loan || job == _FinanceJob.savings)
          NumericField(
            key: const Key('finance-months'),
            controller: _months,
            labelText: 'How many months?',
          ),
        if (job == _FinanceJob.savings) ...[
          const SizedBox(height: 12),
          NumericField(
            key: const Key('finance-monthly-add'),
            controller: _monthlyAdd,
            labelText: 'Added each month',
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _calculate,
          child: const Text('Calculate'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_result!, key: const Key('finance-result'), style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_explanation != null) StepsPanel(explanation: _explanation!),
      ],
    );
  }
}
