import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/theme/color_story.dart';
import 'package:scientific_calculator/theme/type_voice.dart';

import 'test_helpers.dart';

void main() {
  test('each look is an 80-15-5 split with a single highlight', () {
    for (final story in ColorStory.values) {
      expect(story.dominant, isNot(story.accent), reason: story.name);
      expect(story.secondary, isNot(story.accent), reason: story.name);
      expect(story.tokens.numberKey, isNot(story.accent), reason: story.name);
      expect(story.keypad.equalsButton, story.accent);
      expect(story.keypad.displayBackground, story.dominant);
    }
  });

  test('colour-vision looks cover every daltonism type', () {
    expect(ColorStory.inGroup(ColorStoryGroup.colourVision).length, 8);
    expect(ColorStory.protanopia.accent, const Color(0xFFF0E442));
    expect(ColorStory.tritanopia.accent, const Color(0xFFD55E00));
    expect(ColorStory.tritanopia.accent, isNot(const Color(0xFFF0E442)));
    expect(ColorStory.achromatopsia.accent, const Color(0xFFFFFFFF));
    expect(ColorStory.blueCone.accent, const Color(0xFF56B4E9));
    expect(ColorStory.blueCone.accent, isNot(const Color(0xFFF0E442)));
    for (final story in ColorStory.inGroup(ColorStoryGroup.colourVision)) {
      expect(story.keypad.equalsButton, isNot(story.keypad.operatorButton), reason: story.name);
      expect(story.keypad.clearButton, isNot(story.keypad.equalsButton), reason: story.name);
    }
  });

  test('type voices use distinct families for lab vs page vs clearest', () {
    expect(TypeVoice.laboratory.uiFamily, 'IBMPlexSans');
    expect(TypeVoice.laboratory.mathFamily, 'IBMPlexMono');
    expect(TypeVoice.manuscript.uiFamily, 'Literata');
    expect(TypeVoice.clearest.uiFamily, 'AtkinsonHyperlegible');
  });

  testWidgets('settings can pick a nature look, a type voice, and a colour-vision look', (tester) async {
    final settings = await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Look'), findsOneWidget);
    expect(find.textContaining('Panther'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('color-story-africa')));
    await tester.pumpAndSettle();
    expect(settings.colorStory, ColorStory.africa);

    await tester.ensureVisible(find.byKey(const Key('type-voice-clearest')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('type-voice-clearest')));
    await tester.pumpAndSettle();
    expect(settings.typeVoice, TypeVoice.clearest);

    await tester.ensureVisible(find.byKey(const Key('color-story-tritanopia')));
    await tester.pumpAndSettle();
    expect(find.text('Colour vision'), findsOneWidget);
    expect(find.textContaining('Protanopia'), findsWidgets);
    await tester.tap(find.byKey(const Key('color-story-tritanopia')));
    await tester.pumpAndSettle();
    expect(settings.colorStory, ColorStory.tritanopia);
  });
}
