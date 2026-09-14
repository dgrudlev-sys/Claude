import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads a string out loud. Screen readers get an announcement; everyone
/// else gets device text-to-speech when the platform supports it.
class SpeechService {
  FlutterTts? _tts;

  Future<void> speak(String text) async {
    final spoken = text.trim().isEmpty ? '0' : text.trim();
    SemanticsService.announce(spoken, TextDirection.ltr); // ignore: deprecated_member_use
    try {
      _tts ??= FlutterTts();
      await _tts!.stop();
      await _tts!.setSpeechRate(0.45);
      await _tts!.speak(spoken);
    } catch (_) {
      // Tests and some web hosts have no TTS engine.
    }
  }
}
