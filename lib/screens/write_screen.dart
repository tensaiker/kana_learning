import 'package:flutter/material.dart';
import '../features/writing/data/kana_data.dart';
import '../features/writing/screens/writing_lesson_screen.dart';

/// A lightweight compatibility bridge connecting `LearnScreen` row navigation
/// directly to the interactive 4-stage canvas in `WritingLessonScreen`.
///
/// Usage:
/// Navigating to this screen from any "Write" button immediately resolves stroke
/// vectors and presents the handwriting practice lesson without intermediate UI.
///
/// Responsibilities:
/// 1. Filters out blank spacer placeholders (e.g., empty slots in Ya/Wa rows) in a single pass.
/// 2. Performs O(1) lookups via `initialKanaData.findByKana(...)` to supply stroke data.
/// 3. Provides a graceful fallback [KanaCharacter] if a stroke definition is missing[cite: 12].
class WriteScreen extends StatelessWidget {
  final String rowTitle;
  final List<Map<String, String>> characters;

  const WriteScreen({
    super.key,
    required this.rowTitle,
    required this.characters,
  });

  /// Resolves the raw character maps into verified [KanaCharacter] models in a single pass.
  List<KanaCharacter> _resolveLessonCharacters() {
    // Check title case before allocating a lowered string
    final bool isKatakanaByTitle =
        rowTitle.contains('Katakana') ||
        rowTitle.toLowerCase().contains('katakana');

    final List<KanaCharacter> resolved = [];

    for (final map in characters) {
      // 1. Single trim and empty check to discard layout spacers
      final String symbol = (map['kana'] ?? '').trim();
      if (symbol.isEmpty) continue;

      // 2. High-speed O(1) hash map lookup from kana_data.dart
      final KanaCharacter? matched = initialKanaData.findByKana(symbol);
      if (matched != null) {
        resolved.add(matched);
        continue; // Skip fallback generation if matched
      }

      // 3. Script detection via title flag or Katakana Unicode range (U+30A0 to U+30FF)
      final int firstCodeUnit = symbol.codeUnitAt(0);
      final bool isKatakana =
          isKatakanaByTitle ||
          (firstCodeUnit >= 0x30A0 && firstCodeUnit <= 0x30FF);

      final String romaji = (map['romaji'] ?? '').trim();

      // 4. Safe fallback model to prevent runtime null exceptions
      resolved.add(
        KanaCharacter(
          id: 'fallback_${isKatakana ? 'k' : 'h'}_$symbol',
          kana: symbol,
          romaji: romaji,
          type: isKatakana ? 'katakana' : 'hiragana',
          strokes: const [],
        ),
      );
    }

    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    // Hands off verified stroke models directly to the writing lesson engine
    return WritingLessonScreen(lessonCharacters: _resolveLessonCharacters());
  }
}
