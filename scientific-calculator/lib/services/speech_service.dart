import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/app_language.dart';

/// Reads a string out loud. Screen readers get an announcement; everyone
/// else gets device text-to-speech when the platform supports it.
///
/// Voice language follows the selected [AppLanguage]. If that locale is
/// missing on the device, we fall back rather than crashing.
class SpeechService {
  FlutterTts? _tts;
  String? _appliedLocale;

  /// Preferred BCP-47 tag for [language] (e.g. `fr` → `fr-FR`).
  static String localeFor(AppLanguage language) =>
      _locales[language.code] ?? language.code;

  static const _locales = <String, String>{
    'en': 'en-US',
    'es': 'es-ES',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'pt': 'pt-PT',
    'it': 'it-IT',
    'nl': 'nl-NL',
    'da': 'da-DK',
    'sv': 'sv-SE',
    'nb': 'nb-NO',
    'fi': 'fi-FI',
    'pl': 'pl-PL',
    'cs': 'cs-CZ',
    'sk': 'sk-SK',
    'hu': 'hu-HU',
    'ro': 'ro-RO',
    'bg': 'bg-BG',
    'ru': 'ru-RU',
    'uk': 'uk-UA',
    'el': 'el-GR',
    'tr': 'tr-TR',
    'ar': 'ar-SA',
    'he': 'he-IL',
    'zh': 'zh-CN',
    'ja': 'ja-JP',
    'ko': 'ko-KR',
    'hi': 'hi-IN',
    'vi': 'vi-VN',
    'id': 'id-ID',
    'th': 'th-TH',
  };

  Future<void> setLanguage(AppLanguage language) async {
    try {
      _tts ??= FlutterTts();
      final resolved = await _resolveLocale(language);
      if (resolved == _appliedLocale) return;
      await _tts!.setLanguage(resolved);
      _appliedLocale = resolved;
    } catch (_) {
      // Tests and some web hosts have no TTS engine.
    }
  }

  Future<void> speak(String text, {AppLanguage? language}) async {
    final spoken = text.trim().isEmpty ? '0' : text.trim();
    final dir = (language?.rtl ?? false) ? TextDirection.rtl : TextDirection.ltr;
    try {
      SemanticsService.announce(spoken, dir); // ignore: deprecated_member_use
    } catch (_) {
      // Tests without a binding, and some hosts, have no announcer.
    }
    try {
      _tts ??= FlutterTts();
      if (language != null) {
        await setLanguage(language);
      }
      await _tts!.stop();
      await _tts!.setSpeechRate(0.45);
      await _tts!.speak(spoken);
    } catch (_) {
      // Tests and some web hosts have no TTS engine.
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  Future<String> _resolveLocale(AppLanguage language) async {
    final preferred = localeFor(language);
    final candidates = <String>[
      preferred,
      preferred.replaceAll('-', '_'),
      language.code,
      'en-US',
      'en_US',
      'en',
    ];
    final seen = <String>{};
    for (final tag in candidates) {
      if (!seen.add(tag)) continue;
      if (await _isAvailable(tag)) return tag;
    }
    return preferred;
  }

  Future<bool> _isAvailable(String locale) async {
    try {
      final result = await _tts!.isLanguageAvailable(locale);
      if (result == true || result == 1) return true;
      if (result is String && result.toLowerCase() == 'true') return true;
    } catch (_) {}
    return false;
  }
}
