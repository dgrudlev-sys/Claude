import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';

export '../design/tokens.dart' show Appearance, Palette, SurfacePair, Space, Radii, TouchTarget, Motion;

/// Which kind of key a button is. The colour it gets comes from the
/// palette, which supplies the text colour alongside it.
enum ButtonRole { number, operatorKey, function, action, equals }

/// Carries the resolved [Palette] through the widget tree.
///
/// A theme extension rather than a set of loose colours, so a widget asks
/// for the role it needs and cannot pick a background from one appearance
/// and a foreground from another.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette(this.palette);

  final Palette palette;

  SurfacePair forRole(ButtonRole role) => switch (role) {
        ButtonRole.number => palette.keyNumber,
        ButtonRole.operatorKey => palette.keyOperator,
        ButtonRole.function => palette.keyFunction,
        ButtonRole.action => palette.keyAction,
        ButtonRole.equals => palette.keyEquals,
      };

  @override
  AppPalette copyWith({Palette? palette}) => AppPalette(palette ?? this.palette);

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    // Palettes are discrete appearances, not points on a line: half way
    // between light and dark is not a design, it is a smear. Snap.
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }

  static Palette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!.palette;
}

/// Builds the theme for one appearance.
///
/// Four of these exist — light, dark, and an Increase Contrast variant of
/// each — and Flutter picks between them from the system settings, so the
/// app follows the phone rather than asking the user to configure it
/// twice.
ThemeData buildAppTheme(Appearance appearance) {
  final palette = Palette.of(appearance);
  final brightness = appearance.isDark ? Brightness.dark : Brightness.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    secondary: palette.accent,
    onSecondary: palette.onAccent,
    error: palette.errorSurface.background,
    onError: palette.errorSurface.foreground,
    surface: palette.elevatedSurface,
    onSurface: palette.label,
    surfaceContainerHighest: palette.groupedBackground,
    onSurfaceVariant: palette.secondaryLabel,
    outline: palette.separator,
  );

  TextStyle body(TextStyle style) => style.copyWith(color: palette.label);
  TextStyle muted(TextStyle style) => style.copyWith(color: palette.secondaryLabel);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    // Set once, here, so nothing downstream has to remember it. Every
    // style in AppType inherits it, including the ones Material builds
    // for its own widgets.
    fontFamily: AppType.family,
    scaffoldBackgroundColor: palette.background,
    dividerColor: palette.separator,
    splashFactory: InkSparkle.splashFactory,
    extensions: [AppPalette(palette)],
    textTheme: TextTheme(
      displayLarge: body(AppType.displayResult),
      headlineLarge: body(AppType.largeTitle),
      headlineMedium: body(AppType.title1),
      headlineSmall: body(AppType.title2),
      titleLarge: body(AppType.title3),
      titleMedium: body(AppType.headline),
      bodyLarge: body(AppType.body),
      bodyMedium: body(AppType.callout),
      bodySmall: muted(AppType.subheadline),
      labelLarge: body(AppType.headline),
      labelMedium: muted(AppType.footnote),
      labelSmall: muted(AppType.caption1),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.label,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppType.title2.copyWith(color: palette.label),
    ),
    // A utility surface: transitions get out of the way of the task.
    // A cross-fade on every platform. Fades survive Reduce Motion with
    // only a change of duration; a slide that crosses the screen is the
    // highest-risk category for vestibular disorders and has to be
    // replaced outright rather than shortened.
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
    }),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(TouchTarget.comfortable, 52),
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        textStyle: AppType.headline,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(TouchTarget.comfortable, 52),
        foregroundColor: palette.accentOnSurface,
        backgroundColor: palette.elevatedSurface,
        side: BorderSide(color: palette.separator),
        textStyle: AppType.headline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accentOnSurface,
        textStyle: AppType.callout.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(TouchTarget.minimum, TouchTarget.minimum),
        foregroundColor: palette.label,
      ),
    ),
    // Borderless and filled. A box drawn around every field is the single
    // loudest "this is a form" signal there is, and none of these screens
    // is a form — they are places you type one thing.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.groupedBackground,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Space.m, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.medium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.medium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.medium),
        borderSide: BorderSide(color: palette.accent, width: 2),
      ),
      hintStyle: AppType.body.copyWith(color: palette.secondaryLabel),
      labelStyle: AppType.subheadline.copyWith(color: palette.secondaryLabel),
      floatingLabelStyle:
          AppType.footnote.copyWith(color: palette.accentOnSurface),
      helperStyle: AppType.footnote.copyWith(color: palette.secondaryLabel),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.elevatedSurface,
      selectedColor: palette.accentSoft.background,
      side: BorderSide.none,
      showCheckmark: false,
      labelStyle: AppType.subheadline.copyWith(
        color: palette.label,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: AppType.subheadline.copyWith(
        color: palette.accentSoft.foreground,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 10),
      shape: const StadiumBorder(),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? palette.elevatedSurface
                : Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? palette.label
                : palette.secondaryLabel),
        side: WidgetStateProperty.all(BorderSide.none),
        textStyle: WidgetStateProperty.all(
          AppType.subheadline.copyWith(fontWeight: FontWeight.w600),
        ),
        shape: WidgetStateProperty.all(const StadiumBorder()),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? palette.accent
              : palette.separator),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.elevatedSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          AppType.caption2.copyWith(
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? palette.accentOnSurface
                : palette.secondaryLabel,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? palette.accentOnSurface
                : palette.secondaryLabel,
          )),
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: AppType.body.copyWith(color: palette.label),
      subtitleTextStyle: AppType.subheadline.copyWith(color: palette.secondaryLabel),
      iconColor: palette.secondaryLabel,
    ),
    dividerTheme: DividerThemeData(color: palette.separator, space: 1, thickness: 1),
  );
}
