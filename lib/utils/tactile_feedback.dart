import 'package:flutter/services.dart';

/// Centralized utility for tactile stationery clicks and physical haptic feedback.
class TactileFeedback {
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// Primary button press down (mechanical stationery click + subtle vibration)
  static void press() {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Triggered on successful answer or complete milestone
  static void success() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Triggered on an incorrect selection or locked item tap
  static void error() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Subtle tick for toggles, pill switches, and card flips
  static void toggle() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }
}
