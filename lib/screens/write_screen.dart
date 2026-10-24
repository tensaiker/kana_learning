import 'package:flutter/material.dart';
import '../features/writing/data/kana_data.dart';
import '../features/writing/screens/writing_lesson_screen.dart';

/// A lightweight compatibility bridge that connects the navigation in `LearnScreen`
/// with the interactive handwriting canvas in `WritingLessonScreen`.
///
/// Responsibilities:
/// 1. Filters out empty placeholder slots (e.g., the blank spots in Ya and Wa rows).
/// 2. Performs O(1) lookups in `initialKanaData` to retrieve stroke coordinates.
/// 3. Provides a reliable fallback model if a character does not yet have vector paths.
class WriteScreen extends StatelessWidget {
  final String rowTitle;
  final List<Map<String, String>> characters;

  const WriteScreen({
    super.key,
    required this.rowTitle,
    required this.characters,
  });

  @override
  Widget build(BuildContext context) {
    // Determine whether the active lesson is Katakana based on row title metadata
    final bool isKatakanaLesson = rowTitle.toLowerCase().contains('katakana');

    // 1. Filter out empty slots and resolve stroke models
    final List<KanaCharacter> lessonCharacters = characters
        .where((map) {
          final symbol = map['kana']?.trim() ?? '';
          return symbol.isNotEmpty; // Discard blank row fillers
        })
        .map((map) {
          final symbol = map['kana']!.trim();
          final romaji = (map['romaji'] ?? '').trim();

          // 2. High-speed O(1) hash table lookup from kana_data.dart
          final found = initialKanaData.findByKana(symbol);
          if (found != null) {
            return found;
          }

          // 3. Fallback script detection (via title or Katakana Unicode range U+30A0..U+30FF)
          final bool isKatakana =
              isKatakanaLesson ||
              (symbol.isNotEmpty &&
                  symbol.codeUnitAt(0) >= 0x30A0 &&
                  symbol.codeUnitAt(0) <= 0x30FF);

          // Graceful fallback if stroke coordinates are not yet mapped
          return KanaCharacter(
            id: 'fallback_${isKatakana ? 'k' : 'h'}_$symbol',
            kana: symbol,
            romaji: romaji,
            type: isKatakana ? 'katakana' : 'hiragana',
            strokes: const [],
          );
        })
        .toList(growable: false);

    // 4. Hand off verified stroke data directly to WritingLessonScreen
    return WritingLessonScreen(lessonCharacters: lessonCharacters);
  }
}
