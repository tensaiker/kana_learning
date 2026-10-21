import 'dart:convert';
import 'package:flutter/services.dart';
import '../features/writing/data/vocabulary_data.dart';

/// Central service managing offline JSON vocabulary loading and indexing.
class VocabularyService {
  static final VocabularyService instance = VocabularyService._internal();
  VocabularyService._internal();

  List<WordBuilderQuestion> _words = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<WordBuilderQuestion> get allWords => List.unmodifiable(_words);

  /// Loads assets/data/vocabulary.json once at app startup
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
      // Fallback: If JSON is missing or ill-formed during development, load code default
      _words = List.from(allVocabulary);
      _isLoaded = true;
    }
  }

  /// Filters words by writing system and character count
  List<WordBuilderQuestion> getWordsForGame({
    required bool isHiragana,
    int minLength = 0,
    int maxLength = 99,
  }) {
    return _words.where((w) {
      final int len = w.kana.length;
      return w.isHiragana == isHiragana && len >= minLength && len <= maxLength;
    }).toList();
  }

  /// Searches words by kana, romaji, or english definition
  List<WordBuilderQuestion> searchWords({
    required bool isHiragana,
    String query = '',
  }) {
    final cleanQuery = query.trim().toLowerCase();
    return _words.where((w) {
      if (w.isHiragana != isHiragana) return false;
      if (cleanQuery.isEmpty) return true;
      return w.kana.contains(cleanQuery) ||
          w.romaji.toLowerCase().contains(cleanQuery) ||
          w.english.toLowerCase().contains(cleanQuery);
    }).toList();
  }
}
