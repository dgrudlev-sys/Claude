import 'package:flutter/material.dart';

/// Shared visual tokens. Use these instead of magic numbers in widgets.
class AppMetrics {
  AppMetrics._();

  static const double grid = 8;

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 16;
  static const double space4 = 24;
  static const double space5 = 32;

  static const double radiusCard = 16;
  static const double radiusControl = 12;
  /// Dense keypad: tighter than [radiusControl] so keys tessellate, not pillow.
  static const double radiusKey = 8;

  /// 4px between keys. Do not pad each key on both sides or this doubles to 8.
  static const double keypadGutter = space1;
  /// 4px from the screen edge — pad reads edge-to-edge, not floating islands.
  static const double keypadInset = space1;
  /// Wide window / landscape: functions on the left, Samsung numpad on the right.
  static const double keypadWideMinWidth = 640;
  /// Gap between the scientific cluster and the number pad in the wide layout.
  static const double keypadPanelGutter = space2;

  static const double padCard = 16;
  static const double hairline = 1;

  static const double iconSize = 24;
  static const double glyphSize = 28;

  /// Slightly lifted vs the charcoal scaffold.
  static const Color cardFill = Color(0xFF2A2825);
  static const Color cardHairline = Color(0x593A3732);

  static const Color fxUp = Color(0xFF2E7D32);
  static const Color fxDown = Color(0xFFC62828);
  static const Color fxFlat = Color(0xFFF9A825);

  static const double titleHeight = 1.25;
  static const double bodyHeight = 1.40;
  static const double captionHeight = 1.30;
  static const double titleTracking = -0.2;
  static const double captionTracking = 0.1;
}

class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 280);

  static const Curve out = Curves.easeOutCubic;
  static const Curve inOut = Curves.easeInOutCubic;
}
