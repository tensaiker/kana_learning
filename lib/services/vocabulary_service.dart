import 'dart:convert';
import 'package:flutter/services.dart';
import '../features/writing/data/vocabulary_data.dart';
import 'progress_service.dart';

/// Central service managing offline JSON vocabulary loading, indexing,
/// and dynamic prerequisite unlock filtering based on user lesson progress.
class VocabularyService {
  static final VocabularyService instance = VocabularyService._internal();
  VocabularyService._internal();

  List<WordBuilderQuestion> _words = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<WordBuilderQuestion> get allWords => List.unmodifiable(_words);

  /// Loads assets/data/vocabulary.json once at app startup[cite: 13]
  Future<void> init() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/vocabulary.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);

      _words = jsonList.map((item) {
        final List<String> syllables = List<String>.from(
          item['syllables'] ?? [],
        );
        final List<String> kanaSyllables = List<String>.from(
          item['kanaSyllables'] ?? [],
        );

        return WordBuilderQuestion(
          kana: item['kana'] ?? '',
          romaji: item['romaji'] ?? '',
          english: item['english'] ?? '',
          isHiragana: item['isHiragana'] ?? true,
          syllables: syllables,
          kanaSyllables: kanaSyllables,
        );
      }).toList();

      _isLoaded = true;
    } catch (e) {
      // Fallback: If JSON is missing or ill-formed during development, load code default[cite: 13]
      _words = List.from(allVocabulary);
      _isLoaded = true;
    }
  }

  // ===========================================================================
  // DYNAMIC UNLOCK & PREREQUISITE FILTERING
  // ===========================================================================

  /// Checks whether a single kana syllable/character is unlocked based on lesson row progress.
  /// Neutral characters like 'ー' and 'ッ'/'っ' automatically evaluate to true.
  bool isKanaUnlocked(String syllable, {required bool isHiragana}) {
    if (syllable == 'ー' || syllable == 'ッ' || syllable == 'っ') return true;

    final ps = ProgressService.instance;
    if (ps.unlockAllRows) return true;

    final systemName = isHiragana ? 'Hiragana' : 'Katakana';
    final rowTitle = kanaToRowTitleMap[syllable];

    // If the syllable is mapped to a row, check if that row is unlocked;
    // Otherwise fallback to individual character mastery check.
    if (rowTitle != null) {
      return ps.isRowUnlocked(writingSystem: systemName, rowTitle: rowTitle);
    }

    return ps.isKanaMastered(syllable);
  }

  /// Verifies if a complete word is unlocked by ensuring all of its constituent
  /// kana syllables have been cleared in the Learn tab.
  bool isWordUnlocked(WordBuilderQuestion word) {
    return word.isUnlocked(
      (syllable) => isKanaUnlocked(syllable, isHiragana: word.isHiragana),
    );
  }

  /// Returns the titles of all prerequisite lesson rows still required to unlock this word.
  List<String> getMissingPrerequisiteRows(WordBuilderQuestion word) {
    final missingSyllables = word.getMissingPrerequisites(
      (syllable) => isKanaUnlocked(syllable, isHiragana: word.isHiragana),
    );

    final Set<String> rows = {};
    for (final s in missingSyllables) {
      final rowTitle = kanaToRowTitleMap[s];
      if (rowTitle != null) {
        rows.add(rowTitle);
      }
    }
    return rows.toList();
  }

  // ===========================================================================
  // FILTERING & SEARCH
  // ===========================================================================

  /// Filters words by writing system, syllable count, and optional unlock enforcement.
  ///
  /// Optimization:
  /// - Uses syllable length (`w.length`) rather than raw string length to match user-facing word lengths.
  /// - Set [onlyUnlocked] to `true` (default) for gameplay so locked words containing
  ///   unlearned characters never appear in Word Builder rounds.
  List<WordBuilderQuestion> getWordsForGame({
    required bool isHiragana,
    int minLength = 0,
    int maxLength = 99,
    bool onlyUnlocked = true,
  }) {
    final pool = _words.isNotEmpty ? _words : allVocabulary;

    return pool.where((w) {
      if (w.isHiragana != isHiragana) return false;

      final int len = w.length;
      if (len < minLength || len > maxLength) return false;

      if (onlyUnlocked && !isWordUnlocked(w)) return false;

      return true;
    }).toList();
  }

  /// Searches words by plain kana, romaji, or english definition.
  ///
  /// Optimization:
  /// - Strips whitespace from query and searches against both spaced and unspaced kana.
  List<WordBuilderQuestion> searchWords({
    required bool isHiragana,
    String query = '',
  }) {
    final pool = _words.isNotEmpty ? _words : allVocabulary;
    final cleanQuery = query.trim().toLowerCase();

    return pool.where((w) {
      if (w.isHiragana != isHiragana) return false;
      if (cleanQuery.isEmpty) return true;

      return w.plainKana.contains(cleanQuery) ||
          w.kana.contains(cleanQuery) ||
          w.romaji.toLowerCase().contains(cleanQuery) ||
          w.english.toLowerCase().contains(cleanQuery);
    }).toList();
  }
}
