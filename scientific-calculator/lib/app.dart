import 'package:flutter/material.dart';

import 'screens/calculator_screen.dart';
import 'services/settings_controller.dart';
import 'theme/app_theme.dart';

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Scientific Calculator',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(settings.layoutStyle),
          home: CalculatorScreen(settings: settings),
        );
      },
    );
  }
}
