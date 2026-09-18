/// Boundaries between this app's logic and the native speech and vision
/// services.
///
/// Everything behind these interfaces is a platform call that can't run
/// in a unit test — a microphone, a camera, a TTS engine. Everything in
/// front of them is ours and is fully tested. Keeping the seam explicit
/// means the untestable part stays a handful of thin adapters instead of
/// spreading through the app.
///
/// **Where voices and languages come from:** not from us. Both speech
/// engines are the operating system's, so the available languages are
/// whatever that device has installed — `AVSpeechSynthesizer` and
/// `SFSpeechRecognizer` on iOS, `TextToSpeech` and `SpeechRecognizer`
/// (usually Google's) on Android. That's why these interfaces expose
/// enumeration and availability checks rather than a fixed list: the app
/// has to ask the device and adapt, including offering to install a
/// missing language rather than silently failing.
library;

import '../camera/math_layout_reconstructor.dart';

/// A language the device can recognise speech in.
class SpeechLocale {
  const SpeechLocale({
    required this.tag,
    required this.displayName,
    this.supportsOnDevice = false,
  });

  /// BCP-47 tag, e.g. "en-US", "da-DK".
  final String tag;
  final String displayName;

  /// Whether this locale can be recognised without a network round trip.
  /// Offline models are a per-device download, so this varies between two
  /// phones running the same OS version — it can't be assumed.
  final bool supportsOnDevice;
}

/// A voice the device can speak with.
class SpeechVoice {
  const SpeechVoice({
    required this.id,
    required this.name,
    required this.localeTag,
    this.isEnhanced = false,
  });

  final String id;
  final String name;
  final String localeTag;

  /// iOS "enhanced"/"premium" and Android high-quality voices, which the
  /// user downloads separately and which sound markedly better.
  final bool isEnhanced;
}

class SpeechTranscript {
  const SpeechTranscript({
    required this.text,
    required this.isFinal,
    this.confidence = 1.0,
  });

  final String text;

  /// Recognisers stream partial guesses before settling. Only a final
  /// result should be committed to a calculation.
  final bool isFinal;
  final double confidence;
}

/// Wraps the platform speech recogniser (`speech_to_text`).
abstract class SpeechRecognitionPort {
  Future<bool> initialize();

  /// What this particular device can understand — never a fixed list.
  Future<List<SpeechLocale>> availableLocales();

  Future<void> listen({
    required String localeTag,
    required void Function(SpeechTranscript) onResult,

    /// Ask for on-device recognition. Honoured only where the offline
    /// model is installed; the adapter reports what actually happened
    /// rather than pretending.
    bool preferOnDevice = true,
  });

  Future<void> stop();

  bool get isListening;
}

/// Wraps the platform speech synthesiser (`flutter_tts`).
abstract class TextToSpeechPort {
  /// Voices installed on this device, across all languages.
  Future<List<SpeechVoice>> availableVoices();

  /// Whether the device can speak a given language at all, so the UI can
  /// offer to install it instead of failing silently.
  Future<bool> isLanguageAvailable(String localeTag);

  Future<void> speak(
    String text, {
    String? voiceId,
    String? localeTag,
    double rate,
    double pitch,
  });

  Future<void> stop();
}

/// Wraps on-device text recognition (ML Kit).
///
/// Returns flat text with positions — reconstructing the maths from that
/// is [MathLayoutReconstructor]'s job, because no text recogniser
/// understands superscripts or fraction bars.
abstract class TextRecognitionPort {
  /// [imagePath] is a file the camera just wrote.
  Future<List<RecognizedGlyph>> recognizeFile(String imagePath);
}
