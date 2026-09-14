import 'package:flutter/material.dart';

import 'convert/currency_service.dart';
import 'core/calculator_mode.dart';
import 'l10n/app_language.dart';
import 'l10n/app_strings.dart';
import 'l10n/l10n.dart';
import 'screens/home_shell.dart';
import 'screens/language_picker_screen.dart';
import 'screens/mode_picker_screen.dart';
import 'services/settings_controller.dart';
import 'theme/app_theme.dart';
import 'theme/app_metrics.dart';
import 'widgets/adaptive_phone_shell.dart';

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  CalculatorMode? _mode;

  @override
  void initState() {
    super.initState();
    final settings = widget.settings;
    CurrencyService.instance.attachPrefs(settings.prefs);
    if (settings.openLastMode && settings.lastMode != null) {
      _mode = settings.lastMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) {
        final settings = widget.settings;
        final language = settings.language ?? AppLanguage.english;
        final strings = AppStrings.of(language);
        return L10n(
          language: language,
          strings: strings,
          child: MaterialApp(
            title: strings.modeLabel('calculator'),
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(
              settings.layoutStyle,
              vision: settings.visionProfile,
              story: settings.colorStory,
              voice: settings.typeVoice,
            ),
            themeAnimationDuration: AppMotion.standard,
            themeAnimationCurve: AppMotion.out,
            builder: (context, child) {
              return Directionality(
                textDirection: language.rtl ? TextDirection.rtl : TextDirection.ltr,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(settings.textScale),
                  ),
                  child: AdaptivePhoneShell(child: child ?? const SizedBox.shrink()),
                ),
              );
            },
            home: settings.language == null
                ? LanguagePickerScreen(
                    settings: settings,
                    asFirstLaunch: true,
                  )
                : _mode == null
                    ? ModePickerScreen(
                        settings: settings,
                        onChosen: (mode) => setState(() => _mode = mode),
                      )
                    : HomeShell(
                        settings: settings,
                        mode: _mode!,
                        onChangeCalculator: () => setState(() => _mode = null),
                      ),
          ),
        );
      },
    );
  }
}
