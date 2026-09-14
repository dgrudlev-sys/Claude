import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../convert/fraction_math.dart';
import '../convert/tool_explainers.dart';
import '../widgets/numeric_field.dart';
import '../widgets/steps_panel.dart';

class FractionsScreen extends StatefulWidget {
  const FractionsScreen({super.key});

  @override
  State<FractionsScreen> createState() => _FractionsScreenState();
}

class _FractionsScreenState extends State<FractionsScreen> {
  final _w1 = TextEditingController(text: '0');
  final _n1 = TextEditingController(text: '1');
  final _d1 = TextEditingController(text: '2');
  final _w2 = TextEditingController(text: '0');
  final _n2 = TextEditingController(text: '1');
  final _d2 = TextEditingController(text: '3');
  FractionOp _op = FractionOp.add;
  bool _compare = false;
  String? _lastAnnounced;

  @override
  void dispose() {
    _w1.dispose();
    _n1.dispose();
    _d1.dispose();
    _w2.dispose();
    _n2.dispose();
    _d2.dispose();
    super.dispose();
  }

  int? _int(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t)?.round();
  }

  void _announce(String text) {
    if (text == _lastAnnounced) return;
    _lastAnnounced = text;
    SemanticsService.announce(text, TextDirection.ltr); // ignore: deprecated_member_use
  }

  String get _opWord => switch (_op) {
        FractionOp.add => 'plus',
        FractionOp.subtract => 'minus',
        FractionOp.multiply => 'times',
        FractionOp.divide => 'divided by',
      };

  @override
  Widget build(BuildContext context) {
    final w1 = _int(_w1) ?? 0;
    final n1 = _int(_n1);
    final d1 = _int(_d1);
    final w2 = _int(_w2) ?? 0;
    final n2 = _int(_n2);
    final d2 = _int(_d2);
    String result;
    Explanation explanation = const Explanation(steps: []);
    try {
      if (n1 == null || d1 == null || n2 == null || d2 == null) {
        result = 'Fill in the top and bottom numbers.';
      } else {
        final a = Fraction.mixed(whole: w1, numerator: n1, denominator: d1);
        final b = Fraction.mixed(whole: w2, numerator: n2, denominator: d2);
        if (_compare) {
          final cmp = a.compareTo(b);
          if (cmp == 0) {
            result = '${a.mixedLabel} and ${b.mixedLabel} are the same.';
          } else if (cmp > 0) {
            result = '${a.mixedLabel} is bigger than ${b.mixedLabel}.';
          } else {
            result = '${a.mixedLabel} is smaller than ${b.mixedLabel}.';
          }
        } else {
          final c = evalFractions(a, _op, b);
          result =
              '${a.improperLabel} $_opWord ${b.improperLabel} is ${c.improperLabel}. That is also ${c.mixedLabel}, or ${c.toDecimal}.';
          explanation = ToolExplainers.fractions(a, _op, b);
        }
      }
    } catch (e) {
      result = e is ArgumentError ? e.message : 'That fraction does not work.';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(result));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Two fractions.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Whole number (or 0), then the top and bottom of the fraction. Pick plus, minus, times, divide, or compare.',
        ),
        const SizedBox(height: 16),
        _pair(context, 'First fraction', _w1, _n1, _d1, 'frac-w1', 'frac-n1', 'frac-d1'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final op in FractionOp.values)
              ChoiceChip(
                key: Key('frac-op-${op.name}'),
                label: Text(switch (op) {
                  FractionOp.add => 'Plus',
                  FractionOp.subtract => 'Minus',
                  FractionOp.multiply => 'Times',
                  FractionOp.divide => 'Divide',
                }),
                selected: !_compare && _op == op,
                onSelected: (_) => setState(() {
                  _compare = false;
                  _op = op;
                }),
              ),
            ChoiceChip(
              key: const Key('frac-op-compare'),
              label: const Text('Compare'),
              selected: _compare,
              onSelected: (_) => setState(() => _compare = true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _pair(context, 'Second fraction', _w2, _n2, _d2, 'frac-w2', 'frac-n2', 'frac-d2'),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                result,
                key: const Key('frac-result'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        if (explanation.isNotEmpty) StepsPanel(explanation: explanation),
      ],
    );
  }

  Widget _pair(
    BuildContext context,
    String title,
    TextEditingController w,
    TextEditingController n,
    TextEditingController d,
    String wKey,
    String nKey,
    String dKey,
  ) {
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: NumericField(
                  key: Key(wKey),
                  controller: w,
                  labelText: 'Whole',
                  showHelper: false,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NumericField(
                  key: Key(nKey),
                  controller: n,
                  labelText: 'Top',
                  showHelper: false,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NumericField(
                  key: Key(dKey),
                  controller: d,
                  labelText: 'Bottom',
                  showHelper: false,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
