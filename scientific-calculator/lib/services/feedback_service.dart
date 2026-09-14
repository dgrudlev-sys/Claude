import 'package:flutter/services.dart';

import 'settings_controller.dart';

/// Fires the sound/haptic response for a key press, gated by whatever the
/// user has enabled in [SettingsController]. Kept as a thin wrapper so the
/// keypad widget doesn't need to know about platform channels directly.
class FeedbackService {
  const FeedbackService(this._settings);

  final SettingsController _settings;

  void onKeyPress() {
    if (_settings.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (_settings.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }
}
