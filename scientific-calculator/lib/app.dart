import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/math_gallery_screen.dart';
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
          title: HomeScreen.title,
          debugShowCheckedModeBanner: false,
          // Four appearances, chosen by the system rather than by us.
          // A person who has set their phone to light, or turned on
          // Increase Contrast, has already said what they want; asking
          // them to say it again inside every app is the thing Apple's
          // guidelines are arguing against.
          theme: buildAppTheme(Appearance.light),
          darkTheme: buildAppTheme(Appearance.dark),
          highContrastTheme: buildAppTheme(Appearance.lightHighContrast),
          highContrastDarkTheme: buildAppTheme(Appearance.darkHighContrast),
          themeMode: ThemeMode.system,
          home: HomeScreen(settings: settings),
          routes: {'/math-gallery': (_) => const MathGalleryScreen()},
        );
      },
    );
  }
}
