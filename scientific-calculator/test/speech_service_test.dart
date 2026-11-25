import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/l10n/app_language.dart';
import 'package:scientific_calculator/services/speech_service.dart';

void main() {
  test('maps every supported language to a TTS locale', () {
    const expected = {
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

    for (final lang in AppLanguage.supported) {
      expect(expected.containsKey(lang.code), isTrue, reason: lang.code);
      expect(SpeechService.localeFor(lang), expected[lang.code], reason: lang.code);
    }
  });

  test('speak does not throw when the TTS engine is missing', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final speech = SpeechService();
    await speech.setLanguage(AppLanguage.byCode('fr'));
    await speech.speak('bonjour', language: AppLanguage.byCode('fr'));
  });
}
