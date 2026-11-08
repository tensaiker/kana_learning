import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the learner's chosen appearance and notifies MaterialApp immediately.
/// NOTE: screens using hard-coded colors need a follow-up palette refactor
/// to respond visually to dark mode. This service does not touch lesson data.
class AppearanceService extends ChangeNotifier {
  AppearanceService._();
  static final AppearanceService instance = AppearanceService._();

  static const String preferenceKey = 'settings_appearance_mode';
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  void load(SharedPreferences prefs) {
    final value = prefs.getString(preferenceKey);
    _mode = switch (value) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, mode.name);
    _mode = mode;
    notifyListeners();
  }

  /// Call after the full-data reset. SharedPreferences is already cleared.
  void reset() {
    _mode = ThemeMode.light;
    notifyListeners();
  }
}
