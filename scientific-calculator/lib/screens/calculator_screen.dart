import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../core/calculator_controller.dart';
import '../services/feedback_service.dart';
import '../services/settings_controller.dart';
import '../l10n/app_language.dart';
import '../l10n/l10n.dart';
import '../services/speech_service.dart';
import '../widgets/calculator_display.dart';
import '../widgets/keypad.dart';

/// The calculator's display + keypad only — no Scaffold/AppBar of its own,
/// since it's hosted inside [HomeShell] alongside the other modes.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final _controller = CalculatorController(prefs: widget.settings.prefs);
  late final _feedback = FeedbackService(widget.settings);
  final _speech = SpeechService();
  String? _lastAnnounced;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_announce);
  }

  void _announce() {
    final text = _controller.announcement;
    if (text == null || text == _lastAnnounced) return;
    _lastAnnounced = text;
    SemanticsService.announce(text, TextDirection.ltr); // ignore: deprecated_member_use
  }

  void _speakEquation() {
    final language = L10n.maybeOf(context)?.language ?? AppLanguage.english;
    final raw = _controller.expression.isEmpty ? '0' : _controller.expression;
    final shown = formatForLocale(raw, language);
    _speech.speak(shown);
  }

  @override
  void dispose() {
    _controller.removeListener(_announce);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _controller.moveCursorLeft,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _controller.moveCursorRight,
        const SingleActivator(LogicalKeyboardKey.backspace): _controller.backspace,
        const SingleActivator(LogicalKeyboardKey.enter): _controller.evaluate,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _controller.evaluate,
      },
      child: Focus(
        autofocus: true,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                children: [
                  CalculatorDisplay(controller: _controller),
                  const Divider(height: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: AnimatedBuilder(
                        animation: widget.settings,
                        builder: (context, _) => Keypad(
                          controller: _controller,
                          layoutStyle: widget.settings.layoutStyle,
                          feedback: _feedback,
                          onSpeak: _speakEquation,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
