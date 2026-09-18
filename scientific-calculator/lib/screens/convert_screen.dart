import 'package:flutter/material.dart';

import '../convert/unit.dart';
import '../convert/unit_catalog.dart';
import '../convert/unit_converter.dart';
import '../design/typography.dart';
import '../engine/number/number.dart';
import '../engine/number/number_display.dart';
import '../theme/app_theme.dart';

/// The converter, at last given a face.
///
/// Every unit in the catalog and all the arithmetic behind it has been
/// working and tested for some time with no way for anyone to reach it.
/// This is that screen: pick what you are measuring, type an amount, and
/// read the answer — with the rest of the category underneath, because
/// the useful question is usually "and what is that in everything else".
///
/// Two things here are not decoration. The result says `=` when the
/// conversion is exact by definition and `≈` when it had to be rounded,
/// so 1 mile = 5280 feet never looks like an approximation. And a unit's
/// note — the US cup having two legal definitions, say — is shown rather
/// than hidden, because silence there produces confidently wrong
/// recipes.
class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  /// The categories people actually reach for, in the order they reach
  /// for them, rather than the enum's declaration order.
  static const _order = <UnitCategory>[
    UnitCategory.length,
    UnitCategory.mass,
    UnitCategory.volume,
    UnitCategory.temperature,
    UnitCategory.area,
    UnitCategory.speed,
    UnitCategory.time,
    UnitCategory.digitalStorage,
    UnitCategory.dataRate,
    UnitCategory.pressure,
    UnitCategory.energy,
    UnitCategory.power,
    UnitCategory.force,
    UnitCategory.angle,
    UnitCategory.frequency,
  ];

  static const _converter = UnitConverter();

  UnitCategory _category = UnitCategory.length;
  late Unit _from = UnitCatalog.inCategory(_category).first;
  late Unit _to = UnitCatalog.inCategory(_category)[1];
  String _amount = '1';

  // Owned here rather than rebuilt inline: the field reads on every
  // keystroke, and a controller recreated each build would drop the
  // selection and send the caret to the end after each digit.
  late final _field = TextEditingController(text: _amount);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _selectCategory(UnitCategory category) {
    final units = UnitCatalog.inCategory(category);
    setState(() {
      _category = category;
      _from = units.first;
      _to = units.length > 1 ? units[1] : units.first;
    });
  }

  void _swap() => setState(() {
        final was = _from;
        _from = _to;
        _to = was;
      });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final units = UnitCatalog.inCategory(_category);

    NumberValue? amount;
    String? problem;
    try {
      amount = NumberValue.parse(_amount);
    } on MathError {
      problem = 'That is not a number.';
    }

    final result = amount == null ? null : _converter.convert(amount, _from, _to);

    // Fifteen wrapped chips need both room and ordinary text to stay out
    // of the way of the amount field. Short of either, they collapse.
    final width = MediaQuery.sizeOf(context).width;
    final compactCategories =
        width < 360 || AccessibilityPreferences.of(context).needsVerticalLayout;

    return ListView(
      padding: const EdgeInsets.all(Space.m),
      children: [
        // Chips when they fit, a picker when they don't.
        //
        // Wrapped rather than scrolled sideways, for the same reason the
        // tab bar went: a category you cannot see is a category you
        // cannot choose, and a horizontal strip hides two thirds of
        // these behind a swipe with nothing to suggest it. But on a
        // narrow phone, or at grown text sizes, fifteen wrapped chips
        // fill the screen on their own and push the amount field out of
        // sight — so past that point the list collapses into one control
        // and the working part of the screen stays where it was.
        if (compactCategories)
          DropdownButtonFormField<UnitCategory>(
            key: const Key('convert-category'),
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Measuring'),
            items: [
              for (final category in _order)
                DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                ),
            ],
            onChanged: (category) {
              if (category != null) _selectCategory(category);
            },
          )
        else
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final category in _order)
                ChoiceChip(
                  label: Text(category.displayName),
                  selected: _category == category,
                  onSelected: (_) => _selectCategory(category),
                ),
            ],
          ),
        const SizedBox(height: Space.l),
        TextField(
          key: const Key('convert-amount'),
          controller: _field,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppType.title2,
          onChanged: (value) => setState(() => _amount = value),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        const SizedBox(height: Space.m),
        _UnitField(
          label: 'From',
          units: units,
          value: _from,
          onChanged: (unit) => setState(() => _from = unit),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _swap,
            icon: const Icon(Icons.swap_vert),
            label: const Text('Swap'),
          ),
        ),
        _UnitField(
          label: 'To',
          units: units,
          value: _to,
          onChanged: (unit) => setState(() => _to = unit),
        ),
        const SizedBox(height: Space.l),
        if (problem != null)
          Text(problem,
              style: AppType.body.copyWith(color: palette.errorSurface.foreground))
        else if (result != null) ...[
          _ResultCard(result: result),
          if (result.warning != null) ...[
            const SizedBox(height: Space.s),
            Text(result.warning!,
                style: AppType.footnote
                    .copyWith(color: palette.errorSurface.foreground)),
          ],
          for (final note in result.notes) ...[
            const SizedBox(height: Space.s),
            Text(note,
                style: AppType.footnote.copyWith(color: palette.secondaryLabel)),
          ],
          const SizedBox(height: Space.l),
          _SectionLabel(label: 'The same amount, everywhere else'),
          const SizedBox(height: Space.s),
          for (final other in _converter.convertToAll(amount!, _from))
            if (other.to.id != _to.id) _OtherRow(result: other),
        ],
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ConversionResult result;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shown = DisplayNumber.of(result.value);
    // Exact only when nothing was rounded *and* the value itself is
    // exact: a conversion through π is approximate however it is printed.
    final exact = result.isExact && !shown.isRounded;

    return Semantics(
      liveRegion: true,
      label: '${shown.text} ${result.to.name.toLowerCase()}'
          '${exact ? '' : ', approximately'}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Space.m),
          decoration: BoxDecoration(
            color: palette.elevatedSurface,
            borderRadius: BorderRadius.circular(Radii.large),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exact ? 'Exactly' : 'Approximately',
                style: AppType.footnote.copyWith(color: palette.secondaryLabel),
              ),
              const SizedBox(height: Space.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(shown.text, style: AppType.displayResult),
              ),
              const SizedBox(height: Space.xs),
              Text(
                '${result.to.name.toLowerCase()} (${result.to.symbol})',
                style: AppType.subheadline.copyWith(color: palette.secondaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtherRow extends StatelessWidget {
  const _OtherRow({required this.result});

  final ConversionResult result;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shown = DisplayNumber.of(result.value, significantDigits: 8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(result.to.name, style: AppType.body),
          ),
          const SizedBox(width: Space.m),
          Flexible(
            child: Text(
              shown.text,
              textAlign: TextAlign.end,
              style: AppType.body.copyWith(
                color: palette.label,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: Space.xs),
          SizedBox(
            width: 52,
            child: Text(
              result.to.symbol,
              style: AppType.footnote.copyWith(color: palette.secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({
    required this.label,
    required this.units,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<Unit> units;
  final Unit value;
  final ValueChanged<Unit> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: Key('convert-$label'),
      initialValue: value.id,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final unit in units)
          DropdownMenuItem(
            value: unit.id,
            child: Text('${unit.name} (${unit.symbol})'),
          ),
      ],
      onChanged: (id) {
        if (id == null) return;
        onChanged(units.firstWhere((u) => u.id == id));
      },
    );
  }
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
