import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight data holder for row-level question checkpoints (e.g., 5/20)
class RowProgressData {
  final int current;
  final int total;
  const RowProgressData({required this.current, required this.total});
}

/// Central singleton service managing persistent app progress, streaks,
/// row checkpoints, and row completion locks via SharedPreferences.
class ProgressService extends ChangeNotifier {
  static final ProgressService instance = ProgressService._internal();
  ProgressService._internal();

  late SharedPreferences _prefs;

  Set<String> _masteredKana = {};
  int _streakDays = 0;
  String _lastActiveDate = '';
  List<bool> _activeDaysThisWeek = List.filled(7, false);

  // Active script state for LearnScreen (true = Hiragana, false = Katakana)
  bool selectedLearnIsHiragana = true;

  /// Initializes SharedPreferences and loads saved progress
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
    _updateStreak();
  }

  void _loadData() {
    _masteredKana = (_prefs.getStringList('masteredKana') ?? []).toSet();
    _streakDays = _prefs.getInt('streakDays') ?? 0;
    _lastActiveDate = _prefs.getString('lastActiveDate') ?? '';

    for (int i = 0; i < 7; i++) {
      _activeDaysThisWeek[i] = _prefs.getBool('activeDay_$i') ?? false;
    }
  }

  void _updateStreak() {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    int weekdayIndex = now.weekday - 1;

    if (weekdayIndex == 0 && _lastActiveDate != todayStr) {
      _activeDaysThisWeek = List.filled(7, false);
    }

    if (_lastActiveDate == todayStr) return;

    if (_lastActiveDate.isEmpty) {
      _streakDays = 1;
    } else {
      final lastDate = DateTime.parse(_lastActiveDate);
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (difference == 1) {
        _streakDays += 1;
      } else if (difference > 1) {
        _streakDays = 1;
        _activeDaysThisWeek = List.filled(7, false);
      }
    }

    _activeDaysThisWeek[weekdayIndex] = true;
    _lastActiveDate = todayStr;

    _prefs.setInt('streakDays', _streakDays);
    _prefs.setString('lastActiveDate', _lastActiveDate);
    _prefs.setBool('activeDay_$weekdayIndex', true);

    notifyListeners();
  }

  /// Sets whether the Learn screen displays Hiragana or Katakana
  void setLearnScript({required bool isHiragana}) {
    selectedLearnIsHiragana = isHiragana;
    notifyListeners();
  }

  /// Saves row question progress when exiting a quiz session (e.g., 5/20)
  /// Fixes error in quiz_screen.dart
  Future<void> saveRowProgress({
    required String writingSystem,
    required String rowTitle,
    required int currentQuestion,
    required int totalQuestions,
  }) async {
    final keyCurrent = 'row_progress_${writingSystem}_${rowTitle}_current';
    final keyTotal = 'row_progress_${writingSystem}_${rowTitle}_total';

    await _prefs.setInt(keyCurrent, currentQuestion);
    await _prefs.setInt(keyTotal, totalQuestions);

    // If all questions are finished, mark the row completed to unlock next row
    if (currentQuestion >= totalQuestions && totalQuestions > 0) {
      await _prefs.setBool('row_completed_${writingSystem}_$rowTitle', true);
    }

    notifyListeners();
  }

  /// Retrieves stored row progress for Home dashboard display (defaults to 0/20)
  /// Fixes error in main.dart
  RowProgressData getRowProgress({
    required String writingSystem,
    required String rowTitle,
  }) {
    final current =
        _prefs.getInt('row_progress_${writingSystem}_${rowTitle}_current') ?? 0;
    final total =
        _prefs.getInt('row_progress_${writingSystem}_${rowTitle}_total') ?? 20;
    return RowProgressData(current: current, total: total);
  }

  /// Checks if a prerequisite row is completed
  /// Fixes error in learn_screen.dart
  bool isRowCompleted({
    required String writingSystem,
    required String rowTitle,
  }) {
    return _prefs.getBool('row_completed_${writingSystem}_$rowTitle') ?? false;
  }

  /// Saves a newly mastered character
  void markKanaMastered(String kana) {
    if (kana.isEmpty || _masteredKana.contains(kana)) return;

    _masteredKana.add(kana);
    _prefs.setStringList('masteredKana', _masteredKana.toList());
    notifyListeners();
  }

  // --- GETTERS ---
  int get streakDays => _streakDays;
  List<bool> get activeDaysThisWeek => _activeDaysThisWeek;
  int get totalMastered => _masteredKana.length;

  int get masteredHiraganaCount => _masteredKana.where(_isHiragana).length;
  int get masteredKatakanaCount => _masteredKana.where(_isKatakana).length;

  bool _isHiragana(String c) {
    if (c.isEmpty) return false;
    int code = c.codeUnitAt(0);
    return code >= 0x3040 && code <= 0x309F;
  }

  bool _isKatakana(String c) {
    if (c.isEmpty) return false;
    int code = c.codeUnitAt(0);
    return code >= 0x30A0 && code <= 0x30FF;
  }
}
