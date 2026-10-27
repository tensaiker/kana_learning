import 'package:flutter/material.dart';
import '../features/writing/data/kana_data.dart';
import '../features/writing/screens/writing_lesson_screen.dart';

/// A lightweight compatibility bridge connecting `LearnScreen` row navigation
/// directly to the interactive handwriting canvas in `WritingLessonScreen`.
///
/// Features & Guidelines:
/// 1. Filters out blank layout spacers (e.g., empty slots in Ya/Wa rows) in a single pass.
/// 2. Performs O(1) lookups via `initialKanaData.findByKana(...)` to supply stroke data.
/// 3. Provides a graceful fallback [KanaCharacter] if a stroke definition is missing.
/// 4. Memoizes resolved characters in `initState` to eliminate redundant conversions during rebuilds.
class WriteScreen extends StatefulWidget {
  final String rowTitle;
  final String? writingSystem; // 'Hiragana' or 'Katakana'
  final List<Map<String, String>> characters;

  const WriteScreen({
    super.key,
    required this.rowTitle,
    this.writingSystem,
    required this.characters,
  });

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  late final List<KanaCharacter> _resolvedCharacters;

  @override
  void initState() {
    super.initState();
    _resolvedCharacters = _resolveLessonCharacters();
  }

  /// Determines the script system (Hiragana vs. Katakana) with Unicode fallback.
  String _resolveWritingSystem() {
    if (widget.writingSystem != null && widget.writingSystem!.isNotEmpty) {
      return widget.writingSystem!;
    }

    final lowerTitle = widget.rowTitle.toLowerCase();
    if (lowerTitle.contains('katakana')) return 'Katakana';
    if (lowerTitle.contains('hiragana')) return 'Hiragana';

    for (final map in widget.characters) {
      final String symbol = (map['kana'] ?? '').trim();
      if (symbol.isNotEmpty) {
        final codeUnit = symbol.codeUnitAt(0);
        // Katakana Unicode range: U+30A0 to U+30FF
        if (codeUnit >= 0x30A0 && codeUnit <= 0x30FF) {
          return 'Katakana';
        }
      }
    }
    return 'Hiragana';
  }

  /// Resolves character maps into verified [KanaCharacter] models in a single pass.
  List<KanaCharacter> _resolveLessonCharacters() {
    final bool isKatakana = (_resolveWritingSystem() == 'Katakana');
    final List<KanaCharacter> resolved = [];

    for (final map in widget.characters) {
      // 1. Single trim and empty check to discard layout spacers
      final String symbol = (map['kana'] ?? '').trim();
      if (symbol.isEmpty) continue;

      // 2. High-speed O(1) hash map lookup from kana_data.dart
      final KanaCharacter? matched = initialKanaData.findByKana(symbol);
      if (matched != null) {
        resolved.add(matched);
        continue;
      }

      final String romaji = (map['romaji'] ?? '').trim();

      // 3. Safe fallback model to prevent runtime null exceptions
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
    // Hands off verified stroke models directly to WritingLessonScreen
    return WritingLessonScreen(lessonCharacters: _resolvedCharacters);
  }
}
