import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../convert/fraction_math.dart';
import '../convert/tool_explainers.dart';
import '../theme/app_metrics.dart';
import '../widgets/chooser_tile.dart';
import '../widgets/numeric_field.dart';
import '../widgets/steps_panel.dart';

class FractionsScreen extends StatefulWidget {
  const FractionsScreen({super.key});

  @override
  State<FractionsScreen> createState() => _FractionsScreenState();
}

class _FractionTerm {
  _FractionTerm({
    String whole = '0',
    String numerator = '1',
    String denominator = '1',
  }) : w = TextEditingController(text: whole),
       n = TextEditingController(text: numerator),
       d = TextEditingController(text: denominator);

  final TextEditingController w;
  final TextEditingController n;
  final TextEditingController d;

  void dispose() {
    w.dispose();
    n.dispose();
    d.dispose();
  }
}

class _FractionsScreenState extends State<FractionsScreen> {
  static const _minTap = AppMetrics.grid * 6;

  final _terms = <_FractionTerm>[
    _FractionTerm(numerator: '1', denominator: '2'),
    _FractionTerm(numerator: '1', denominator: '3'),
  ];
  FractionOp _op = FractionOp.add;
  bool _compare = false;
  String? _lastAnnounced;

  @override
  void dispose() {
    for (final term in _terms) {
      term.dispose();
    }
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

  void _addTerm() {
    setState(() {
      _compare = false;
      _terms.add(_FractionTerm());
    });
  }

  void _removeTerm(int index) {
    if (_terms.length <= 2 || index < 2) return;
    setState(() {
      final removed = _terms.removeAt(index);
      removed.dispose();
    });
  }

  String get _opWord => switch (_op) {
    FractionOp.add => 'plus',
    FractionOp.subtract => 'minus',
    FractionOp.multiply => 'times',
    FractionOp.divide => 'divided by',
  };

  String _opLabel(FractionOp op) {
    final many = _terms.length > 2;
    return switch (op) {
      FractionOp.add => many ? 'Add all' : 'Plus',
      FractionOp.subtract => many ? 'Subtract in order' : 'Minus',
      FractionOp.multiply => many ? 'Multiply all' : 'Times',
      FractionOp.divide => many ? 'Divide in order' : 'Divide',
    };
  }

  String _termTitle(int index) {
    const named = ['First fraction', 'Second fraction'];
    if (index < named.length) return named[index];
    return 'Fraction ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = <({int whole, int num, int den})?>[];
    var incomplete = false;
    for (final term in _terms) {
      final n = _int(term.n);
      final d = _int(term.d);
      if (n == null || d == null) {
        parsed.add(null);
        incomplete = true;
      } else {
        parsed.add((whole: _int(term.w) ?? 0, num: n, den: d));
      }
    }

    String result;
    Explanation explanation = const Explanation(steps: []);
    try {
      if (incomplete) {
        result = 'Fill in the numerator and denominator for every fraction.';
      } else {
        final fractions = [
          for (final t in parsed)
            Fraction.mixed(
              whole: t!.whole,
              numerator: t.num,
              denominator: t.den,
            ),
        ];
        if (_compare && fractions.length == 2) {
          final a = fractions[0];
          final b = fractions[1];
          final cmp = a.compareTo(b);
          if (cmp == 0) {
            result = '${a.mixedLabel} and ${b.mixedLabel} are the same.';
          } else if (cmp > 0) {
            result = '${a.mixedLabel} is greater than ${b.mixedLabel}.';
          } else {
            result = '${a.mixedLabel} is less than ${b.mixedLabel}.';
          }
        } else {
          final c = evalFractionTerms(fractions, _op);
          final joined = fractions
              .map((f) => f.improperLabel)
              .join(' $_opWord ');
          result =
              '$joined is ${c.improperLabel}. That is also ${c.mixedLabel}, or ${formatExplainNumber(c.toDecimal)}.';
          explanation = ToolExplainers.fractionsAll(fractions, _op);
        }
      }
    } catch (e) {
      result = e is ArgumentError
          ? '${e.message}'
          : 'That fraction does not work.';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(result));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: AppMetrics.space2,
        bottom: AppMetrics.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Fractions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: AppMetrics.titleHeight,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppMetrics.space2),
                Text(
                  'Each row is one mixed number: whole (or 0), numerator, and denominator. '
                  'The operation applies to every term.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: AppMetrics.bodyHeight,
                  ),
                ),
                const SizedBox(height: AppMetrics.space3),
                Text(
                  'Operation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppMetrics.space2),
          ...ChooserTile.separated([
            for (final op in FractionOp.values)
              ChooserTile(
                key: Key('frac-op-${op.name}'),
                title: _opLabel(op),
                selected: !_compare && _op == op,
                onTap: () => setState(() {
                  _compare = false;
                  _op = op;
                }),
              ),
            if (_terms.length == 2)
              ChooserTile(
                key: const Key('frac-op-compare'),
                title: 'Compare',
                selected: _compare,
                onTap: () => setState(() => _compare = true),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          const SizedBox(height: AppMetrics.space3),
          AnimatedSize(
            duration: AppMotion.standard,
            curve: AppMotion.inOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _terms.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppMetrics.space3),
                  _pair(context, i),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppMetrics.space3),
          Semantics(
            button: true,
            label: 'Add another fraction',
            child: ExcludeSemantics(
              child: OutlinedButton(
                key: const Key('fractions-add-term'),
                onPressed: _addTerm,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(_minTap),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppMetrics.space3,
                    vertical: AppMetrics.space2,
                  ),
                  alignment: Alignment.center,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AlignedGlyph(icon: Icons.add),
                    SizedBox(width: AppMetrics.space2),
                    Text('Add another fraction'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppMetrics.space3),
          Semantics(
            liveRegion: true,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppMetrics.padCard),
                child: Text(
                  result,
                  key: const Key('frac-result'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: AppMetrics.titleHeight,
                    letterSpacing: AppMetrics.titleTracking,
                  ),
                ),
              ),
            ),
          ),
          if (explanation.isNotEmpty) StepsPanel(explanation: explanation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pair(BuildContext context, int index) {
    final term = _terms[index];
    final title = _termTitle(index);
    final i = index + 1;
    final canRemove = index >= 2 && _terms.length > 2;
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (canRemove)
                Semantics(
                  button: true,
                  label: 'Remove this fraction',
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: _minTap,
                      height: _minTap,
                      child: IconButton(
                        key: Key('fractions-remove-term-$i'),
                        tooltip: 'Remove this fraction',
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeTerm(index),
                        icon: const AlignedGlyph(
                          icon: Icons.remove_circle_outline,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppMetrics.space2),
          Row(
            children: [
              Expanded(
                child: NumericField(
                  key: Key('frac-w$i'),
                  controller: term.w,
                  labelText: 'Whole',
                  showHelper: false,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppMetrics.space2),
              Expanded(
                child: NumericField(
                  key: Key('frac-n$i'),
                  controller: term.n,
                  labelText: 'Top',
                  showHelper: false,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppMetrics.space2),
              Expanded(
                child: NumericField(
                  key: Key('frac-d$i'),
                  controller: term.d,
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
