import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight data holder for row-level question checkpoints (e.g., 5/20)[cite: 12].
class RowProgressData {
  final int current;
  final int total;
  const RowProgressData({required this.current, required this.total});
}

/// Central singleton service managing persistent app progress, streaks,
/// row checkpoints, practice session statistics, and row unlocking via SharedPreferences[cite: 12].
///
/// Synchronization & Progression Rules:
/// 1. [unlockAllRows] is `false` by default to enforce sequential lesson progression[cite: 12].
/// 2. Completing a lesson row in the Learn tab calls [saveRowProgress] or [markRowCompleted],
///    which unlocks the subsequent row in the Learn tab and enables selection in Flashcards[cite: 12].
/// 3. Centralized [isRowUnlocked] evaluates prerequisite row completion for Basic Kana,
///    Dakuon, and Yoon across both tabs[cite: 12].
class ProgressService extends ChangeNotifier {
  static final ProgressService instance = ProgressService._internal();
  ProgressService._internal();

  // Nullable reference to prevent LateInitializationError if accessed before init finishes
  SharedPreferences? _prefs;

  Set<String> _masteredKana = {};
  int _masteredHiraganaCount = 0;
  int _masteredKatakanaCount = 0;

  int _streakDays = 0;
  String _lastActiveDate = '';
  List<bool> _activeDaysThisWeek = List.filled(7, false);

  // Active script state for LearnScreen (true = Hiragana, false = Katakana)[cite: 12]
  bool selectedLearnIsHiragana = true;

  // Progression override: defaults to false so rows unlock sequentially[cite: 12]
  bool unlockAllRows = false;

  // Progression row orders for prerequisite validation[cite: 12]
  static const List<String> basicRowOrder = [
    'A row',
    'Ka row',
    'Sa row',
    'Ta row',
    'Na row',
    'Ha row',
    'Ma row',
    'Ya row',
    'Ra row',
    'Wa / N row',
  ];

  static const List<String> dakuonRowTitles = [
    'Ga row',
    'Za row',
    'Da row',
    'Ba row',
    'Pa row',
  ];

  static const List<String> yoonRowTitles = [
    'Kya row',
    'Sha row',
    'Cha row',
    'Nya row',
    'Hya row',
    'Mya row',
    'Rya row',
    'Gya row',
    'Ja row',
    'Bya row',
    'Pya row',
  ];

  // --- PRACTICE & VOCABULARY PERSISTENCE STATES ---[cite: 12]
  Set<String> _masteredWords = {};
  int _wordsCompletedCount = 0;
  int _flashcardsReviewedCount = 0;

  /// Initializes SharedPreferences and loads saved progress[cite: 12].
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
    _updateStreak();
  }

  void _loadData() {
    final prefs = _prefs;
    if (prefs == null) return;

    _masteredKana = (prefs.getStringList('masteredKana') ?? []).toSet();
    _recalculateMasteredCounts();

    _streakDays = prefs.getInt('streakDays') ?? 0;
    _lastActiveDate = prefs.getString('lastActiveDate') ?? '';

    for (int i = 0; i < 7; i++) {
      _activeDaysThisWeek[i] = prefs.getBool('activeDay_$i') ?? false;
    }

    // Load practice metrics and mastered vocabulary words[cite: 12]
    _masteredWords = (prefs.getStringList('masteredWords') ?? []).toSet();
    _wordsCompletedCount = prefs.getInt('wordsCompletedCount') ?? 0;
    _flashcardsReviewedCount = prefs.getInt('flashcardsReviewedCount') ?? 0;

    // Load row progression override preference (defaults to false)[cite: 12]
    unlockAllRows = prefs.getBool('unlockAllRows') ?? false;
  }

  void _recalculateMasteredCounts() {
    int hCount = 0;
    int kCount = 0;
    for (final char in _masteredKana) {
      if (_isHiragana(char)) hCount++;
      if (_isKatakana(char)) kCount++;
    }
    _masteredHiraganaCount = hCount;
    _masteredKatakanaCount = kCount;
  }

  void _updateStreak() {
    final prefs = _prefs;
    if (prefs == null) return;

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
      final lastDate = DateTime.tryParse(_lastActiveDate);
      if (lastDate != null) {
        final difference = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;

        if (difference == 1) {
          _streakDays += 1;
        } else if (difference > 1) {
          _streakDays = 1;
          _activeDaysThisWeek = List.filled(7, false);
        }
      } else {
        _streakDays = 1;
      }
    }

    _activeDaysThisWeek[weekdayIndex] = true;
    _lastActiveDate = todayStr;

    prefs.setInt('streakDays', _streakDays);
    prefs.setString('lastActiveDate', _lastActiveDate);
    prefs.setBool('activeDay_$weekdayIndex', true);

    notifyListeners();
  }

  /// Sets whether the Learn screen displays Hiragana or Katakana[cite: 12].
  void setLearnScript({required bool isHiragana}) {
    if (selectedLearnIsHiragana == isHiragana) return;
    selectedLearnIsHiragana = isHiragana;
    notifyListeners();
  }

  /// Toggles unlocking all learning rows immediately across the app[cite: 12].
  Future<void> setUnlockAllRows(bool value) async {
    if (unlockAllRows == value) return;
    unlockAllRows = value;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('unlockAllRows', value);
    notifyListeners();
  }

  /// Utility to map short row IDs ('a', 'ka', etc.) to full row titles.
  static String? rowIdToTitle(String rowId) {
    switch (rowId) {
      case 'a':
        return 'A row';
      case 'ka':
        return 'Ka row';
      case 'sa':
        return 'Sa row';
      case 'ta':
        return 'Ta row';
      case 'na':
        return 'Na row';
      case 'ha':
        return 'Ha row';
      case 'ma':
        return 'Ma row';
      case 'ya':
        return 'Ya row';
      case 'ra':
        return 'Ra row';
      case 'wa':
        return 'Wa / N row';
      case 'ga':
        return 'Ga row';
      case 'za':
        return 'Za row';
      case 'da':
        return 'Da row';
      case 'ba':
        return 'Ba row';
      case 'pa':
        return 'Pa row';
      case 'kya':
        return 'Kya row';
      case 'sha':
        return 'Sha row';
      case 'cha':
        return 'Cha row';
      case 'nya':
        return 'Nya row';
      case 'hya':
        return 'Hya row';
      case 'mya':
        return 'Mya row';
      case 'rya':
        return 'Rya row';
      case 'gya':
        return 'Gya row';
      case 'ja':
        return 'Ja row';
      case 'bya':
        return 'Bya row';
      case 'pya':
        return 'Pya row';
      default:
        return null;
    }
  }

  // ===========================================================================
  // ROW PROGRESSION & UNLOCK LOGIC (Shared between Learn & Flashcards)
  // ===========================================================================

  /// Saves row question progress when completing/exiting a session (e.g., 5/20)[cite: 12].
  Future<void> saveRowProgress({
    required String writingSystem,
    required String rowTitle,
    required int currentQuestion,
    required int totalQuestions,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final keyCurrent = 'row_progress_${writingSystem}_${rowTitle}_current';
    final keyTotal = 'row_progress_${writingSystem}_${rowTitle}_total';

    final writes = <Future<bool>>[
      prefs.setInt(keyCurrent, currentQuestion),
      prefs.setInt(keyTotal, totalQuestions),
    ];

    // If all questions are finished, mark the row completed to unlock next rows[cite: 12]
    if (currentQuestion >= totalQuestions && totalQuestions > 0) {
      writes.add(
        prefs.setBool('row_completed_${writingSystem}_$rowTitle', true),
      );
    }

    await Future.wait(writes);
    notifyListeners();
  }

  /// Directly marks a lesson row as completed/unlocked without requiring a quiz score[cite: 12].
  Future<void> markRowCompleted({
    required String writingSystem,
    required String rowTitle,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('row_completed_${writingSystem}_$rowTitle', true);
    notifyListeners();
  }

  /// Retrieves stored row progress for Home dashboard display (defaults to 0/20)[cite: 12].
  RowProgressData getRowProgress({
    required String writingSystem,
    required String rowTitle,
  }) {
    final current =
        _prefs?.getInt('row_progress_${writingSystem}_${rowTitle}_current') ??
        0;
    final total =
        _prefs?.getInt('row_progress_${writingSystem}_${rowTitle}_total') ?? 20;
    return RowProgressData(current: current, total: total);
  }

  /// Checks if a row has been completed[cite: 12].
  /// Returns `true` if [unlockAllRows] is enabled or if marked completed in preferences[cite: 12].
  bool isRowCompleted({
    required String writingSystem,
    required String rowTitle,
  }) {
    if (unlockAllRows) return true;
    return _prefs?.getBool('row_completed_${writingSystem}_$rowTitle') ?? false;
  }

  /// Single source of truth for row unlock validation across Learn and Flashcard tabs[cite: 12].
  /// - 'A row' is always unlocked[cite: 12].
  /// - Subsequent basic rows require completion of the previous row[cite: 12].
  /// - Dakuon rows require completion of 'Wa / N row'[cite: 12].
  /// - Yoon rows require completion of 'Pa row'[cite: 12].
  bool isRowUnlocked({String? writingSystem, String? rowTitle, String? rowId}) {
    if (unlockAllRows) return true;

    final system =
        writingSystem ?? (selectedLearnIsHiragana ? 'Hiragana' : 'Katakana');
    final title = rowTitle ?? (rowId != null ? rowIdToTitle(rowId) : null);

    if (title == null || title == 'A row') return true;

    final basicIndex = basicRowOrder.indexOf(title);
    if (basicIndex > 0) {
      final prevRow = basicRowOrder[basicIndex - 1];
      return isRowCompleted(writingSystem: system, rowTitle: prevRow);
    }

    if (dakuonRowTitles.contains(title)) {
      return isRowCompleted(writingSystem: system, rowTitle: 'Wa / N row');
    }

    if (yoonRowTitles.contains(title)) {
      return isRowCompleted(writingSystem: system, rowTitle: 'Pa row');
    }

    return true;
  }

  /// Checks if an individual character is unlocked for practice.
  bool isCharacterUnlocked(String characterId) {
    return true;
  }

  /// Saves a newly mastered character and updates cached counts[cite: 12].
  void markKanaMastered(String kana) {
    if (kana.isEmpty || _masteredKana.contains(kana)) return;

    _masteredKana.add(kana);
    if (_isHiragana(kana)) _masteredHiraganaCount++;
    if (_isKatakana(kana)) _masteredKatakanaCount++;

    final prefs = _prefs;
    if (prefs != null) {
      prefs.setStringList('masteredKana', _masteredKana.toList());
    } else {
      SharedPreferences.getInstance().then((p) {
        p.setStringList('masteredKana', _masteredKana.toList());
      });
    }
    notifyListeners();
  }

  /// Checks whether a specific kana character is already mastered[cite: 12].
  bool isKanaMastered(String kana) {
    return _masteredKana.contains(kana);
  }

  // ===========================================================================
  // PRACTICE PERSISTENCE METHODS (Flashcards & Word Builder)[cite: 12]
  // ===========================================================================

  /// Increments total reviewed flashcard count in SharedPreferences[cite: 12].
  Future<void> recordFlashcardReviewed() async {
    _flashcardsReviewedCount += 1;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setInt('flashcardsReviewedCount', _flashcardsReviewedCount);
    notifyListeners();
  }

  /// Records a completed vocabulary word from Word Builder or practice activities[cite: 12].
  /// Optimized with direct rune traversal to avoid O(N²) iterable overhead[cite: 12].
  Future<void> recordWordCompleted({
    required String word,
    bool wasCorrectFirstTry = true,
  }) async {
    _wordsCompletedCount += 1;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final writes = <Future<bool>>[
      prefs.setInt('wordsCompletedCount', _wordsCompletedCount),
    ];

    if (word.isNotEmpty && !_masteredWords.contains(word)) {
      _masteredWords.add(word);
      writes.add(prefs.setStringList('masteredWords', _masteredWords.toList()));
    }

    // Add individual kana characters with O(N) iteration[cite: 12]
    bool kanaAdded = false;
    for (final rune in word.runes) {
      final char = String.fromCharCode(rune);
      if (char.isNotEmpty && !_masteredKana.contains(char)) {
        _masteredKana.add(char);
        if (_isHiragana(char)) _masteredHiraganaCount++;
        if (_isKatakana(char)) _masteredKatakanaCount++;
        kanaAdded = true;
      }
    }

    if (kanaAdded) {
      writes.add(prefs.setStringList('masteredKana', _masteredKana.toList()));
    }

    await Future.wait(writes);
    notifyListeners();
  }

  /// Checks if a vocabulary word is already marked as mastered[cite: 12].
  bool isWordMastered(String word) {
    return _masteredWords.contains(word);
  }

  // ===========================================================================
  // DATA MANAGEMENT & RESET METHODS[cite: 12]
  // ===========================================================================

  /// Resets only mastered Kana characters and mastered vocabulary words[cite: 12].
  /// Preserves the user's study streak, calendar dots, and profile settings[cite: 12].
  Future<void> resetMasteredKana() async {
    _masteredKana.clear();
    _masteredHiraganaCount = 0;
    _masteredKatakanaCount = 0;
    _masteredWords.clear();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('masteredKana'),
      prefs.remove('masteredWords'),
    ]);
    notifyListeners();
  }

  /// Resets all row question progress checkpoints, unlocked row flags, and custom difficulty tags[cite: 12].
  /// Enforces sequential row locks back to 'A row'[cite: 12].
  Future<void> resetRowCheckpoints() async {
    unlockAllRows = false;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('unlockAllRows', false);

    final keys = prefs
        .getKeys()
        .where(
          (k) =>
              k.startsWith('row_progress_') ||
              k.startsWith('row_completed_') ||
              k.startsWith('kana_difficulty_'),
        )
        .toList();

    if (keys.isNotEmpty) {
      await Future.wait(keys.map((k) => prefs.remove(k)));
    }
    notifyListeners();
  }

  /// Complete reset: erases mastered characters, row progress, streaks, and practice metrics[cite: 12].
  /// User preferences (username, avatar, TTS settings) are preserved[cite: 12].
  Future<void> resetAllProgress() async {
    unlockAllRows = false;
    _masteredKana.clear();
    _masteredHiraganaCount = 0;
    _masteredKatakanaCount = 0;
    _masteredWords.clear();
    _wordsCompletedCount = 0;
    _flashcardsReviewedCount = 0;
    _streakDays = 0;
    _lastActiveDate = '';
    _activeDaysThisWeek = List.filled(7, false);

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final removes = <Future<bool>>[
      prefs.remove('masteredKana'),
      prefs.remove('masteredWords'),
      prefs.remove('wordsCompletedCount'),
      prefs.remove('flashcardsReviewedCount'),
      prefs.remove('streakDays'),
      prefs.remove('lastActiveDate'),
      prefs.remove('unlockAllRows'),
    ];

    for (int i = 0; i < 7; i++) {
      removes.add(prefs.remove('activeDay_$i'));
    }

    await Future.wait(removes);
    await resetRowCheckpoints();
    _updateStreak();
    notifyListeners();
  }

  // --- GETTERS ---[cite: 12]
  int get streakDays => _streakDays;
  List<bool> get activeDaysThisWeek => _activeDaysThisWeek;
  int get totalMastered => _masteredKana.length;

  // Cached O(1) getters for dashboard and progress card animations
  int get masteredHiraganaCount => _masteredHiraganaCount;
  int get masteredKatakanaCount => _masteredKatakanaCount;

  // Practice getters[cite: 12]
  int get wordsCompletedCount => _wordsCompletedCount;
  int get flashcardsReviewedCount => _flashcardsReviewedCount;
  int get totalMasteredWords => _masteredWords.length;
  Set<String> get masteredWords => Set.unmodifiable(_masteredWords);

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
