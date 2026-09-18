import 'package:flutter/material.dart';

import '../statistics/stats_controller.dart';
import '../statistics/stats_engine.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _controller = StatsController();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: SegmentedButton<StatsTab>(
                segments: const [
                  ButtonSegment(value: StatsTab.oneVar, label: Text('1-Var')),
                  ButtonSegment(value: StatsTab.regression, label: Text('Regression')),
                  ButtonSegment(value: StatsTab.distributions, label: Text('Distributions')),
                ],
                selected: {_controller.tab},
                onSelectionChanged: (s) => _controller.setTab(s.first),
                showSelectedIcon: false,
              ),
            ),
            Expanded(
              child: switch (_controller.tab) {
                StatsTab.oneVar => _OneVarPanel(controller: _controller),
                StatsTab.regression => _RegressionPanel(controller: _controller),
                StatsTab.distributions => _DistributionPanel(controller: _controller),
              },
            ),
          ],
        );
      },
    );
  }
}

class _DataField extends StatelessWidget {
  const _DataField({required this.label, required this.value, required this.onChanged});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: '$label (comma-separated)',
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _OneVarPanel extends StatelessWidget {
  const _OneVarPanel({required this.controller});

  final StatsController controller;

  @override
  Widget build(BuildContext context) {
    final r = controller.oneVarResult;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _DataField(label: 'L1', value: controller.l1Text, onChanged: controller.setL1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FilledButton(onPressed: controller.computeOneVar, child: const Text('Calculate')),
        ),
        if (controller.error != null) _ErrorCard(message: controller.error!),
        if (r != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow('n', '${r.n}'),
                    _StatRow('x̄ (mean)', r.mean.toStringAsFixed(6)),
                    _StatRow('Σx (sum)', r.sum.toStringAsFixed(6)),
                    _StatRow('Sx (sample stdev)', r.sampleStdDev.toStringAsFixed(6)),
                    _StatRow('σx (population stdev)', r.populationStdDev.toStringAsFixed(6)),
                    _StatRow('min', r.min.toStringAsFixed(6)),
                    _StatRow('Q1', r.q1.toStringAsFixed(6)),
                    _StatRow('median', r.median.toStringAsFixed(6)),
                    _StatRow('Q3', r.q3.toStringAsFixed(6)),
                    _StatRow('max', r.max.toStringAsFixed(6)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RegressionPanel extends StatelessWidget {
  const _RegressionPanel({required this.controller});

  final StatsController controller;

  @override
  Widget build(BuildContext context) {
    final r = controller.regressionResult;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _DataField(label: 'L1 (x)', value: controller.l1Text, onChanged: controller.setL1),
        _DataField(label: 'L2 (y)', value: controller.l2Text, onChanged: controller.setL2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<RegressionKind>(
            initialValue: controller.regressionKind,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            items: [
              for (final kind in RegressionKind.values)
                DropdownMenuItem(value: kind, child: Text(_regressionLabel(kind))),
            ],
            onChanged: (kind) {
              if (kind != null) controller.setRegressionKind(kind);
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FilledButton(onPressed: controller.computeRegression, child: const Text('Calculate')),
        ),
        if (controller.error != null) _ErrorCard(message: controller.error!),
        if (r != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.equation, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                    const SizedBox(height: 8),
                    _StatRow('R²', r.rSquared.toStringAsFixed(6)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _regressionLabel(RegressionKind kind) => switch (kind) {
        RegressionKind.linear => 'Linear: y = a + bx',
        RegressionKind.quadratic => 'Quadratic: y = a + bx + cx²',
        RegressionKind.cubic => 'Cubic: y = a + bx + cx² + dx³',
        RegressionKind.quartic => 'Quartic: y = a + bx + ... + ex⁴',
        RegressionKind.power => 'Power: y = a·x^b',
        RegressionKind.exponential => 'Exponential: y = a·b^x',
        RegressionKind.logarithmic => 'Logarithmic: y = a + b·ln(x)',
      };
}

class _DistributionPanel extends StatefulWidget {
  const _DistributionPanel({required this.controller});

  final StatsController controller;

  @override
  State<_DistributionPanel> createState() => _DistributionPanelState();
}

class _DistributionPanelState extends State<_DistributionPanel> {
  final _lower = TextEditingController(text: '-1');
  final _upper = TextEditingController(text: '1');
  final _mean = TextEditingController(text: '0');
  final _sd = TextEditingController(text: '1');
  final _area = TextEditingController(text: '0.95');
  final _n = TextEditingController(text: '10');
  final _p = TextEditingController(text: '0.5');
  final _k = TextEditingController(text: '5');

  @override
  void dispose() {
    for (final c in [_lower, _upper, _mean, _sd, _area, _n, _p, _k]) {
      c.dispose();
    }
    super.dispose();
  }

  void _compute() {
    widget.controller.computeDistribution(
      a: widget.controller.distributionKind == DistributionKind.invNorm
          ? double.tryParse(_area.text) ?? 0.5
          : double.tryParse(_lower.text) ?? 0,
      b: double.tryParse(_upper.text) ?? 0,
      mean: double.tryParse(_mean.text) ?? 0,
      sd: double.tryParse(_sd.text) ?? 1,
      n: int.tryParse(_n.text) ?? 0,
      p: double.tryParse(_p.text) ?? 0.5,
      k: int.tryParse(_k.text) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.controller.distributionKind;
    final isNormal = kind == DistributionKind.normalCdf || kind == DistributionKind.invNorm;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        DropdownButtonFormField<DistributionKind>(
          initialValue: kind,
          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: DistributionKind.normalCdf, child: Text('normalcdf(lower, upper)')),
            DropdownMenuItem(value: DistributionKind.invNorm, child: Text('invNorm(area)')),
            DropdownMenuItem(value: DistributionKind.binomialPdf, child: Text('binompdf(n, p, k)')),
            DropdownMenuItem(value: DistributionKind.binomialCdf, child: Text('binomcdf(n, p, k) — P(X≤k)')),
          ],
          onChanged: (v) {
            if (v != null) widget.controller.setDistributionKind(v);
          },
        ),
        const SizedBox(height: 12),
        if (kind == DistributionKind.normalCdf) ...[
          _numField('lower', _lower),
          _numField('upper', _upper),
        ],
        if (kind == DistributionKind.invNorm) _numField('area (0-1)', _area),
        if (isNormal) ...[
          _numField('mean (μ)', _mean),
          _numField('standard deviation (σ)', _sd),
        ],
        if (!isNormal) ...[
          _numField('n (trials)', _n),
          _numField('p (probability)', _p),
          _numField('k (successes)', _k),
        ],
        const SizedBox(height: 8),
        FilledButton(onPressed: _compute, child: const Text('Calculate')),
        if (widget.controller.error != null) _ErrorCard(message: widget.controller.error!),
        if (widget.controller.distributionResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Result: ${widget.controller.distributionResult!.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _numField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
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
      padding: const EdgeInsets.all(12),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(padding: const EdgeInsets.all(12), child: Text(message)),
      ),
    );
  }
}
