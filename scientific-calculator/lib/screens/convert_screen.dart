import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../convert/convert_engine.dart';
import '../convert/currency_service.dart';
import '../convert/tool_explainers.dart';
import '../l10n/l10n.dart';
import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';
import '../widgets/numeric_field.dart';
import '../widgets/steps_panel.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  ConvertCategory? _category;
  bool _flour = false;
  String? _fromId;
  String? _toId;
  CurrencyBook? _fx;
  Object? _fxError;
  bool _fxLoading = false;
  final _amount = TextEditingController(text: '1');
  final _bill = TextEditingController(text: '100');
  final _tipPercent = TextEditingController(text: '15');
  final _people = TextEditingController(text: '1');
  String? _lastAnnounced;

  @override
  void dispose() {
    _amount.dispose();
    _bill.dispose();
    _tipPercent.dispose();
    _people.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _announce(String text) {
    if (text == _lastAnnounced) return;
    _lastAnnounced = text;
    SemanticsService.announce(text, TextDirection.ltr); // ignore: deprecated_member_use
  }

  void _pick(ConvertCategory category) {
    final flour = category == ConvertCategory.cooking && _flour;
    final units = flour ? ConvertEngine.flourUnits : ConvertEngine.unitsFor(category);
    setState(() {
      _category = category;
      _fromId = category == ConvertCategory.currency
          ? 'EUR'
          : (units.isEmpty ? null : units.first.id);
      _toId = category == ConvertCategory.currency
          ? 'USD'
          : (units.length > 1 ? units[1].id : _fromId);
      _fxError = null;
    });
    if (category == ConvertCategory.currency) {
      _loadRates();
    }
  }

  Future<void> _loadRates({bool force = false}) async {
    setState(() {
      _fxLoading = true;
      _fxError = null;
    });
    try {
      final book = await CurrencyService.instance.load(force: force);
      if (!mounted) return;
      setState(() {
        _fx = book;
        _fxLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fxError = e;
        _fxLoading = false;
      });
    }
  }

  String _fmt(double v) {
    if ((v - v.roundToDouble()).abs() < 1e-9 && v.abs() < 1e12) {
      return v.round().toString();
    }
    var text = v.abs() >= 1e6 || (v.abs() < 1e-4 && v != 0)
        ? v.toStringAsExponential(6)
        : v.toStringAsFixed(6);
    if (text.contains('.') && !text.contains('e') && !text.contains('E')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    if (category == null) return _picker(context);
    if (category == ConvertCategory.tip) return _tipForm(context);
    if (category == ConvertCategory.currency) return _currencyForm(context);
    return _unitForm(context, category);
  }

  Widget _picker(BuildContext context) {
    final strings = L10n.stringsOf(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          strings.convertAsk,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          strings.convertPick,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        for (final category in ConvertCategory.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChoiceCard(
              key: Key('convert-${category.name}'),
              title: strings.convertLabel(category.name),
              subtitle: strings.convertDescription(category.name),
              icon: category.icon,
              onTap: () => _pick(category),
            ),
          ),
      ],
    );
  }

  Widget _unitForm(BuildContext context, ConvertCategory category) {
    final strings = L10n.stringsOf(context);
    final flour = category == ConvertCategory.cooking && _flour;
    final units = flour ? ConvertEngine.flourUnits : ConvertEngine.unitsFor(category);
    final fromId = _fromId ?? units.first.id;
    final toId = _toId ?? (units.length > 1 ? units[1].id : units.first.id);
    final amount = _parse(_amount);
    String resultText;
    String spoken;
    Explanation explanation = const Explanation(steps: []);
    if (amount == null) {
      resultText = 'Type a number.';
      spoken = 'Type a number to convert.';
    } else if (flour) {
      final value = ConvertEngine.convertFlour(fromId: fromId, toId: toId, value: amount);
      final from = units.firstWhere((u) => u.id == fromId);
      final to = units.firstWhere((u) => u.id == toId);
      final grams = ConvertEngine.flourToGrams(fromId, amount);
          resultText =
              '${_fmt(amount)} ${from.name} of flour is about ${_fmt(value)} ${to.name}. ${ConvertEngine.flourMassSummary(grams)}';
      spoken = resultText;
      explanation = ToolExplainers.unitConvert(
        category: category,
        from: from,
        to: to,
        amount: amount,
        value: value,
      );
    } else {
      final value = ConvertEngine.convert(
        category: category,
        fromId: fromId,
        toId: toId,
        value: amount,
      );
      final from = units.firstWhere((u) => u.id == fromId);
      final to = units.firstWhere((u) => u.id == toId);
      resultText = '${_fmt(amount)} ${from.name} is ${_fmt(value)} ${to.name}.';
      spoken = resultText;
      explanation = ToolExplainers.unitConvert(
        category: category,
        from: from,
        to: to,
        amount: amount,
        value: value,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(spoken));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _category = null),
            child: const Text('All converters'),
          ),
        ),
        Text(
          strings.convertLabel(category.name),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (category == ConvertCategory.cooking) ...[
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Liquid'), tooltip: 'Cups, spoons, and millilitres'),
              ButtonSegment(value: true, label: Text('Flour'), tooltip: 'Flour weight to cups and spoons'),
            ],
            selected: {_flour},
            onSelectionChanged: (s) {
              final next = s.first;
              final units = next ? ConvertEngine.flourUnits : ConvertEngine.unitsFor(ConvertCategory.cooking);
              setState(() {
                _flour = next;
                _fromId = next ? 'cup' : units.first.id;
                _toId = next ? 'g' : units[1].id;
              });
            },
          ),
          ),
          if (_flour) ...[
            const SizedBox(height: 8),
            const Text(
              'All-purpose flour is approximate: 1 cup is about 120 grams. Packed flour can weigh more.',
            ),
          ],
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('convert-from-$fromId'),
          isExpanded: true,
          initialValue: fromId,
          decoration: const InputDecoration(
            labelText: 'From',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final u in units)
              DropdownMenuItem(value: u.id, child: Text(u.menuLabel)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _fromId = v);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('convert-to-$toId'),
          isExpanded: true,
          initialValue: toId,
          decoration: const InputDecoration(
            labelText: 'To',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final u in units)
              DropdownMenuItem(value: u.id, child: Text(u.menuLabel)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _toId = v);
          },
        ),
        const SizedBox(height: 12),
        NumericField(
          key: const Key('convert-amount'),
          controller: _amount,
          labelText: 'How many?',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                resultText,
                key: const Key('convert-result'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        if (explanation.isNotEmpty) StepsPanel(explanation: explanation),
      ],
    );
  }

  Widget _currencyForm(BuildContext context) {
    final strings = L10n.stringsOf(context);
    final amount = _parse(_amount);
    final fromId = _fromId ?? 'EUR';
    final toId = _toId ?? 'USD';
    final latest = _fx?.latest;
    String? rateLine;
    FxMove? move;
    String? resultText;
    Explanation explanation = const Explanation(steps: []);
    if (_fxLoading && latest == null) {
      resultText = 'Loading the daily money table.';
    } else if (_fxError != null && latest == null) {
      resultText = 'Could not load the daily money table. Check the internet, then try again.';
    } else if (latest != null) {
      try {
        final from = CurrencyService.catalog.firstWhere((c) => c.code == fromId);
        final to = CurrencyService.catalog.firstWhere((c) => c.code == toId);
        final unit = latest.convert(amount: 1, from: fromId, to: toId);
        rateLine =
            '1 ${from.name} = ${_fmt(unit)} ${to.name}, as of ${formatEcbDate(latest.date)}';
        move = _fx!.move(from: fromId, to: toId);
        if (amount != null) {
          final value = latest.convert(amount: amount, from: fromId, to: toId);
          resultText = '${_fmt(amount)} ${from.name} is ${_fmt(value)} ${to.name}.';
          explanation = ToolExplainers.currency(
            rates: latest,
            from: from,
            to: to,
            amount: amount,
            value: value,
          );
        }
      } catch (_) {
        resultText = 'That currency pair is not in the daily table.';
      }
    }
    if (resultText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _announce(resultText!));
    }

    final codes = {
      ...CurrencyService.catalog.map((c) => c.code),
      if (latest != null) ...latest.perEuro.keys,
    }.where((c) => CurrencyService.catalog.any((info) => info.code == c)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppMetrics.space3,
        AppMetrics.space2,
        AppMetrics.space3,
        AppMetrics.space4,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _category = null),
            child: const Text('All converters'),
          ),
        ),
        Text(
          strings.convertLabel('currency'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppMetrics.space2),
        Text(strings.convertDescription('currency')),
        const SizedBox(height: AppMetrics.space3),
        DropdownButtonFormField<String>(
          key: ValueKey('convert-from-$fromId'),
          isExpanded: true,
          initialValue: fromId,
          decoration: const InputDecoration(
            labelText: 'From',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final c in CurrencyService.catalog)
              if (codes.contains(c.code))
                DropdownMenuItem(value: c.code, child: Text(c.menuLabel)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _fromId = v);
          },
        ),
        const SizedBox(height: AppMetrics.space3),
        DropdownButtonFormField<String>(
          key: ValueKey('convert-to-$toId'),
          isExpanded: true,
          initialValue: toId,
          decoration: const InputDecoration(
            labelText: 'To',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final c in CurrencyService.catalog)
              if (codes.contains(c.code))
                DropdownMenuItem(value: c.code, child: Text(c.menuLabel)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _toId = v);
          },
        ),
        if (rateLine != null) ...[
          const SizedBox(height: AppMetrics.space3),
          _FxRateCard(line: rateLine, move: move),
        ],
        const SizedBox(height: AppMetrics.space3),
        NumericField(
          key: const Key('convert-amount'),
          controller: _amount,
          labelText: 'Amount',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppMetrics.space3),
        if (_fxError != null)
          TextButton(
            onPressed: () => _loadRates(force: true),
            child: const Text('Try again'),
          ),
        AnimatedSize(
          duration: AppMotion.standard,
          curve: AppMotion.inOut,
          alignment: Alignment.topCenter,
          child: resultText == null
              ? const SizedBox(width: double.infinity)
              : Semantics(
                  liveRegion: true,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(AppMetrics.padCard),
                      child: AnimatedSwitcher(
                        duration: AppMotion.standard,
                        switchInCurve: AppMotion.out,
                        switchOutCurve: AppMotion.out,
                        child: Text(
                          resultText,
                          key: const Key('convert-result'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                height: AppMetrics.titleHeight,
                                letterSpacing: AppMetrics.titleTracking,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        if (explanation.isNotEmpty) StepsPanel(explanation: explanation),
      ],
    );
  }

  Widget _tipForm(BuildContext context) {
    final bill = _parse(_bill) ?? 0;
    final percent = _parse(_tipPercent) ?? 0;
    final people = (_parse(_people) ?? 1).round().clamp(1, 9999);
    final result = ConvertEngine.tip(bill: bill, tipPercent: percent, people: people);
    final parts = <String>[
      'Tip is ${_fmt(result.tipAmount)}.',
      'Total is ${_fmt(result.total)}.',
    ];
    if (result.perPerson != null) {
      parts.add('Each person pays ${_fmt(result.perPerson!)}.');
    }
    final resultText = parts.join(' ');
    final explanation = ToolExplainers.tip(bill: bill, tipPercent: percent, people: people);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(resultText));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _category = null),
            child: const Text('All converters'),
          ),
        ),
        Text(
          'Tip',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('Bill amount, tip percent, and optionally how many people split the bill.'),
        const SizedBox(height: 12),
        NumericField(
          key: const Key('convert-bill'),
          controller: _bill,
          labelText: 'Bill amount',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        NumericField(
          key: const Key('convert-tip-percent'),
          controller: _tipPercent,
          labelText: 'Tip percent',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        NumericField(
          key: const Key('convert-people'),
          controller: _people,
          labelText: 'Split between how many people?',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                resultText,
                key: const Key('convert-result'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        StepsPanel(explanation: explanation),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CalculatorPalette>()!;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 32, color: palette.onButton),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.onButton,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FxRateCard extends StatelessWidget {
  const _FxRateCard({required this.line, required this.move});

  final String line;
  final FxMove? move;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moveLabel = switch (move) {
      FxMove.up => 'up from yesterday',
      FxMove.down => 'down from yesterday',
      FxMove.unchanged => 'unchanged from yesterday',
      null => null,
    };
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: moveLabel == null ? line : '$line, $moveLabel',
      child: Card(
        key: const Key('fx-rate-card'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppMetrics.padCard),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.standard,
                  switchInCurve: AppMotion.out,
                  switchOutCurve: AppMotion.out,
                  child: Align(
                    key: ValueKey(line),
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        line,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: AppMetrics.titleHeight,
                          letterSpacing: AppMetrics.titleTracking,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppMetrics.space2),
              SizedBox(
                width: AppMetrics.glyphSize,
                height: AppMetrics.glyphSize,
                child: move == null ? null : _FxMoveGlyph(move: move!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FxMoveGlyph extends StatelessWidget {
  const _FxMoveGlyph({required this.move});

  final FxMove move;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label, dy) = switch (move) {
      FxMove.up => (Icons.arrow_drop_up, AppMetrics.fxUp, 'up from yesterday', 1.5),
      FxMove.down => (Icons.arrow_drop_down, AppMetrics.fxDown, 'down from yesterday', -1.5),
      FxMove.unchanged => (Icons.square, AppMetrics.fxFlat, 'unchanged from yesterday', 0.0),
    };
    return Semantics(
      key: Key('fx-move-${move.name}'),
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: Align(
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Icon(icon, size: AppMetrics.glyphSize, color: color),
          ),
        ),
      ),
    );
  }
}
