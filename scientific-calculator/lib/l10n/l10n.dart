import 'package:flutter/material.dart';

import 'app_language.dart';
import 'app_strings.dart';

class L10n extends InheritedWidget {
  const L10n({
    super.key,
    required this.language,
    required this.strings,
    required super.child,
  });

  final AppLanguage language;
  final AppStrings strings;

  static L10n? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<L10n>();

  static L10n of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'L10n not found');
    return scope!;
  }

  static AppLanguage languageOf(BuildContext context) =>
      maybeOf(context)?.language ?? AppLanguage.english;

  static AppStrings stringsOf(BuildContext context) =>
      maybeOf(context)?.strings ?? AppStrings.of(AppLanguage.english);

  @override
  bool updateShouldNotify(L10n oldWidget) =>
      language.code != oldWidget.language.code;
}
