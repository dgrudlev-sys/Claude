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
  const CalculatorScreen({
    super.key,
    required this.settings,
    this.onOpenConvert,
  });

  final SettingsController settings;
  final VoidCallback? onOpenConvert;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpeechLanguage();
  }

  void _syncSpeechLanguage() {
    final language = L10n.maybeOf(context)?.language ?? AppLanguage.english;
    _speech.setLanguage(language);
  }

  void _announce() {
    if (!mounted) return;
    final text = _controller.announcement;
    if (text == null || text == _lastAnnounced) return;
    _lastAnnounced = text;
    final rtl = L10n.maybeOf(context)?.language.rtl ?? false;
    SemanticsService.announce( // ignore: deprecated_member_use
      text,
      rtl ? TextDirection.rtl : TextDirection.ltr,
    );
  }

  void _speakEquation() {
    final language = L10n.maybeOf(context)?.language ?? AppLanguage.english;
    final raw = _controller.expression.isEmpty ? '0' : _controller.expression;
    final shown = formatForLocale(raw, language);
    _speech.speak(shown, language: language);
  }

  @override
  void dispose() {
    _controller.removeListener(_announce);
    _controller.dispose();
    _speech.stop();
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
          left: false,
          right: false,
          bottom: false,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                children: [
                  CalculatorDisplay(
                    controller: _controller,
                    onOpenConvert: widget.onOpenConvert,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: widget.settings,
                      builder: (context, _) => Keypad(
                        controller: _controller,
                        layoutStyle: widget.settings.layoutStyle,
                        feedback: _feedback,
                        onSpeak: _speakEquation,
                        scientific: widget.settings.scientificKeypad,
                        onScientificChanged: widget.settings.setScientificKeypad,
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
