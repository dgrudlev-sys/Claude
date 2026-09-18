import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/input/platform/speech_ports.dart';
import 'package:scientific_calculator/input/voice/math_speaker.dart';

/// Stands in for the platform TTS engine, capturing what would have been
/// spoken. The real adapter wraps flutter_tts and can't run in a test —
/// this is exactly the seam the port exists to create.
class FakeTts implements TextToSpeechPort {
  final List<String> spoken = [];
  String? lastVoiceId;
  String? lastLocaleTag;
  double? lastRate;
  bool stopped = false;

  List<SpeechVoice> voices = const [
    SpeechVoice(id: 'en-us-1', name: 'Samantha', localeTag: 'en-US', isEnhanced: true),
    SpeechVoice(id: 'da-dk-1', name: 'Sara', localeTag: 'da-DK'),
  ];

  @override
  Future<List<SpeechVoice>> availableVoices() async => voices;

  @override
  Future<bool> isLanguageAvailable(String localeTag) async =>
      voices.any((v) => v.localeTag == localeTag);

  @override
  Future<void> speak(
    String text, {
    String? voiceId,
    String? localeTag,
    double rate = 0.5,
    double pitch = 1.0,
  }) async {
    spoken.add(text);
    lastVoiceId = voiceId;
    lastLocaleTag = localeTag;
    lastRate = rate;
  }

  @override
  Future<void> stop() async => stopped = true;
}

void main() {
  const parser = ExpressionParser();

  group('reading back what is written down', () {
    test('speaks the expression currently on screen', () async {
      final tts = FakeTts();
      final speaker = MathSpeaker(tts);

      await speaker.speakExpression(parser.parse('sqrt(x^2+1)'));

      expect(tts.spoken.single, 'square root of x squared plus 1, end root');
    });

    test('maths is spoken more slowly than prose', () async {
      final tts = FakeTts();
      await MathSpeaker(tts).speakExpression(parser.parse('1+1'));
      expect(tts.lastRate, lessThan(0.5));
    });

    test('a chosen voice is passed through to the engine', () async {
      final tts = FakeTts();
      await MathSpeaker(tts)
          .speakExpression(parser.parse('1+1'), voiceId: 'en-us-1', localeTag: 'en-US');
      expect(tts.lastVoiceId, 'en-us-1');
      expect(tts.lastLocaleTag, 'en-US');
    });
  });

  group('speaking results', () {
    test('an exact fraction is spoken as a fraction, not a decimal', () async {
      final tts = FakeTts();
      final speaker = MathSpeaker(tts);
      final expression = parser.parse('1/2');

      await speaker.speakResult(
        expression,
        RationalValue(BigInt.one, BigInt.two),
      );

      // The point of keeping exactness is that it survives to the ear too.
      expect(tts.spoken.single, contains('equals one half'));
      expect(tts.spoken.single, isNot(contains('0 point 5')));
    });

    test('an improper fraction is spoken as a mixed number', () async {
      final tts = FakeTts();
      await MathSpeaker(tts).speakResult(
        parser.parse('7/2'),
        RationalValue(BigInt.from(7), BigInt.two),
      );
      expect(tts.spoken.single, contains('3 and one half'));
    });

    test('a whole number is spoken plainly', () async {
      final tts = FakeTts();
      await MathSpeaker(tts).speakResult(parser.parse('2+2'), RationalValue.fromInt(4));
      expect(tts.spoken.single, '2 plus 2, equals 4');
    });

    test('an approximate result is trimmed, not read to 15 digits', () async {
      final tts = FakeTts();
      await MathSpeaker(tts)
          .speakResult(parser.parse('sqrt(2)'), const RealValue(1.4142135623730951));
      expect(tts.spoken.single, contains('1 point 4 1 4 2 1 3 5 6 2'));
    });

    test('a complex result names its imaginary part', () async {
      final tts = FakeTts();
      await MathSpeaker(tts).speakResult(
        parser.parse('sqrt(-4)'),
        ComplexValue(RationalValue.zero, RationalValue.fromInt(2)),
      );
      expect(tts.spoken.single, contains('0 plus 2 i'));
    });
  });

  group('device capability, not assumption', () {
    test('available voices come from the device', () async {
      final tts = FakeTts();
      final voices = await tts.availableVoices();
      expect(voices.map((v) => v.localeTag), containsAll(['en-US', 'da-DK']));
      expect(voices.firstWhere((v) => v.isEnhanced).name, 'Samantha');
    });

    test('a missing language is reported rather than silently failing', () async {
      final tts = FakeTts();
      expect(await tts.isLanguageAvailable('en-US'), isTrue);
      expect(await tts.isLanguageAvailable('ja-JP'), isFalse);
    });
  });

  test('stopping speech reaches the engine', () async {
    final tts = FakeTts();
    await MathSpeaker(tts).stop();
    expect(tts.stopped, isTrue);
  });
}
