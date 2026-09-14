import 'package:flutter/material.dart';

/// How the product speaks in type. Laboratory aspires to instruments and
/// papers; Manuscript is a book face; Clearest is the Braille Institute’s
/// Atkinson Hyperlegible — every letter unmistakable.
enum TypeVoice {
  laboratory(
    label: 'Laboratory',
    description:
        'IBM Plex. The face of labs and instruments: precise, modern, quietly scientific.',
    uiFamily: 'IBMPlexSans',
    mathFamily: 'IBMPlexMono',
    sample: 'The mass of the sun is 1.989 × 10³⁰ kg.',
  ),
  manuscript(
    label: 'Manuscript',
    description:
        'Literata. Cut for long reading: warm, beautiful, still easy at small sizes.',
    uiFamily: 'Literata',
    mathFamily: 'Literata',
    sample: 'The mass of the sun is 1.989 × 10³⁰ kg.',
  ),
  clearest(
    label: 'Clearest',
    description:
        'Atkinson Hyperlegible. Designed so 0, O, 1, l and I never trade places.',
    uiFamily: 'AtkinsonHyperlegible',
    mathFamily: 'AtkinsonHyperlegible',
    sample: 'The mass of the sun is 1.989 × 10³⁰ kg.',
  );

  const TypeVoice({
    required this.label,
    required this.description,
    required this.uiFamily,
    required this.mathFamily,
    required this.sample,
  });

  final String label;
  final String description;
  final String uiFamily;
  final String mathFamily;
  final String sample;
}

class AppTypefaces extends ThemeExtension<AppTypefaces> {
  const AppTypefaces({required this.uiFamily, required this.mathFamily});

  final String uiFamily;
  final String mathFamily;

  static const fallback = AppTypefaces(
    uiFamily: 'IBMPlexSans',
    mathFamily: 'IBMPlexMono',
  );

  static AppTypefaces of(BuildContext context) {
    return Theme.of(context).extension<AppTypefaces>() ?? fallback;
  }

  TextStyle math([TextStyle? base]) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: mathFamily,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  @override
  AppTypefaces copyWith({String? uiFamily, String? mathFamily}) {
    return AppTypefaces(
      uiFamily: uiFamily ?? this.uiFamily,
      mathFamily: mathFamily ?? this.mathFamily,
    );
  }

  @override
  AppTypefaces lerp(ThemeExtension<AppTypefaces>? other, double t) {
    if (other is! AppTypefaces) return this;
    return t < 0.5 ? this : other;
  }
}
