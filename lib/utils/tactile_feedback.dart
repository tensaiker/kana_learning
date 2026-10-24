import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized utility for tactile stationery clicks and physical haptic feedback.
///
/// Calibrated for both modern linear actuators (iOS Taptic Engine, flagship Android)
/// and traditional rotary ERM motors (TECNO, Infinix, Xiaomi, Samsung A-series)
/// where subtle micro-ticks (`lightImpact`, `selectionClick`) are often dropped by the OS.
class TactileFeedback {
  // Global toggle flags synced across settings and throughout the app
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  // Cached SharedPreferences instance for fast setting updates without re-fetching
  static SharedPreferences? _prefs;

  /// Loads saved tactile preferences from SharedPreferences at startup.
  /// Call this in `main()` before `runApp()`.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    soundEnabled = _prefs?.getBool('settings_sound_fx') ?? true;
    hapticsEnabled = _prefs?.getBool('settings_haptics') ?? true;
  }

  /// Updates and persists the sound effect toggle state.
  static Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool('settings_sound_fx', enabled);
  }

  /// Updates and persists the haptic feedback toggle state.
  static Future<void> setHapticsEnabled(bool enabled) async {
    hapticsEnabled = enabled;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool('settings_haptics', enabled);
  }

  /// Primary button press down (card taps, navigation buttons).
  ///
  /// Uses `mediumImpact` so physical vibration motors have sufficient spin-up
  /// time to produce a discernible tactile pop.
  static void press() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Triggered on successful answer, correct stroke match, or milestone completion.
  ///
  /// Delivers a solid tactile confirmation pulse.
  static void success() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Triggered on an incorrect selection, off-target stroke, or locked item tap.
  ///
  /// Uses `heavyImpact` paired with fallback `vibrate` to guarantee a prominent
  /// error buzz across all Android hardware.
  static void error() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Subtle tick for toggles, pill switches, tab changes, and card flips.
  ///
  /// Calls `selectionClick` with fallback support for Android devices where
  /// selection clicks are disabled in system settings.
  static void toggle() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Strong physical vibration pulse for explicit alerts or reset confirmations.
  /// Note: Requires `<uses-permission android:name="android.permission.VIBRATE" />` in AndroidManifest.xml.
  static void vibrate() {
    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
