import '../platform/speech_ports.dart';
import 'math_vocabulary.dart';

/// How well a given language works, all things considered.
enum LanguageSupportLevel {
  /// Speaking and listening both work, including the maths vocabulary.
  full,

  /// The device can speak and listen, but this app's maths layer has no
  /// vocabulary for the language — voice features fall back to English.
  deviceOnly,

  /// The device itself is missing voices or recognition for it.
  needsDeviceSetup,

  /// Nothing works for this language on this device.
  unavailable,
}

/// The combined answer to "will voice features work if I pick this
/// language?", drawn from what the device reports and what this app
/// actually implements.
class LanguageSupport {
  const LanguageSupport({
    required this.localeTag,
    required this.displayName,
    required this.canSpeak,
    required this.canListen,
    required this.canListenOffline,
    required this.mathVocabularySupported,
    required this.voices,
  });

  final String localeTag;
  final String displayName;

  /// A text-to-speech voice exists for this language on this device.
  final bool canSpeak;

  /// The device's recogniser accepts this language.
  final bool canListen;

  /// Recognition works without a network round trip. Offline models are
  /// a per-device download, so this varies between two identical phones.
  final bool canListenOffline;

  /// This app can turn spoken words in this language into maths, and say
  /// results back in it.
  final bool mathVocabularySupported;

  final List<SpeechVoice> voices;

  bool get hasEnhancedVoice => voices.any((v) => v.isEnhanced);

  LanguageSupportLevel get level {
    if (!canSpeak && !canListen) return LanguageSupportLevel.unavailable;
    if (!canSpeak || !canListen) return LanguageSupportLevel.needsDeviceSetup;
    if (!mathVocabularySupported) return LanguageSupportLevel.deviceOnly;
    return LanguageSupportLevel.full;
  }

  /// One line for the picker row — says what the user gets, not what the
  /// implementation is.
  String get summary => switch (level) {
        LanguageSupportLevel.full => 'Voice input and spoken results available',
        LanguageSupportLevel.deviceOnly =>
          'Spoken results available in English only',
        LanguageSupportLevel.needsDeviceSetup =>
          canSpeak ? 'Spoken results only' : 'Voice input only',
        LanguageSupportLevel.unavailable => 'Not available on this device',
      };

  /// The specific things that will not work, for the notice shown when a
  /// language is selected. Empty when everything works.
  List<String> get caveats {
    final notes = <String>[];

    if (!canSpeak) {
      notes.add(
        'This device has no $displayName voice installed, so results cannot be '
        'read aloud. You can add one in your device settings.',
      );
    }
    if (!canListen) {
      notes.add(
        'This device cannot recognise spoken $displayName, so voice input is '
        'unavailable.',
      );
    } else if (!canListenOffline) {
      notes.add(
        'Speech recognition for $displayName needs an internet connection on '
        'this device. Download the offline language pack in your device '
        'settings to use it without one.',
      );
    }
    if (canSpeak && canListen && !mathVocabularySupported) {
      notes.add(
        'Spoken maths is not yet translated into $displayName. Voice input and '
        'read-back will use English.',
      );
    }
    return notes;
  }
}

/// Answers language questions by asking the device, then checking what
/// this app supports — never by assuming a fixed list.
class LanguageSupportService {
  const LanguageSupportService({
    required this.tts,
    required this.speech,
    this.vocabularies = const MathVocabularyRegistry(),
  });

  final TextToSpeechPort tts;
  final SpeechRecognitionPort speech;
  final MathVocabularyRegistry vocabularies;

  /// Every language that works for at least one voice feature on this
  /// device, best-supported first so the picker leads with what works.
  Future<List<LanguageSupport>> availableLanguages() async {
    final voices = await tts.availableVoices();
    final locales = await speech.availableLocales();

    final byLanguage = <String, List<SpeechVoice>>{};
    for (final voice in voices) {
      byLanguage.putIfAbsent(voice.localeTag, () => []).add(voice);
    }

    final tags = <String>{...byLanguage.keys, ...locales.map((l) => l.tag)};
    final result = <LanguageSupport>[];

    for (final tag in tags) {
      final locale = locales.where((l) => l.tag == tag).firstOrNull;
      final localeVoices = byLanguage[tag] ?? const <SpeechVoice>[];
      result.add(LanguageSupport(
        localeTag: tag,
        displayName: locale?.displayName ?? localeVoices.firstOrNull?.localeTag ?? tag,
        canSpeak: localeVoices.isNotEmpty,
        canListen: locale != null,
        canListenOffline: locale?.supportsOnDevice ?? false,
        mathVocabularySupported: vocabularies.supportsLanguage(tag),
        voices: localeVoices,
      ));
    }

    result.sort((a, b) {
      final byLevel = a.level.index.compareTo(b.level.index);
      if (byLevel != 0) return byLevel;
      return a.displayName.compareTo(b.displayName);
    });
    return result;
  }

  /// The report for one language, for the notice shown on selection.
  Future<LanguageSupport> describe(String localeTag) async {
    final all = await availableLanguages();
    return all.firstWhere(
      (l) => l.localeTag == localeTag,
      orElse: () => LanguageSupport(
        localeTag: localeTag,
        displayName: localeTag,
        canSpeak: false,
        canListen: false,
        canListenOffline: false,
        mathVocabularySupported: vocabularies.supportsLanguage(localeTag),
        voices: const [],
      ),
    );
  }
}
