import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized utility for tactile stationery clicks and physical haptic feedback.
/// Supports runtime toggling and persistence via SharedPreferences.
class TactileFeedback {
  // Global toggle flags synced across ProfileScreen and throughout the app
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// Loads saved tactile preferences from SharedPreferences at startup
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    soundEnabled = prefs.getBool('settings_sound_fx') ?? true;
    hapticsEnabled = prefs.getBool('settings_haptics') ?? true;
  }

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
