import 'package:flutter/material.dart';
import '../features/writing/data/kana_data.dart'; // Imports the structured kana data[cite: 19, 20]
import '../features/writing/screens/writing_lesson_screen.dart'; // Imports the lesson screen[cite: 19, 22]

/// A lightweight compatibility bridge so LearnScreen can continue calling `WriteScreen`[cite: 18, 23]
/// without requiring rewrites of its navigation handlers[cite: 18].
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
    // 1. Map incoming character dictionaries to our verified KanaCharacter stroke models[cite: 20]
    final List<KanaCharacter> lessonCharacters = characters.map((map) {
      final symbol = map['kana'] ?? '';
      final romaji = map['romaji'] ?? '';

      // Look up verified character data from kana_data.dart[cite: 20]
      final found = initialKanaData.findByKana(symbol);
      if (found != null) {
        return found;
      }

      // Fallback placeholder if character is not yet mapped in initialKanaData[cite: 20]
      return KanaCharacter(
        id: 'fallback_$symbol',
        kana: symbol,
        romaji: romaji,
        type: 'hiragana',
        strokes: const [],
      );
    }).toList();

    // 2. Delegate directly to the comprehensive WritingLessonScreen[cite: 22]
    return WritingLessonScreen(lessonCharacters: lessonCharacters);
  }
}
