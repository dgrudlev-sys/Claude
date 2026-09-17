import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/input/language/language_support.dart';
import 'package:scientific_calculator/input/platform/speech_ports.dart';

import 'math_speaker_test.dart' show FakeTts;

/// Stands in for the device recogniser. Two phones running the same OS
/// return different lists here, which is the whole reason the app has to
/// ask rather than assume.
class FakeSpeechRecognition implements SpeechRecognitionPort {
  FakeSpeechRecognition(this.locales);

  final List<SpeechLocale> locales;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<List<SpeechLocale>> availableLocales() async => locales;

  @override
  Future<void> listen({
    required String localeTag,
    required void Function(SpeechTranscript) onResult,
    bool preferOnDevice = true,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  bool get isListening => false;
}

void main() {
  LanguageSupportService serviceWith({
    List<SpeechVoice> voices = const [],
    List<SpeechLocale> locales = const [],
  }) {
    final tts = FakeTts()..voices = voices;
    return LanguageSupportService(
      tts: tts,
      speech: FakeSpeechRecognition(locales),
    );
  }

  group('English: everything works', () {
    test('reports full support with no caveats', () async {
      final service = serviceWith(
        voices: const [
          SpeechVoice(id: 'en1', name: 'Samantha', localeTag: 'en-US', isEnhanced: true),
        ],
        locales: const [
          SpeechLocale(tag: 'en-US', displayName: 'English (US)', supportsOnDevice: true),
        ],
      );

      final english = await service.describe('en-US');
      expect(english.level, LanguageSupportLevel.full);
      expect(english.summary, 'Voice input and spoken results available');
      expect(english.caveats, isEmpty);
      expect(english.hasEnhancedVoice, isTrue);
    });
  });

  group('a shipped maths vocabulary changes what the picker promises', () {
    test('German is promised in full, because we ship German maths', () async {
      final service = serviceWith(
        voices: const [SpeechVoice(id: 'de1', name: 'Anna', localeTag: 'de-DE')],
        locales: const [
          SpeechLocale(tag: 'de-DE', displayName: 'German', supportsOnDevice: true),
        ],
      );

      final german = await service.describe('de-DE');
      expect(german.mathVocabularySupported, isTrue);
      expect(german.level, LanguageSupportLevel.full);
      // No "falls back to English" note, because it does not.
      expect(german.caveats, isEmpty);
    });
  });

  group('a language the device supports but our maths layer does not', () {
    test('is honest that maths falls back to English', () async {
      final service = serviceWith(
        voices: const [SpeechVoice(id: 'nl1', name: 'Xander', localeTag: 'nl-NL')],
        locales: const [
          SpeechLocale(tag: 'nl-NL', displayName: 'Dutch', supportsOnDevice: true),
        ],
      );

      final dutch = await service.describe('nl-NL');
      expect(dutch.canSpeak, isTrue);
      expect(dutch.canListen, isTrue);
      // The device is fully capable; we are not.
      expect(dutch.mathVocabularySupported, isFalse);
      expect(dutch.level, LanguageSupportLevel.deviceOnly);
      expect(
        dutch.caveats.single,
        contains('not yet translated into Dutch'),
      );
    });
  });

  group('device gaps are named specifically', () {
    test('no voice installed says so and points at device settings', () async {
      final service = serviceWith(
        locales: const [
          SpeechLocale(tag: 'fr-FR', displayName: 'French', supportsOnDevice: true),
        ],
      );

      final french = await service.describe('fr-FR');
      expect(french.canSpeak, isFalse);
      expect(french.level, LanguageSupportLevel.needsDeviceSetup);
      expect(french.summary, 'Voice input only');
      expect(french.caveats.first, contains('no French voice installed'));
      expect(french.caveats.first, contains('device settings'));
    });

    test('recognition present but online-only is called out', () async {
      final service = serviceWith(
        voices: const [SpeechVoice(id: 'de1', name: 'Anna', localeTag: 'de-DE')],
        locales: const [
          SpeechLocale(tag: 'de-DE', displayName: 'German', supportsOnDevice: false),
        ],
      );

      final german = await service.describe('de-DE');
      expect(german.canListenOffline, isFalse);
      expect(
        german.caveats.any((c) => c.contains('needs an internet connection')),
        isTrue,
      );
    });

    test('a language the device knows nothing about is unavailable', () async {
      final service = serviceWith();
      final japanese = await service.describe('ja-JP');
      expect(japanese.level, LanguageSupportLevel.unavailable);
      expect(japanese.summary, 'Not available on this device');
    });
  });

  group('the language picker', () {
    test('lists everything the device offers, best support first', () async {
      final service = serviceWith(
        voices: const [
          SpeechVoice(id: 'nl1', name: 'Xander', localeTag: 'nl-NL'),
          SpeechVoice(id: 'en1', name: 'Samantha', localeTag: 'en-US'),
        ],
        locales: const [
          SpeechLocale(tag: 'nl-NL', displayName: 'Dutch', supportsOnDevice: true),
          SpeechLocale(tag: 'en-US', displayName: 'English (US)', supportsOnDevice: true),
          SpeechLocale(tag: 'pl-PL', displayName: 'Polish', supportsOnDevice: false),
        ],
      );

      final all = await service.availableLanguages();

      expect(all.map((l) => l.localeTag), containsAll(['en-US', 'nl-NL', 'pl-PL']));
      // English has a maths vocabulary and leads; Dutch is device-only;
      // Polish, which has no voice at all, trails.
      expect(all.first.localeTag, 'en-US');
      expect(all.last.localeTag, 'pl-PL');
    });

    test('a language with only a voice still appears, with its limits', () async {
      final service = serviceWith(
        voices: const [SpeechVoice(id: 'es1', name: 'Monica', localeTag: 'es-ES')],
      );

      final spanish = await service.describe('es-ES');
      expect(spanish.canSpeak, isTrue);
      expect(spanish.canListen, isFalse);
      expect(spanish.summary, 'Spoken results only');
      expect(spanish.caveats.any((c) => c.contains('cannot recognise spoken')), isTrue);
    });
  });

  group('locale codes', () {
    test('regional variants share a maths vocabulary', () async {
      final service = serviceWith(
        voices: const [SpeechVoice(id: 'gb1', name: 'Daniel', localeTag: 'en-GB')],
        locales: const [
          SpeechLocale(tag: 'en-GB', displayName: 'English (UK)', supportsOnDevice: true),
        ],
      );
      final british = await service.describe('en-GB');
      expect(british.mathVocabularySupported, isTrue);
      expect(british.level, LanguageSupportLevel.full);
    });
  });
}
