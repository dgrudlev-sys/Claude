import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../convert/percent_math.dart';
import '../convert/tool_explainers.dart';
import '../theme/app_metrics.dart';
import '../widgets/chooser_tile.dart';
import '../widgets/numeric_field.dart';
import '../widgets/steps_panel.dart';

enum _PercentJob { of, what, change }

class PercentageScreen extends StatefulWidget {
  const PercentageScreen({super.key});

  @override
  State<PercentageScreen> createState() => _PercentageScreenState();
}

class _PercentageScreenState extends State<PercentageScreen> {
  _PercentJob? _job;
  final _a = TextEditingController(text: '15');
  final _b = TextEditingController(text: '80');
  String? _lastAnnounced;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  String _fmt(double v) {
    if ((v - v.roundToDouble()).abs() < 1e-9 && v.abs() < 1e12) {
      return v.round().toString();
    }
    var text = v.toStringAsFixed(4);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    return text.replaceFirst(RegExp(r'\.$'), '');
  }

  void _announce(String text) {
    if (text == _lastAnnounced) return;
    _lastAnnounced = text;
    SemanticsService.announce(text, TextDirection.ltr); // ignore: deprecated_member_use
  }

  @override
  Widget build(BuildContext context) {
    if (_job == null) return _picker(context);
    return _form(context, _job!);
  }

  Widget _picker(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: AppMetrics.space2, bottom: AppMetrics.space4),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppMetrics.space3, 0, AppMetrics.space3, AppMetrics.space2),
          child: Text(
            'Pick one question.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: AppMetrics.titleHeight,
                  letterSpacing: AppMetrics.titleTracking,
                ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(AppMetrics.space3, 0, AppMetrics.space3, AppMetrics.space2),
          child: Text('Each row is one kind of percent. Numbers only.'),
        ),
        ...ChooserTile.separated([
          ChooserTile(
            key: const Key('percent-of'),
            title: 'What is this percent of a number?',
            subtitle: 'Example: 15% of 80.',
            onTap: () => setState(() {
              _job = _PercentJob.of;
              _a.text = '15';
              _b.text = '80';
            }),
          ),
          ChooserTile(
            key: const Key('percent-what'),
            title: 'This number is what percent of that number?',
            subtitle: 'Example: 20 is what percent of 50.',
            onTap: () => setState(() {
              _job = _PercentJob.what;
              _a.text = '20';
              _b.text = '50';
            }),
          ),
          ChooserTile(
            key: const Key('percent-change'),
            title: 'Increase or decrease a number by a percent',
            subtitle: 'Example: 50 plus 10%, or 50 minus 10% (type −10).',
            onTap: () => setState(() {
              _job = _PercentJob.change;
              _a.text = '50';
              _b.text = '10';
            }),
          ),
        ]),
      ],
    );
  }

  Widget _form(BuildContext context, _PercentJob job) {
    final a = _parse(_a);
    final b = _parse(_b);
    String result;
    Explanation explanation = const Explanation(steps: []);
    try {
      if (a == null || b == null) {
        result = 'Type both numbers.';
      } else {
        result = switch (job) {
          _PercentJob.of => '${_fmt(a)} percent of ${_fmt(b)} is ${_fmt(PercentMath.percentOf(percent: a, ofValue: b))}.',
          _PercentJob.what =>
            '${_fmt(a)} is ${_fmt(PercentMath.whatPercent(part: a, whole: b))} percent of ${_fmt(b)}.',
          _PercentJob.change =>
            '${_fmt(b)} percent change of ${_fmt(a)} is ${_fmt(PercentMath.changeBy(amount: a, percent: b))}.',
        };
        explanation = switch (job) {
          _PercentJob.of => ToolExplainers.percentOf(percent: a, ofValue: b),
          _PercentJob.what => ToolExplainers.whatPercent(part: a, whole: b),
          _PercentJob.change => ToolExplainers.percentChange(amount: a, percent: b),
        };
      }
    } catch (_) {
      result = 'That percent cannot use zero as the whole.';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(result));

    final labels = switch (job) {
      _PercentJob.of => ('Percent', 'Of this number'),
      _PercentJob.what => ('This number', 'Of this whole'),
      _PercentJob.change => ('Starting number', 'Percent change (minus for down)'),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _job = null),
            child: const Text('All percent questions'),
          ),
        ),
        const SizedBox(height: 8),
        NumericField(
          key: const Key('percent-a'),
          controller: _a,
          labelText: labels.$1,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        NumericField(
          key: const Key('percent-b'),
          controller: _b,
          labelText: labels.$2,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                result,
                key: const Key('percent-result'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        if (explanation.isNotEmpty) StepsPanel(explanation: explanation),
      ],
    );
  }
}
