import 'package:flutter/material.dart';

import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';
import '../theme/color_story.dart';
import '../theme/type_voice.dart';

class ColorStoryPicker extends StatelessWidget {
  const ColorStoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final ColorStory value;
  final ValueChanged<ColorStory> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in ColorStoryGroup.values) ...[
          if (group != ColorStoryGroup.nature) const SizedBox(height: AppMetrics.space4),
          Text(group.label, style: Theme.of(context).textTheme.titleMedium),
          if (group == ColorStoryGroup.colourVision)
            Padding(
              padding: const EdgeInsets.only(top: AppMetrics.space1, bottom: AppMetrics.space2),
              child: Text(
                'Each look is built so equals, operators, and the field stay distinct when that hue is missing or weak. Borders and labels still carry the meaning.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            const SizedBox(height: AppMetrics.space2),
          for (final story in ColorStory.inGroup(group)) ...[
            _StoryCard(
              story: story,
              selected: story == value,
              enabled: enabled,
              onTap: () => onChanged(story),
            ),
            const SizedBox(height: AppMetrics.space2),
          ],
        ],
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ColorStory story;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CalculatorPalette>()!;
    final t = story.tokens;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '${story.label}. ${story.description}',
      child: Material(
        color: t.cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
          side: BorderSide(
            color: selected ? palette.selectedBorder : t.cardHairline,
            width: selected ? 3 : AppMetrics.hairline,
          ),
        ),
        child: InkWell(
          key: Key('color-story-${story.name}'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(AppMetrics.space2),
            child: Row(
              children: [
                _PaletteSwatches(tokens: t),
                const SizedBox(width: AppMetrics.space2),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: story.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const TextSpan(text: '  '),
                        TextSpan(
                          text: story.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteSwatches extends StatelessWidget {
  const _PaletteSwatches({required this.tokens});

  final ColorStoryTokens tokens;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final chips = <(Color, String)>[
      (tokens.dominant, 'field'),
      (tokens.secondary, 'supporting'),
      (tokens.accent, 'highlight'),
      (tokens.onDominant, 'text'),
    ];
    return Semantics(
      label: 'Palette: field, supporting, highlight, text',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: AppMetrics.space1),
            Tooltip(
              message: chips[i].$2,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: chips[i].$1,
                  borderRadius: BorderRadius.circular(AppMetrics.space2),
                  border: Border.all(color: const Color(0x59FFFFFF), width: AppMetrics.hairline),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TypeVoicePicker extends StatelessWidget {
  const TypeVoicePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TypeVoice value;
  final ValueChanged<TypeVoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<TypeVoice>(
      groupValue: value,
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
      child: Column(
        children: [
          for (final voice in TypeVoice.values)
            RadioListTile<TypeVoice>(
              key: Key('type-voice-${voice.name}'),
              value: voice,
              title: Text(
                voice.label,
                style: TextStyle(
                  fontFamily: voice.uiFamily,
                  fontWeight: FontWeight.w600,
                  height: AppMetrics.titleHeight,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppMetrics.space1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voice.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppMetrics.space1),
                    Text(
                      voice.sample,
                      style: TextStyle(
                        fontFamily: voice.uiFamily,
                        height: AppMetrics.bodyHeight,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
