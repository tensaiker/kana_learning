import 'package:flutter/material.dart';

/// Represents a single stroke path made of sequential normalized coordinate points.
class KanaStroke {
  /// Normalized points (0.0 to 1.0 relative to the canvas width and height).
  final List<Offset> points;

  const KanaStroke(this.points);

  /// Convenience getter for stroke starting point.
  Offset get startPoint => points.first;

  /// Convenience getter for stroke ending point.
  Offset get endPoint => points.last;
}

/// Represents a Japanese kana character with metadata and ordered stroke data.
class KanaCharacter {
  final String id;
  final String kana;
  final String romaji;
  final String type; // 'hiragana' or 'katakana'
  final List<KanaStroke> strokes;

  const KanaCharacter({
    required this.id,
    required this.kana,
    required this.romaji,
    required this.type,
    required this.strokes,
  });

  /// Total number of strokes for this character.
  int get strokeCount => strokes.length;
}

/// Normalized stroke-path data for the 5 basic Hiragana and 5 basic Katakana vowels.
///
/// Coordinates are mapped in a normalized 0.0 to 1.0 bounding box:
/// - (0.0, 0.0) is the top-left corner.
/// - (1.0, 1.0) is the bottom-right corner.
/// - Standard stroke sequence, start points, and direction conventions are preserved.
final List<KanaCharacter> initialKanaData = [
  // ===========================================================================
  // HIRAGANA VOWELS (あ, い, う, え, お)
  // ===========================================================================

  // --- あ (a) : 3 Strokes ---
  KanaCharacter(
    id: 'h_a',
    kana: 'あ',
    romaji: 'a',
    type: 'hiragana',
    strokes: [
      // Stroke 1: Upper horizontal line (Left to Right)
      KanaStroke([
        const Offset(0.24, 0.34),
        const Offset(0.50, 0.34),
        const Offset(0.76, 0.34),
      ]),
      // Stroke 2: Central downward curve (Top to Bottom)
      KanaStroke([
        const Offset(0.50, 0.16),
        const Offset(0.49, 0.45),
        const Offset(0.46, 0.78),
      ]),
      // Stroke 3: Bottom loop & tail (Right downward diagonal -> loop left -> sweep right)
      KanaStroke([
        const Offset(0.62, 0.42),
        const Offset(0.42, 0.60),
        const Offset(0.28, 0.70),
        const Offset(0.20, 0.54),
        const Offset(0.32, 0.38),
        const Offset(0.52, 0.38),
        const Offset(0.76, 0.54),
        const Offset(0.78, 0.74),
        const Offset(0.68, 0.86),
      ]),
    ],
  ),

  // --- い (i) : 2 Strokes ---
  KanaCharacter(
    id: 'h_i',
    kana: 'い',
    romaji: 'i',
    type: 'hiragana',
    strokes: [
      // Stroke 1: Left downward curve with an upward hook at bottom
      KanaStroke([
        const Offset(0.32, 0.24),
        const Offset(0.30, 0.50),
        const Offset(0.30, 0.72),
        const Offset(0.38, 0.62), // upward release hook
      ]),
      // Stroke 2: Right shorter descending stroke
      KanaStroke([
        const Offset(0.68, 0.32),
        const Offset(0.70, 0.48),
        const Offset(0.72, 0.62),
      ]),
    ],
  ),

  // --- う (u) : 2 Strokes ---
  KanaCharacter(
    id: 'h_u',
    kana: 'う',
    romaji: 'u',
    type: 'hiragana',
    strokes: [
      // Stroke 1: Top short angled dash (Left-high to Right-low)
      KanaStroke([const Offset(0.42, 0.18), const Offset(0.58, 0.24)]),
      // Stroke 2: Rounded sweeping curve (Left -> arch right -> sweep down-left)
      KanaStroke([
        const Offset(0.36, 0.40),
        const Offset(0.58, 0.36),
        const Offset(0.70, 0.48),
        const Offset(0.68, 0.66),
        const Offset(0.50, 0.82),
        const Offset(0.32, 0.80),
      ]),
    ],
  ),

  // --- え (e) : 2 Strokes ---
  KanaCharacter(
    id: 'h_e',
    kana: 'え',
    romaji: 'e',
    type: 'hiragana',
    strokes: [
      // Stroke 1: Top short angled dash
      KanaStroke([const Offset(0.44, 0.16), const Offset(0.56, 0.24)]),
      // Stroke 2: Z-zigzag into rounded wave and horizontal finish
      KanaStroke([
        const Offset(0.26, 0.44),
        const Offset(0.72, 0.40),
        const Offset(0.32, 0.74),
        const Offset(0.52, 0.66),
        const Offset(0.70, 0.74),
        const Offset(0.78, 0.82),
      ]),
    ],
  ),

  // --- お (o) : 3 Strokes ---
  KanaCharacter(
    id: 'h_o',
    kana: 'お',
    romaji: 'o',
    type: 'hiragana',
    strokes: [
      // Stroke 1: Horizontal line (Left to Right)
      KanaStroke([const Offset(0.24, 0.34), const Offset(0.74, 0.34)]),
      // Stroke 2: Vertical stem -> lower-left loop -> wide right arc
      KanaStroke([
        const Offset(0.48, 0.16),
        const Offset(0.48, 0.66),
        const Offset(0.32, 0.78),
        const Offset(0.22, 0.62),
        const Offset(0.42, 0.52),
        const Offset(0.68, 0.58),
        const Offset(0.74, 0.74),
        const Offset(0.66, 0.84),
      ]),
      // Stroke 3: Upper-right accent dash
      KanaStroke([const Offset(0.70, 0.20), const Offset(0.82, 0.30)]),
    ],
  ),

  // ===========================================================================
  // KATAKANA VOWELS (ア, イ, ウ, エ, オ)
  // ===========================================================================

  // --- ア (a) : 2 Strokes ---
  KanaCharacter(
    id: 'k_a',
    kana: 'ア',
    romaji: 'a',
    type: 'katakana',
    strokes: [
      // Stroke 1: Top horizontal line with sharp downward-left hook
      KanaStroke([
        const Offset(0.24, 0.28),
        const Offset(0.76, 0.28),
        const Offset(0.54, 0.50),
      ]),
      // Stroke 2: Leftward downward curve starting below the fold
      KanaStroke([
        const Offset(0.54, 0.44),
        const Offset(0.48, 0.64),
        const Offset(0.32, 0.80),
      ]),
    ],
  ),

  // --- イ (i) : 2 Strokes ---
  KanaCharacter(
    id: 'k_i',
    kana: 'イ',
    romaji: 'i',
    type: 'katakana',
    strokes: [
      // Stroke 1: Slanted leftward diagonal (Top to Bottom-Left)
      KanaStroke([
        const Offset(0.56, 0.18),
        const Offset(0.44, 0.38),
        const Offset(0.30, 0.62),
      ]),
      // Stroke 2: Vertical stem starting from mid-stroke 1 downward
      KanaStroke([
        const Offset(0.46, 0.40),
        const Offset(0.46, 0.62),
        const Offset(0.46, 0.84),
      ]),
    ],
  ),

  // --- ウ (u) : 3 Strokes ---
  KanaCharacter(
    id: 'k_u',
    kana: 'ウ',
    romaji: 'u',
    type: 'katakana',
    strokes: [
      // Stroke 1: Top central vertical dot/dash
      KanaStroke([const Offset(0.50, 0.14), const Offset(0.50, 0.26)]),
      // Stroke 2: Left short downward tick
      KanaStroke([const Offset(0.30, 0.34), const Offset(0.28, 0.48)]),
      // Stroke 3: Horizontal line across from stroke 2, with downward-left hook
      KanaStroke([
        const Offset(0.28, 0.38),
        const Offset(0.74, 0.38),
        const Offset(0.66, 0.58),
        const Offset(0.48, 0.82),
      ]),
    ],
  ),

  // --- エ (e) : 3 Strokes ---
  KanaCharacter(
    id: 'k_e',
    kana: 'エ',
    romaji: 'e',
    type: 'katakana',
    strokes: [
      // Stroke 1: Upper horizontal bar (Left to Right)
      KanaStroke([const Offset(0.28, 0.22), const Offset(0.72, 0.22)]),
      // Stroke 2: Central vertical bar (Top to Bottom)
      KanaStroke([const Offset(0.50, 0.22), const Offset(0.50, 0.78)]),
      // Stroke 3: Lower horizontal bar (Left to Right, slightly wider)
      KanaStroke([const Offset(0.20, 0.78), const Offset(0.80, 0.78)]),
    ],
  ),

  // --- オ (o) : 3 Strokes ---
  KanaCharacter(
    id: 'k_o',
    kana: 'オ',
    romaji: 'o',
    type: 'katakana',
    strokes: [
      // Stroke 1: Horizontal bar (Left to Right)
      KanaStroke([const Offset(0.22, 0.32), const Offset(0.78, 0.32)]),
      // Stroke 2: Vertical bar with bottom-left hook
      KanaStroke([
        const Offset(0.52, 0.16),
        const Offset(0.52, 0.78),
        const Offset(0.42, 0.68), // hook up-left
      ]),
      // Stroke 3: Left-descending diagonal stroke
      KanaStroke([
        const Offset(0.50, 0.38),
        const Offset(0.38, 0.56),
        const Offset(0.24, 0.76),
      ]),
    ],
  ),
];

/// Helper extension to query kana data conveniently.
extension KanaListExtension on List<KanaCharacter> {
  /// Finds a character by its literal Japanese symbol (e.g., 'あ' or 'ア').
  KanaCharacter? findByKana(String kana) {
    try {
      return firstWhere((element) => element.kana == kana);
    } catch (_) {
      return null;
    }
  }

  /// Filters characters by writing system ('hiragana' or 'katakana').
  List<KanaCharacter> filterByType(String type) {
    return where((element) => element.type == type).toList();
  }
}
