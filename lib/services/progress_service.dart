import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight data holder for row-level question checkpoints (e.g., 5/20)[cite: 15]
class RowProgressData {
  final int current;
  final int total;
  const RowProgressData({required this.current, required this.total});
}

/// Central singleton service managing persistent app progress, streaks,
/// row checkpoints, practice session statistics, and row completion locks via SharedPreferences.[cite: 15]
class ProgressService extends ChangeNotifier {
  static final ProgressService instance = ProgressService._internal();
  ProgressService._internal();

  late SharedPreferences _prefs;

  Set<String> _masteredKana = {};
  int _streakDays = 0;
  String _lastActiveDate = '';
  List<bool> _activeDaysThisWeek = List.filled(7, false);

  // Active script state for LearnScreen (true = Hiragana, false = Katakana)[cite: 15]
  bool selectedLearnIsHiragana = true;

  // --- PRACTICE & VOCABULARY PERSISTENCE STATES ---
  Set<String> _masteredWords = {};
  int _wordsCompletedCount = 0;
  int _flashcardsReviewedCount = 0;

  /// Initializes SharedPreferences and loads saved progress[cite: 15]
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

    // Load practice metrics and mastered vocabulary words
    _masteredWords = (_prefs.getStringList('masteredWords') ?? []).toSet();
    _wordsCompletedCount = _prefs.getInt('wordsCompletedCount') ?? 0;
    _flashcardsReviewedCount = _prefs.getInt('flashcardsReviewedCount') ?? 0;
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

  /// Sets whether the Learn screen displays Hiragana or Katakana[cite: 15]
  void setLearnScript({required bool isHiragana}) {
    selectedLearnIsHiragana = isHiragana;
    notifyListeners();
  }

  /// Saves row question progress when exiting a quiz session (e.g., 5/20)[cite: 15]
  /// Fixes error in quiz_screen.dart[cite: 15]
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

    // If all questions are finished, mark the row completed to unlock next row[cite: 15]
    if (currentQuestion >= totalQuestions && totalQuestions > 0) {
      await _prefs.setBool('row_completed_${writingSystem}_$rowTitle', true);
    }

    notifyListeners();
  }

  /// Retrieves stored row progress for Home dashboard display (defaults to 0/20)[cite: 15]
  /// Fixes error in main.dart[cite: 15]
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

  /// Checks if a prerequisite row is completed[cite: 15]
  /// Fixes error in learn_screen.dart[cite: 15]
  bool isRowCompleted({
    required String writingSystem,
    required String rowTitle,
  }) {
    return _prefs.getBool('row_completed_${writingSystem}_$rowTitle') ?? false;
  }

  /// Saves a newly mastered character[cite: 15]
  void markKanaMastered(String kana) {
    if (kana.isEmpty || _masteredKana.contains(kana)) return;

    _masteredKana.add(kana);
    _prefs.setStringList('masteredKana', _masteredKana.toList());
    notifyListeners();
  }

  // ===========================================================================
  // PRACTICE PERSISTENCE METHODS (Flashcards & Word Builder)
  // ===========================================================================

  /// Increments total reviewed flashcard count in SharedPreferences.
  /// Call this when a card is flipped or rated in flashcard_screen.dart.
  Future<void> recordFlashcardReviewed() async {
    _flashcardsReviewedCount += 1;
    await _prefs.setInt('flashcardsReviewedCount', _flashcardsReviewedCount);
    notifyListeners();
  }

  /// Records a completed vocabulary word from Word Builder or practice activities.
  /// Stores the word in mastered words and marks its individual Kana characters as mastered.
  Future<void> recordWordCompleted({
    required String word,
    bool wasCorrectFirstTry = true,
  }) async {
    _wordsCompletedCount += 1;
    await _prefs.setInt('wordsCompletedCount', _wordsCompletedCount);

    if (word.isNotEmpty && !_masteredWords.contains(word)) {
      _masteredWords.add(word);
      await _prefs.setStringList('masteredWords', _masteredWords.toList());
    }

    // Automatically mark every Kana character within the word as mastered
    for (int i = 0; i < word.runes.length; i++) {
      final char = String.fromCharCode(word.runes.elementAt(i));
      markKanaMastered(char);
    }

    notifyListeners();
  }

  /// Checks if a vocabulary word is already marked as mastered.
  bool isWordMastered(String word) {
    return _masteredWords.contains(word);
  }

  // --- GETTERS ---
  int get streakDays => _streakDays; //[cite: 15]
  List<bool> get activeDaysThisWeek => _activeDaysThisWeek; //[cite: 15]
  int get totalMastered => _masteredKana.length; //[cite: 15]

  int get masteredHiraganaCount =>
      _masteredKana.where(_isHiragana).length; //[cite: 15]
  int get masteredKatakanaCount =>
      _masteredKana.where(_isKatakana).length; //[cite: 15]

  // Practice getters
  int get wordsCompletedCount => _wordsCompletedCount;
  int get flashcardsReviewedCount => _flashcardsReviewedCount;
  int get totalMasteredWords => _masteredWords.length;
  Set<String> get masteredWords => Set.unmodifiable(_masteredWords);

  bool _isHiragana(String c) {
    if (c.isEmpty) return false; //[cite: 15]
    int code = c.codeUnitAt(0); //[cite: 15]
    return code >= 0x3040 && code <= 0x309F; //[cite: 15]
  }

  bool _isKatakana(String c) {
    if (c.isEmpty) return false; //[cite: 15]
    int code = c.codeUnitAt(0); //[cite: 15]
    return code >= 0x30A0 && code <= 0x30FF; //[cite: 15]
  }
}
