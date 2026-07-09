import 'package:flutter/material.dart';

import '../core/calculator_controller.dart';
import '../services/feedback_service.dart';
import '../services/settings_controller.dart';
import '../widgets/calculator_display.dart';
import '../widgets/keypad.dart';
import 'settings_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _controller = CalculatorController();
  late final _feedback = FeedbackService(widget.settings);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scientific Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(settings: widget.settings),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
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
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
