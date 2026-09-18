import 'package:flutter/material.dart';

import '../design/typography.dart';
import '../expression/expression.dart';
import '../expression/parse/expression_parser.dart';
import '../expression/render/braille_renderer.dart';
import '../expression/render/speech_renderer.dart';
import '../input/braille/braille_math_parser.dart';
import '../input/camera/math_layout_reconstructor.dart';
import '../input/language/vocabularies.dart';
import '../input/voice/spoken_math_parser.dart';
import '../theme/app_theme.dart';
import '../widgets/math/math_view.dart';

/// The four ways into the same expression, made visible.
///
/// Voice, camera and braille each had a parser and a test suite and no
/// way for anyone to reach them — no button, no screen, nothing wired
/// into the app at all. Work nobody can get to is work nobody can judge.
///
/// This is deliberately not the finished feature. The microphone and the
/// camera need platform adapters that cannot run here, so those tabs take
/// what the recogniser *would* have produced and show what the app does
/// with it. That is the honest half: the language and layout work is
/// real and running; the hardware behind it is not yet attached.
class InputMethodsScreen extends StatefulWidget {
  const InputMethodsScreen({super.key, this.initial = InputMethod.voice});

  /// Which way in to open on. The calculator's microphone and camera
  /// buttons come straight here, so they land on the panel the button
  /// promised rather than on a menu.
  final InputMethod initial;

  @override
  State<InputMethodsScreen> createState() => _InputMethodsScreenState();
}

class _InputMethodsScreenState extends State<InputMethodsScreen> {
  late InputMethod _method = widget.initial;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    // No Scaffold: this is hosted by ModeScaffold, which supplies the
    // title and the back button that names where it returns to.
    return SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.m),
              child: SegmentedButton<InputMethod>(
                segments: [
                  for (final method in InputMethod.values)
                    ButtonSegment(
                      value: method,
                      icon: Icon(method.icon),
                      label: Text(method.label),
                    ),
                ],
                selected: {_method},
                showSelectedIcon: false,
                onSelectionChanged: (choice) =>
                    setState(() => _method = choice.first),
              ),
            ),
            Expanded(
              child: switch (_method) {
                InputMethod.voice => const _VoicePanel(),
                InputMethod.camera => const _CameraPanel(),
                InputMethod.braille => const _BraillePanel(),
              },
            ),
            Container(
              width: double.infinity,
              color: palette.groupedBackground,
              padding: const EdgeInsets.all(Space.m),
              child: Text(
                _method.caveat,
                style: AppType.footnote.copyWith(color: palette.secondaryLabel),
              ),
            ),
          ],
        ),
    );
  }
}

/// The ways in, other than the keypad.
enum InputMethod {
  voice(
    label: 'Voice',
    icon: Icons.mic_outlined,
    caveat: 'The microphone needs a platform adapter that is not attached '
        'yet. The words below are what a recogniser would hand over; '
        'everything after that point is running for real.',
  ),
  camera(
    label: 'Camera',
    icon: Icons.photo_camera_outlined,
    caveat: 'The camera needs a platform adapter that is not attached yet. '
        'The glyphs below stand in for what on-device text recognition '
        'would return, positions and all.',
  ),
  braille(
    label: 'Braille',
    icon: Icons.touch_app_outlined,
    caveat: 'Braille needs no adapter: a display sends characters like any '
        'keyboard. Type Nemeth here in Unicode braille or in ASCII '
        'braille and it is read live.',
  );

  const InputMethod({
    required this.label,
    required this.icon,
    required this.caveat,
  });

  final String label;
  final IconData icon;
  final String caveat;
}

/// Shows a spoken phrase becoming an expression, in any shipped language.
class _VoicePanel extends StatefulWidget {
  const _VoicePanel();

  @override
  State<_VoicePanel> createState() => _VoicePanelState();
}

class _VoicePanelState extends State<_VoicePanel> {
  static const _samples = {
    'en': 'twenty five plus seventeen',
    'de': 'fünfundzwanzig plus siebzehn',
    'fr': 'quatre-vingt-dix-neuf plus un',
    'es': 'raíz cuadrada de dieciséis',
    'ru': 'квадратный корень из шестнадцати',
    'da': 'femoghalvfjerds minus femogtyve',
    'sv': 'tjugofem plus sjutton',
  };

  String _language = 'en';
  late String _heard = _samples['en']!;

  // Owned by the state rather than rebuilt inline: a controller recreated
  // on every build throws away the selection, which puts the caret back
  // at the end after each keystroke.
  late final _transcript = TextEditingController(text: _heard);

  @override
  void dispose() {
    _transcript.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final vocabulary = shippedMathVocabularies.vocabularies[_language]!;

    ExpressionNode? parsed;
    String? problem;
    try {
      parsed = SpokenMathParser(vocabulary: vocabulary).parse(_heard).expression;
    } on SpokenMathError catch (error) {
      problem = error.message;
    }

    return ListView(
      padding: const EdgeInsets.all(Space.m),
      children: [
        Wrap(
          spacing: Space.s,
          runSpacing: Space.s,
          children: [
            for (final entry in shippedMathVocabularies.vocabularies.entries)
              ChoiceChip(
                label: Text(entry.value.displayName),
                selected: _language == entry.key,
                onSelected: (_) => setState(() {
                  _language = entry.key;
                  _heard = _samples[entry.key]!;
                  _transcript.text = _heard;
                }),
              ),
          ],
        ),
        const SizedBox(height: Space.m),
        _Heading(label: 'Heard'),
        TextField(
          key: const Key('voice-transcript'),
          controller: _transcript,
          onSubmitted: (value) => setState(() => _heard = value),
          decoration: const InputDecoration(
            helperText: 'Edit and press enter to re-read it',
          ),
        ),
        const SizedBox(height: Space.l),
        _Heading(label: 'Understood as'),
        if (problem != null)
          Text(problem,
              style: AppType.body.copyWith(color: palette.errorSurface.foreground))
        else
          _Result(expression: parsed!),
      ],
    );
  }
}

/// Shows recognised glyphs being reassembled into two-dimensional maths.
class _CameraPanel extends StatefulWidget {
  const _CameraPanel();

  @override
  State<_CameraPanel> createState() => _CameraPanelState();
}

class _CameraPanelState extends State<_CameraPanel> {
  static const _scenes = {
    'x² + 5x + 6 = 0': [
      RecognizedGlyph(text: 'x', left: 10, top: 40, width: 14, height: 20),
      RecognizedGlyph(text: '2', left: 25, top: 30, width: 8, height: 11),
      RecognizedGlyph(text: '+', left: 40, top: 44, width: 12, height: 12),
      RecognizedGlyph(text: '5', left: 58, top: 40, width: 12, height: 20),
      RecognizedGlyph(text: 'x', left: 72, top: 40, width: 14, height: 20),
      RecognizedGlyph(text: '+', left: 92, top: 44, width: 12, height: 12),
      RecognizedGlyph(text: '6', left: 110, top: 40, width: 12, height: 20),
    ],
    '3x - 7': [
      RecognizedGlyph(text: '3', left: 10, top: 40, width: 12, height: 20),
      RecognizedGlyph(text: 'x', left: 24, top: 40, width: 14, height: 20),
      RecognizedGlyph(text: '-', left: 44, top: 48, width: 12, height: 3),
      RecognizedGlyph(text: '7', left: 62, top: 40, width: 12, height: 20),
    ],
  };

  String _scene = 'x² + 5x + 6 = 0';

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final result =
        const MathLayoutReconstructor().reconstruct(_scenes[_scene]!);

    ExpressionNode? parsed;
    try {
      parsed = const ExpressionParser().parse(result.normalizedSource);
    } on ParseError {
      parsed = null;
    }

    return ListView(
      padding: const EdgeInsets.all(Space.m),
      children: [
        Wrap(
          spacing: Space.s,
          children: [
            for (final name in _scenes.keys)
              ChoiceChip(
                label: Text(name),
                selected: _scene == name,
                onSelected: (_) => setState(() => _scene = name),
              ),
          ],
        ),
        const SizedBox(height: Space.m),
        _Heading(label: 'Glyphs recognised'),
        Text(
          _scenes[_scene]!
              .map((g) => '${g.text} at ${g.left.toInt()},${g.top.toInt()}')
              .join('   '),
          style: AppType.mono.copyWith(color: palette.secondaryLabel),
        ),
        const SizedBox(height: Space.l),
        _Heading(label: 'Layout reconstructed'),
        Text(result.normalizedSource, style: AppType.mono),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: Space.s),
          for (final warning in result.warnings)
            Text('• $warning',
                style: AppType.footnote
                    .copyWith(color: palette.errorSurface.foreground)),
        ],
        const SizedBox(height: Space.l),
        if (parsed != null) ...[
          _Heading(label: 'As an expression'),
          _Result(expression: parsed),
        ],
      ],
    );
  }
}

/// Reads Nemeth braille live, and writes it back.
class _BraillePanel extends StatefulWidget {
  const _BraillePanel();

  @override
  State<_BraillePanel> createState() => _BraillePanelState();
}

class _BraillePanelState extends State<_BraillePanel> {
  // ASCII braille for ?1/2#+3 — a half plus three.
  String _input = '?1/2#+3';

  // Held here for the same reason as the transcript: this one reads on
  // every keystroke, so a rebuilt controller would drag the caret to the
  // end mid-word — and a braille display is a keyboard, typing into it.
  late final _field = TextEditingController(text: _input);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    ExpressionNode? parsed;
    String? problem;
    try {
      parsed = const BrailleMathParser().parse(_input);
    } on BrailleParseError catch (error) {
      problem = error.message;
    } on FormatException catch (error) {
      problem = error.message;
    }

    return ListView(
      padding: const EdgeInsets.all(Space.m),
      children: [
        _Heading(label: 'Braille in'),
        TextField(
          key: const Key('braille-input'),
          controller: _field,
          style: AppType.mono,
          onChanged: (value) => setState(() => _input = value),
          decoration: const InputDecoration(
            helperText: 'Unicode braille patterns or ASCII braille',
          ),
        ),
        const SizedBox(height: Space.l),
        if (problem != null)
          Text(problem,
              style: AppType.body.copyWith(color: palette.errorSurface.foreground))
        else ...[
          _Heading(label: 'Understood as'),
          _Result(expression: parsed!),
          const SizedBox(height: Space.l),
          _Heading(label: 'Written back as braille'),
          Text(
            const BrailleRenderer().renderUnicode(parsed),
            style: AppType.displayResult.copyWith(fontSize: 28),
          ),
          const SizedBox(height: Space.s),
          Text(
            const BrailleRenderer().renderAscii(parsed),
            style: AppType.mono.copyWith(color: palette.secondaryLabel),
          ),
        ],
      ],
    );
  }
}

/// The same expression drawn, and read aloud, from the one tree.
class _Result extends StatelessWidget {
  const _Result({required this.expression});

  final ExpressionNode expression;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 80,
          child: Align(
            alignment: Alignment.centerLeft,
            child: MathView(expression: expression),
          ),
        ),
        const SizedBox(height: Space.s),
        Text(
          // The same renderer that supplies the screen-reader label and
          // read-aloud, so there is no second description to keep in step.
          'Reads aloud as: ${const SpeechRenderer().render(expression)}',
          style: AppType.footnote.copyWith(color: palette.secondaryLabel),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: AppType.footnote.copyWith(
            color: palette.secondaryLabel,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
