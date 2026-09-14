import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/explanation.dart';
import '../l10n/l10n.dart';
import '../theme/app_metrics.dart';
import '../theme/type_voice.dart';

/// Collapsed-by-default walkthrough: a sentence, then the matching symbols.
class StepsPanel extends StatefulWidget {
  const StepsPanel({
    super.key,
    required this.explanation,
    this.initiallyExpanded = false,
  });

  final Explanation explanation;
  final bool initiallyExpanded;

  @override
  State<StepsPanel> createState() => _StepsPanelState();
}

class _StepsPanelState extends State<StepsPanel> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (widget.explanation.isEmpty) return const SizedBox.shrink();
    final strings = L10n.stringsOf(context);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: strings.howWeGotThis,
      child: Card(
        margin: const EdgeInsets.only(top: AppMetrics.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: const Key('how-we-got-this'),
              onTap: () {
                final next = !_open;
                setState(() => _open = next);
                if (next) {
                  SemanticsService.announce(widget.explanation.spoken, TextDirection.ltr); // ignore: deprecated_member_use
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(AppMetrics.padCard),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: AppMetrics.iconSize,
                      height: AppMetrics.iconSize,
                      child: Icon(Icons.menu_book_outlined, size: AppMetrics.iconSize),
                    ),
                    const SizedBox(width: AppMetrics.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.howWeGotThis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: AppMetrics.titleHeight,
                              letterSpacing: AppMetrics.titleTracking,
                            ),
                          ),
                          const SizedBox(height: AppMetrics.space1),
                          Text(
                            strings.howWeGotThisHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: AppMetrics.captionHeight,
                              letterSpacing: AppMetrics.captionTracking,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppMetrics.space2),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: AppMotion.standard,
                      curve: AppMotion.inOut,
                      child: const Icon(Icons.expand_more, size: AppMetrics.iconSize),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.standard,
              curve: AppMotion.inOut,
              alignment: Alignment.topCenter,
              child: _open
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final step in widget.explanation.steps) _BeatTile(step: step),
                        const SizedBox(height: AppMetrics.space2),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeatTile extends StatelessWidget {
  const _BeatTile({required this.step});

  final ExplanationStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '${step.words} ${step.symbols}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppMetrics.space3,
          0,
          AppMetrics.space3,
          AppMetrics.space3,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppMetrics.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.words,
                      style: theme.textTheme.bodyMedium?.copyWith(height: AppMetrics.bodyHeight),
                    ),
                    const SizedBox(height: AppMetrics.space2),
                    SelectableText(
                      step.symbols,
                      style: AppTypefaces.of(context).math(
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen sheet used on the keypad calculator, where there is no room
/// to expand steps under the display.
Future<void> showStepsSheet(BuildContext context, Explanation explanation) {
  final strings = L10n.stringsOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        builder: (context, scroll) {
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(
              AppMetrics.space3,
              0,
              AppMetrics.space3,
              AppMetrics.space4,
            ),
            children: [
              Text(
                strings.howWeGotThis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: AppMetrics.titleHeight,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: AppMetrics.space1),
              Text(
                strings.howWeGotThisHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: AppMetrics.bodyHeight,
                    ),
              ),
              const SizedBox(height: AppMetrics.space3),
              for (final step in explanation.steps) _BeatTile(step: step),
            ],
          );
        },
      );
    },
  );
}
