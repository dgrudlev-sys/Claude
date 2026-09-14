import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/numeric_input.dart';
import '../l10n/l10n.dart';
import '../theme/type_voice.dart';

enum NumericFieldKind { scalar, list }

/// Number-only text field used by Finance and other value inputs.
class NumericField extends StatelessWidget {
  const NumericField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.labelText,
    this.enabled = true,
    this.kind = NumericFieldKind.scalar,
    this.textAlign = TextAlign.start,
    this.isDense = true,
    this.showHelper = true,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? labelText;
  final bool enabled;
  final NumericFieldKind kind;
  final TextAlign textAlign;
  final bool isDense;
  final bool showHelper;

  @override
  Widget build(BuildContext context) {
    final formatters = <TextInputFormatter>[
      if (kind == NumericFieldKind.scalar) NumericInput.scalarFormatter else NumericInput.listFormatter,
    ];
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      onChanged: onChanged,
      textAlign: textAlign,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: formatters,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      style: AppTypefaces.of(context).math(),
      decoration: InputDecoration(
        labelText: labelText,
        isDense: isDense,
        border: const OutlineInputBorder(),
        helperText: showHelper
            ? (kind == NumericFieldKind.scalar
                ? (L10n.maybeOf(context)?.strings.numbersOnly ?? 'Numbers only')
                : (L10n.maybeOf(context)?.strings.numbersAndCommas ?? 'Numbers and commas only'))
            : null,
      ),
    );
  }
}
