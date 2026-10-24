import 'package:flutter/material.dart';

/// Represents a single stroke path made of sequential normalized coordinate points.
class KanaStroke {
  /// Normalized points (0.0 to 1.0 relative to canvas width and height).
  final List<Offset> points;

  const KanaStroke(this.points);

  /// Convenience getter for the stroke starting point.
  Offset get startPoint => points.first;

  /// Convenience getter for the stroke ending point.
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

// =============================================================================
// STANDARD DIACRITIC STROKES (DAKUTEN & HANDAKUTEN)
// =============================================================================

/// Standard two-stroke Dakuten (voiced mark) placed in the upper-right corner.
const List<KanaStroke> _standardDakutenStrokes = [
  KanaStroke([Offset(0.74, 0.14), Offset(0.84, 0.22)]),
  KanaStroke([Offset(0.82, 0.12), Offset(0.92, 0.20)]),
];

/// Standard circular Handakuten (semi-voiced mark) placed in the upper-right corner.
const List<KanaStroke> _standardHandakutenStrokes = [
  KanaStroke([
    Offset(0.82, 0.14),
    Offset(0.76, 0.20),
    Offset(0.82, 0.26),
    Offset(0.88, 0.20),
    Offset(0.82, 0.14),
  ]),
];

// =============================================================================
// BASE KANA DATASET (46 HIRAGANA + 46 KATAKANA)
// =============================================================================

const List<KanaCharacter> _baseKanaData = [
  // ---------------------------------------------------------------------------
  // 1. HIRAGANA A ROW (a, i, u, e, o)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'h_a',
    kana: 'あ',
    romaji: 'a',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.24, 0.34), Offset(0.50, 0.34), Offset(0.76, 0.34)]),
      KanaStroke([Offset(0.50, 0.16), Offset(0.49, 0.45), Offset(0.46, 0.78)]),
      KanaStroke([
        Offset(0.62, 0.42),
        Offset(0.42, 0.60),
        Offset(0.28, 0.70),
        Offset(0.20, 0.54),
        Offset(0.32, 0.38),
        Offset(0.52, 0.38),
        Offset(0.76, 0.54),
        Offset(0.78, 0.74),
        Offset(0.68, 0.86),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_i',
    kana: 'い',
    romaji: 'i',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.32, 0.24),
        Offset(0.30, 0.50),
        Offset(0.30, 0.72),
        Offset(0.38, 0.62),
      ]),
      KanaStroke([Offset(0.68, 0.32), Offset(0.70, 0.48), Offset(0.72, 0.62)]),
    ],
  ),
  KanaCharacter(
    id: 'h_u',
    kana: 'う',
    romaji: 'u',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.42, 0.18), Offset(0.58, 0.24)]),
      KanaStroke([
        Offset(0.36, 0.40),
        Offset(0.58, 0.36),
        Offset(0.70, 0.48),
        Offset(0.68, 0.66),
        Offset(0.50, 0.82),
        Offset(0.32, 0.80),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_e',
    kana: 'え',
    romaji: 'e',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.44, 0.16), Offset(0.56, 0.24)]),
      KanaStroke([
        Offset(0.26, 0.44),
        Offset(0.72, 0.40),
        Offset(0.32, 0.74),
        Offset(0.52, 0.66),
        Offset(0.70, 0.74),
        Offset(0.78, 0.82),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_o',
    kana: 'お',
    romaji: 'o',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.24, 0.34), Offset(0.74, 0.34)]),
      KanaStroke([
        Offset(0.48, 0.16),
        Offset(0.48, 0.66),
        Offset(0.32, 0.78),
        Offset(0.22, 0.62),
        Offset(0.42, 0.52),
        Offset(0.68, 0.58),
        Offset(0.74, 0.74),
        Offset(0.66, 0.84),
      ]),
      KanaStroke([Offset(0.70, 0.20), Offset(0.82, 0.30)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 2. HIRAGANA KA ROW (ka, ki, ku, ke, ko)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'h_ka',
    kana: 'か',
    romaji: 'ka',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.28, 0.36),
        Offset(0.48, 0.34),
        Offset(0.48, 0.62),
        Offset(0.44, 0.74),
        Offset(0.36, 0.66),
      ]),
      KanaStroke([Offset(0.36, 0.20), Offset(0.32, 0.48), Offset(0.26, 0.78)]),
      KanaStroke([Offset(0.68, 0.26), Offset(0.78, 0.38)]),
    ],
  ),
  KanaCharacter(
    id: 'h_ki',
    kana: 'き',
    romaji: 'ki',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.30, 0.32), Offset(0.68, 0.28)]),
      KanaStroke([Offset(0.24, 0.46), Offset(0.74, 0.42)]),
      KanaStroke([Offset(0.58, 0.18), Offset(0.48, 0.58), Offset(0.40, 0.52)]),
      KanaStroke([Offset(0.36, 0.68), Offset(0.48, 0.78), Offset(0.64, 0.72)]),
    ],
  ),
  KanaCharacter(
    id: 'h_ku',
    kana: 'く',
    romaji: 'ku',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.64, 0.24),
        Offset(0.48, 0.36),
        Offset(0.34, 0.50),
        Offset(0.50, 0.64),
        Offset(0.66, 0.76),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_ke',
    kana: 'け',
    romaji: 'ke',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.28, 0.20),
        Offset(0.26, 0.50),
        Offset(0.26, 0.76),
        Offset(0.34, 0.68),
      ]),
      KanaStroke([Offset(0.48, 0.38), Offset(0.76, 0.38)]),
      KanaStroke([Offset(0.64, 0.24), Offset(0.64, 0.52), Offset(0.58, 0.80)]),
    ],
  ),
  KanaCharacter(
    id: 'h_ko',
    kana: 'こ',
    romaji: 'ko',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.32, 0.34), Offset(0.68, 0.32), Offset(0.60, 0.38)]),
      KanaStroke([Offset(0.30, 0.68), Offset(0.50, 0.72), Offset(0.70, 0.66)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 3. HIRAGANA SA ROW (sa, shi, su, se, so)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'h_sa',
    kana: 'さ',
    romaji: 'sa',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.28, 0.36), Offset(0.70, 0.32)]),
      KanaStroke([Offset(0.56, 0.20), Offset(0.46, 0.54), Offset(0.38, 0.48)]),
      KanaStroke([Offset(0.34, 0.68), Offset(0.50, 0.78), Offset(0.66, 0.70)]),
    ],
  ),
  KanaCharacter(
    id: 'h_shi',
    kana: 'し',
    romaji: 'shi',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.38, 0.22),
        Offset(0.38, 0.60),
        Offset(0.44, 0.78),
        Offset(0.60, 0.80),
        Offset(0.72, 0.64),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_su',
    kana: 'す',
    romaji: 'su',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.24, 0.34), Offset(0.76, 0.34)]),
      KanaStroke([
        Offset(0.50, 0.16),
        Offset(0.50, 0.48),
        Offset(0.36, 0.56),
        Offset(0.44, 0.66),
        Offset(0.54, 0.58),
        Offset(0.48, 0.82),
        Offset(0.38, 0.86),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_se',
    kana: 'せ',
    romaji: 'se',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.24, 0.40), Offset(0.76, 0.38)]),
      KanaStroke([Offset(0.66, 0.22), Offset(0.66, 0.64), Offset(0.56, 0.60)]),
      KanaStroke([
        Offset(0.38, 0.26),
        Offset(0.38, 0.68),
        Offset(0.46, 0.78),
        Offset(0.78, 0.76),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_so',
    kana: 'そ',
    romaji: 'so',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.34, 0.26),
        Offset(0.66, 0.24),
        Offset(0.34, 0.48),
        Offset(0.66, 0.46),
        Offset(0.48, 0.64),
        Offset(0.68, 0.74),
        Offset(0.58, 0.84),
        Offset(0.40, 0.82),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 4. HIRAGANA TA ROW (ta, chi, tsu, te, to)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'h_ta',
    kana: 'た',
    romaji: 'ta',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.22, 0.36), Offset(0.48, 0.34)]),
      KanaStroke([Offset(0.38, 0.20), Offset(0.28, 0.74)]),
      KanaStroke([Offset(0.52, 0.42), Offset(0.74, 0.40)]),
      KanaStroke([Offset(0.52, 0.64), Offset(0.66, 0.70), Offset(0.78, 0.62)]),
    ],
  ),
  KanaCharacter(
    id: 'h_chi',
    kana: 'ち',
    romaji: 'chi',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.30, 0.34), Offset(0.70, 0.32)]),
      KanaStroke([
        Offset(0.52, 0.18),
        Offset(0.44, 0.52),
        Offset(0.72, 0.52),
        Offset(0.74, 0.74),
        Offset(0.50, 0.84),
        Offset(0.32, 0.78),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_tsu',
    kana: 'つ',
    romaji: 'tsu',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.26, 0.38),
        Offset(0.68, 0.32),
        Offset(0.74, 0.50),
        Offset(0.64, 0.72),
        Offset(0.42, 0.82),
        Offset(0.26, 0.80),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_te',
    kana: 'て',
    romaji: 'te',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.28, 0.34),
        Offset(0.72, 0.34),
        Offset(0.46, 0.54),
        Offset(0.64, 0.66),
        Offset(0.68, 0.78),
        Offset(0.48, 0.84),
        Offset(0.36, 0.82),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_to',
    kana: 'と',
    romaji: 'to',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.42, 0.22), Offset(0.52, 0.44)]),
      KanaStroke([
        Offset(0.34, 0.44),
        Offset(0.68, 0.56),
        Offset(0.68, 0.76),
        Offset(0.44, 0.84),
        Offset(0.32, 0.80),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 5. HIRAGANA NA ROW (na, ni, nu, ne, no)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'h_na',
    kana: 'な',
    romaji: 'na',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.24, 0.36), Offset(0.46, 0.34)]),
      KanaStroke([Offset(0.36, 0.22), Offset(0.28, 0.60)]),
      KanaStroke([Offset(0.58, 0.26), Offset(0.68, 0.36)]),
      KanaStroke([
        Offset(0.54, 0.46),
        Offset(0.54, 0.74),
        Offset(0.42, 0.82),
        Offset(0.48, 0.88),
        Offset(0.66, 0.78),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_ni',
    kana: 'に',
    romaji: 'ni',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.30, 0.22),
        Offset(0.28, 0.54),
        Offset(0.28, 0.78),
        Offset(0.34, 0.70),
      ]),
      KanaStroke([Offset(0.50, 0.38), Offset(0.76, 0.36)]),
      KanaStroke([Offset(0.48, 0.68), Offset(0.64, 0.72), Offset(0.80, 0.66)]),
    ],
  ),
  KanaCharacter(
    id: 'h_nu',
    kana: 'ぬ',
    romaji: 'nu',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.38, 0.24), Offset(0.30, 0.74)]),
      KanaStroke([
        Offset(0.26, 0.38),
        Offset(0.68, 0.34),
        Offset(0.24, 0.76),
        Offset(0.76, 0.66),
        Offset(0.78, 0.82),
        Offset(0.68, 0.86),
        Offset(0.84, 0.84),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_ne',
    kana: 'ね',
    romaji: 'ne',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.32, 0.20), Offset(0.32, 0.80)]),
      KanaStroke([
        Offset(0.18, 0.36),
        Offset(0.54, 0.34),
        Offset(0.26, 0.68),
        Offset(0.54, 0.44),
        Offset(0.68, 0.54),
        Offset(0.68, 0.76),
        Offset(0.56, 0.82),
        Offset(0.74, 0.80),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_no',
    kana: 'の',
    romaji: 'no',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.48, 0.30),
        Offset(0.38, 0.54),
        Offset(0.52, 0.32),
        Offset(0.74, 0.46),
        Offset(0.72, 0.76),
        Offset(0.48, 0.84),
        Offset(0.26, 0.70),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 6. HIRAGANA HA ROW (ha, hi, fu, he, ho)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'h_ha',
    kana: 'は',
    romaji: 'ha',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.28, 0.20), Offset(0.28, 0.76), Offset(0.34, 0.68)]),
      KanaStroke([Offset(0.46, 0.36), Offset(0.74, 0.34)]),
      KanaStroke([
        Offset(0.62, 0.20),
        Offset(0.62, 0.66),
        Offset(0.50, 0.76),
        Offset(0.58, 0.84),
        Offset(0.74, 0.76),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_hi',
    kana: 'ひ',
    romaji: 'hi',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.24, 0.36),
        Offset(0.42, 0.34),
        Offset(0.28, 0.64),
        Offset(0.50, 0.82),
        Offset(0.72, 0.48),
        Offset(0.74, 0.76),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_fu',
    kana: 'ふ',
    romaji: 'fu',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.50, 0.18), Offset(0.54, 0.30)]),
      KanaStroke([
        Offset(0.50, 0.40),
        Offset(0.44, 0.60),
        Offset(0.50, 0.78),
        Offset(0.42, 0.84),
      ]),
      KanaStroke([Offset(0.32, 0.52), Offset(0.24, 0.66)]),
      KanaStroke([Offset(0.68, 0.50), Offset(0.76, 0.64)]),
    ],
  ),
  KanaCharacter(
    id: 'h_he',
    kana: 'へ',
    romaji: 'he',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.22, 0.64), Offset(0.44, 0.34), Offset(0.78, 0.66)]),
    ],
  ),
  KanaCharacter(
    id: 'h_ho',
    kana: 'ほ',
    romaji: 'ho',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.26, 0.20), Offset(0.26, 0.76), Offset(0.32, 0.68)]),
      KanaStroke([Offset(0.44, 0.32), Offset(0.76, 0.32)]),
      KanaStroke([Offset(0.44, 0.48), Offset(0.74, 0.48)]),
      KanaStroke([
        Offset(0.60, 0.32),
        Offset(0.60, 0.68),
        Offset(0.48, 0.76),
        Offset(0.56, 0.84),
        Offset(0.72, 0.76),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 7. HIRAGANA MA ROW (ma, mi, mu, me, mo)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'h_ma',
    kana: 'ま',
    romaji: 'ma',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.26, 0.34), Offset(0.74, 0.32)]),
      KanaStroke([Offset(0.30, 0.50), Offset(0.70, 0.48)]),
      KanaStroke([
        Offset(0.50, 0.18),
        Offset(0.50, 0.68),
        Offset(0.36, 0.78),
        Offset(0.44, 0.86),
        Offset(0.66, 0.78),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_mi',
    kana: 'み',
    romaji: 'mi',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.24, 0.32),
        Offset(0.60, 0.28),
        Offset(0.30, 0.62),
        Offset(0.22, 0.74),
        Offset(0.38, 0.78),
        Offset(0.74, 0.62),
      ]),
      KanaStroke([Offset(0.62, 0.38), Offset(0.54, 0.72), Offset(0.44, 0.84)]),
    ],
  ),
  KanaCharacter(
    id: 'h_mu',
    kana: 'む',
    romaji: 'mu',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.20, 0.38), Offset(0.46, 0.36)]),
      KanaStroke([
        Offset(0.40, 0.20),
        Offset(0.40, 0.64),
        Offset(0.26, 0.74),
        Offset(0.36, 0.82),
        Offset(0.58, 0.74),
        Offset(0.76, 0.58),
        Offset(0.72, 0.48),
      ]),
      KanaStroke([Offset(0.68, 0.24), Offset(0.78, 0.36)]),
    ],
  ),
  KanaCharacter(
    id: 'h_me',
    kana: 'め',
    romaji: 'me',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.38, 0.26), Offset(0.30, 0.74)]),
      KanaStroke([
        Offset(0.28, 0.42),
        Offset(0.70, 0.34),
        Offset(0.26, 0.76),
        Offset(0.76, 0.72),
        Offset(0.64, 0.86),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_mo',
    kana: 'も',
    romaji: 'mo',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.46, 0.20),
        Offset(0.46, 0.70),
        Offset(0.56, 0.82),
        Offset(0.74, 0.72),
      ]),
      KanaStroke([Offset(0.28, 0.38), Offset(0.68, 0.36)]),
      KanaStroke([Offset(0.26, 0.54), Offset(0.70, 0.52)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 8. HIRAGANA YA ROW (ya, yu, yo)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'h_ya',
    kana: 'や',
    romaji: 'ya',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.26, 0.44),
        Offset(0.48, 0.32),
        Offset(0.64, 0.40),
        Offset(0.60, 0.60),
        Offset(0.48, 0.54),
      ]),
      KanaStroke([Offset(0.38, 0.22), Offset(0.46, 0.34)]),
      KanaStroke([Offset(0.70, 0.22), Offset(0.68, 0.54), Offset(0.62, 0.82)]),
    ],
  ),
  KanaCharacter(
    id: 'h_yu',
    kana: 'ゆ',
    romaji: 'yu',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.38, 0.22),
        Offset(0.38, 0.68),
        Offset(0.26, 0.76),
        Offset(0.34, 0.84),
        Offset(0.68, 0.72),
      ]),
      KanaStroke([Offset(0.58, 0.18), Offset(0.58, 0.58), Offset(0.52, 0.84)]),
    ],
  ),
  KanaCharacter(
    id: 'h_yo',
    kana: 'よ',
    romaji: 'yo',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.26, 0.36), Offset(0.54, 0.36)]),
      KanaStroke([
        Offset(0.52, 0.20),
        Offset(0.52, 0.68),
        Offset(0.36, 0.78),
        Offset(0.44, 0.86),
        Offset(0.76, 0.78),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 9. HIRAGANA RA ROW (ra, ri, ru, re, ro)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'h_ra',
    kana: 'ら',
    romaji: 'ra',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.42, 0.20), Offset(0.54, 0.26)]),
      KanaStroke([
        Offset(0.34, 0.40),
        Offset(0.48, 0.38),
        Offset(0.66, 0.48),
        Offset(0.66, 0.72),
        Offset(0.44, 0.84),
        Offset(0.30, 0.78),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_ri',
    kana: 'り',
    romaji: 'ri',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.34, 0.26), Offset(0.34, 0.54), Offset(0.42, 0.50)]),
      KanaStroke([Offset(0.64, 0.20), Offset(0.64, 0.62), Offset(0.54, 0.84)]),
    ],
  ),
  KanaCharacter(
    id: 'h_ru',
    kana: 'る',
    romaji: 'ru',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.28, 0.32),
        Offset(0.68, 0.30),
        Offset(0.34, 0.58),
        Offset(0.68, 0.60),
        Offset(0.72, 0.76),
        Offset(0.48, 0.84),
        Offset(0.42, 0.74),
        Offset(0.54, 0.74),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_re',
    kana: 'れ',
    romaji: 're',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.32, 0.20), Offset(0.32, 0.80)]),
      KanaStroke([
        Offset(0.18, 0.36),
        Offset(0.54, 0.34),
        Offset(0.26, 0.68),
        Offset(0.54, 0.44),
        Offset(0.66, 0.64),
        Offset(0.80, 0.60),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_ro',
    kana: 'ろ',
    romaji: 'ro',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.28, 0.32),
        Offset(0.68, 0.30),
        Offset(0.34, 0.58),
        Offset(0.68, 0.60),
        Offset(0.72, 0.76),
        Offset(0.46, 0.84),
        Offset(0.32, 0.78),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 10. HIRAGANA WA & N ROW (wa, wo, n)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'h_wa',
    kana: 'わ',
    romaji: 'wa',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.32, 0.20), Offset(0.32, 0.80)]),
      KanaStroke([
        Offset(0.18, 0.36),
        Offset(0.54, 0.34),
        Offset(0.26, 0.68),
        Offset(0.54, 0.44),
        Offset(0.74, 0.56),
        Offset(0.68, 0.80),
        Offset(0.46, 0.84),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_wo',
    kana: 'を',
    romaji: 'wo',
    type: 'hiragana',
    strokes: [
      KanaStroke([Offset(0.26, 0.32), Offset(0.70, 0.30)]),
      KanaStroke([Offset(0.46, 0.18), Offset(0.40, 0.58), Offset(0.26, 0.66)]),
      KanaStroke([
        Offset(0.38, 0.52),
        Offset(0.74, 0.54),
        Offset(0.68, 0.78),
        Offset(0.42, 0.84),
        Offset(0.30, 0.78),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'h_n',
    kana: 'ん',
    romaji: 'n',
    type: 'hiragana',
    strokes: [
      KanaStroke([
        Offset(0.34, 0.28),
        Offset(0.28, 0.62),
        Offset(0.44, 0.46),
        Offset(0.60, 0.58),
        Offset(0.52, 0.84),
        Offset(0.74, 0.80),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 11. KATAKANA A ROW (a, i, u, e, o)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'k_a',
    kana: 'ア',
    romaji: 'a',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.24, 0.28), Offset(0.76, 0.28), Offset(0.54, 0.50)]),
      KanaStroke([Offset(0.54, 0.44), Offset(0.48, 0.64), Offset(0.32, 0.80)]),
    ],
  ),
  KanaCharacter(
    id: 'k_i',
    kana: 'イ',
    romaji: 'i',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.56, 0.18), Offset(0.44, 0.38), Offset(0.30, 0.62)]),
      KanaStroke([Offset(0.46, 0.40), Offset(0.46, 0.62), Offset(0.46, 0.84)]),
    ],
  ),
  KanaCharacter(
    id: 'k_u',
    kana: 'ウ',
    romaji: 'u',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.50, 0.14), Offset(0.50, 0.26)]),
      KanaStroke([Offset(0.30, 0.34), Offset(0.28, 0.48)]),
      KanaStroke([
        Offset(0.28, 0.38),
        Offset(0.74, 0.38),
        Offset(0.66, 0.58),
        Offset(0.48, 0.82),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'k_e',
    kana: 'エ',
    romaji: 'e',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.28, 0.22), Offset(0.72, 0.22)]),
      KanaStroke([Offset(0.50, 0.22), Offset(0.50, 0.78)]),
      KanaStroke([Offset(0.20, 0.78), Offset(0.80, 0.78)]),
    ],
  ),
  KanaCharacter(
    id: 'k_o',
    kana: 'オ',
    romaji: 'o',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.22, 0.32), Offset(0.78, 0.32)]),
      KanaStroke([Offset(0.52, 0.16), Offset(0.52, 0.78), Offset(0.42, 0.68)]),
      KanaStroke([Offset(0.50, 0.38), Offset(0.38, 0.56), Offset(0.24, 0.76)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 12. KATAKANA KA ROW (ka, ki, ku, ke, ko)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'k_ka',
    kana: 'カ',
    romaji: 'ka',
    type: 'katakana',
    strokes: [
      KanaStroke([
        Offset(0.24, 0.32),
        Offset(0.74, 0.32),
        Offset(0.60, 0.64),
        Offset(0.50, 0.56),
      ]),
      KanaStroke([Offset(0.48, 0.18), Offset(0.42, 0.50), Offset(0.28, 0.82)]),
    ],
  ),
  KanaCharacter(
    id: 'k_ki',
    kana: 'キ',
    romaji: 'ki',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.30, 0.32), Offset(0.70, 0.30)]),
      KanaStroke([Offset(0.24, 0.50), Offset(0.76, 0.48)]),
      KanaStroke([Offset(0.58, 0.18), Offset(0.46, 0.54), Offset(0.30, 0.84)]),
    ],
  ),
  KanaCharacter(
    id: 'k_ku',
    kana: 'ク',
    romaji: 'ku',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.48, 0.20), Offset(0.34, 0.44)]),
      KanaStroke([
        Offset(0.32, 0.38),
        Offset(0.72, 0.38),
        Offset(0.62, 0.58),
        Offset(0.36, 0.82),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'k_ke',
    kana: 'ケ',
    romaji: 'ke',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.46, 0.18), Offset(0.32, 0.44)]),
      KanaStroke([Offset(0.36, 0.40), Offset(0.78, 0.40)]),
      KanaStroke([Offset(0.60, 0.32), Offset(0.60, 0.58), Offset(0.44, 0.84)]),
    ],
  ),
  KanaCharacter(
    id: 'k_ko',
    kana: 'コ',
    romaji: 'ko',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.28, 0.28), Offset(0.72, 0.28), Offset(0.72, 0.74)]),
      KanaStroke([Offset(0.28, 0.74), Offset(0.74, 0.74)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 13. KATAKANA SA ROW (sa, shi, su, se, so)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'k_sa',
    kana: 'サ',
    romaji: 'sa',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.22, 0.36), Offset(0.78, 0.36)]),
      KanaStroke([Offset(0.38, 0.22), Offset(0.38, 0.54)]),
      KanaStroke([Offset(0.64, 0.22), Offset(0.64, 0.62), Offset(0.48, 0.82)]),
    ],
  ),
  KanaCharacter(
    id: 'k_shi',
    kana: 'シ',
    romaji: 'shi',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.32, 0.28), Offset(0.44, 0.34)]),
      KanaStroke([Offset(0.28, 0.48), Offset(0.40, 0.54)]),
      KanaStroke([Offset(0.28, 0.80), Offset(0.48, 0.68), Offset(0.74, 0.34)]),
    ],
  ),
  KanaCharacter(
    id: 'k_su',
    kana: 'ス',
    romaji: 'su',
    type: 'katakana',
    strokes: [
      KanaStroke([
        Offset(0.28, 0.32),
        Offset(0.72, 0.32),
        Offset(0.46, 0.58),
        Offset(0.30, 0.82),
      ]),
      KanaStroke([Offset(0.48, 0.54), Offset(0.70, 0.82)]),
    ],
  ),
  KanaCharacter(
    id: 'k_se',
    kana: 'セ',
    romaji: 'se',
    type: 'katakana',
    strokes: [
      KanaStroke([
        Offset(0.24, 0.38),
        Offset(0.76, 0.38),
        Offset(0.74, 0.62),
        Offset(0.60, 0.68),
      ]),
      KanaStroke([Offset(0.48, 0.20), Offset(0.48, 0.74), Offset(0.80, 0.74)]),
    ],
  ),
  KanaCharacter(
    id: 'k_so',
    kana: 'ソ',
    romaji: 'so',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.36, 0.26), Offset(0.46, 0.44)]),
      KanaStroke([Offset(0.70, 0.24), Offset(0.50, 0.56), Offset(0.30, 0.82)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 14. KATAKANA TA ROW (ta, chi, tsu, te, to)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'k_ta',
    kana: 'タ',
    romaji: 'ta',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.48, 0.18), Offset(0.32, 0.44)]),
      KanaStroke([
        Offset(0.34, 0.38),
        Offset(0.76, 0.38),
        Offset(0.64, 0.60),
        Offset(0.34, 0.84),
      ]),
      KanaStroke([Offset(0.46, 0.52), Offset(0.68, 0.72)]),
    ],
  ),
  KanaCharacter(
    id: 'k_chi',
    kana: 'チ',
    romaji: 'chi',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.68, 0.20), Offset(0.36, 0.30)]),
      KanaStroke([Offset(0.22, 0.48), Offset(0.78, 0.48)]),
      KanaStroke([Offset(0.50, 0.30), Offset(0.50, 0.62), Offset(0.36, 0.84)]),
    ],
  ),
  KanaCharacter(
    id: 'k_tsu',
    kana: 'ツ',
    romaji: 'tsu',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.34, 0.28), Offset(0.40, 0.42)]),
      KanaStroke([Offset(0.52, 0.34), Offset(0.58, 0.48)]),
      KanaStroke([Offset(0.74, 0.24), Offset(0.56, 0.56), Offset(0.32, 0.80)]),
    ],
  ),
  KanaCharacter(
    id: 'k_te',
    kana: 'テ',
    romaji: 'te',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.34, 0.28), Offset(0.66, 0.28)]),
      KanaStroke([Offset(0.20, 0.48), Offset(0.80, 0.48)]),
      KanaStroke([Offset(0.50, 0.48), Offset(0.48, 0.68), Offset(0.32, 0.84)]),
    ],
  ),
  KanaCharacter(
    id: 'k_to',
    kana: 'ト',
    romaji: 'to',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.44, 0.18), Offset(0.44, 0.84)]),
      KanaStroke([Offset(0.44, 0.44), Offset(0.74, 0.62)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 15. KATAKANA NA ROW (na, ni, nu, ne, no)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'k_na',
    kana: 'ナ',
    romaji: 'na',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.24, 0.36), Offset(0.76, 0.36)]),
      KanaStroke([Offset(0.50, 0.22), Offset(0.46, 0.52), Offset(0.30, 0.84)]),
    ],
  ),
  KanaCharacter(
    id: 'k_ni',
    kana: 'ニ',
    romaji: 'ni',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.32, 0.36), Offset(0.68, 0.36)]),
      KanaStroke([Offset(0.22, 0.72), Offset(0.78, 0.72)]),
    ],
  ),
  KanaCharacter(
    id: 'k_nu',
    kana: 'ヌ',
    romaji: 'nu',
    type: 'katakana',
    strokes: [
      KanaStroke([
        Offset(0.28, 0.34),
        Offset(0.72, 0.34),
        Offset(0.52, 0.60),
        Offset(0.32, 0.82),
      ]),
      KanaStroke([Offset(0.46, 0.52), Offset(0.72, 0.78)]),
    ],
  ),
  KanaCharacter(
    id: 'k_ne',
    kana: 'ネ',
    romaji: 'ne',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.42, 0.18), Offset(0.48, 0.30)]),
      KanaStroke([Offset(0.30, 0.36), Offset(0.64, 0.36), Offset(0.42, 0.56)]),
      KanaStroke([Offset(0.42, 0.44), Offset(0.42, 0.84)]),
      KanaStroke([Offset(0.58, 0.58), Offset(0.74, 0.74)]),
    ],
  ),
  KanaCharacter(
    id: 'k_no',
    kana: 'ノ',
    romaji: 'no',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.68, 0.22), Offset(0.50, 0.52), Offset(0.30, 0.82)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 16. KATAKANA HA ROW (ha, hi, fu, he, ho)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'k_ha',
    kana: 'ハ',
    romaji: 'ha',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.40, 0.28), Offset(0.28, 0.76)]),
      KanaStroke([Offset(0.60, 0.28), Offset(0.74, 0.76)]),
    ],
  ),
  KanaCharacter(
    id: 'k_hi',
    kana: 'ヒ',
    romaji: 'hi',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.34, 0.34), Offset(0.64, 0.34)]),
      KanaStroke([Offset(0.38, 0.22), Offset(0.38, 0.72), Offset(0.78, 0.72)]),
    ],
  ),
  KanaCharacter(
    id: 'k_fu',
    kana: 'フ',
    romaji: 'fu',
    type: 'katakana',
    strokes: [
      KanaStroke([
        Offset(0.30, 0.32),
        Offset(0.72, 0.32),
        Offset(0.54, 0.56),
        Offset(0.34, 0.82),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'k_he',
    kana: 'ヘ',
    romaji: 'he',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.22, 0.64), Offset(0.44, 0.34), Offset(0.78, 0.66)]),
    ],
  ),
  KanaCharacter(
    id: 'k_ho',
    kana: 'ホ',
    romaji: 'ho',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.26, 0.34), Offset(0.74, 0.34)]),
      KanaStroke([Offset(0.50, 0.20), Offset(0.50, 0.82), Offset(0.42, 0.74)]),
      KanaStroke([Offset(0.38, 0.48), Offset(0.28, 0.72)]),
      KanaStroke([Offset(0.62, 0.48), Offset(0.72, 0.72)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 17. KATAKANA MA ROW (ma, mi, mu, me, mo)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'k_ma',
    kana: 'マ',
    romaji: 'ma',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.26, 0.34), Offset(0.72, 0.34), Offset(0.48, 0.58)]),
      KanaStroke([Offset(0.56, 0.58), Offset(0.74, 0.78)]),
    ],
  ),
  KanaCharacter(
    id: 'k_mi',
    kana: 'ミ',
    romaji: 'mi',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.36, 0.28), Offset(0.64, 0.36)]),
      KanaStroke([Offset(0.32, 0.48), Offset(0.66, 0.56)]),
      KanaStroke([Offset(0.26, 0.68), Offset(0.72, 0.78)]),
    ],
  ),
  KanaCharacter(
    id: 'k_mu',
    kana: 'ム',
    romaji: 'mu',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.50, 0.22), Offset(0.28, 0.68), Offset(0.74, 0.68)]),
      KanaStroke([Offset(0.64, 0.50), Offset(0.76, 0.60)]),
    ],
  ),
  KanaCharacter(
    id: 'k_me',
    kana: 'メ',
    romaji: 'me',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.68, 0.22), Offset(0.30, 0.80)]),
      KanaStroke([Offset(0.38, 0.36), Offset(0.72, 0.74)]),
    ],
  ),
  KanaCharacter(
    id: 'k_mo',
    kana: 'モ',
    romaji: 'mo',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.30, 0.32), Offset(0.70, 0.32)]),
      KanaStroke([Offset(0.24, 0.50), Offset(0.78, 0.50)]),
      KanaStroke([Offset(0.48, 0.18), Offset(0.48, 0.78), Offset(0.80, 0.78)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 18. KATAKANA YA ROW (ya, yu, yo)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'k_ya',
    kana: 'ヤ',
    romaji: 'ya',
    type: 'katakana',
    strokes: [
      KanaStroke([
        Offset(0.24, 0.36),
        Offset(0.74, 0.36),
        Offset(0.60, 0.54),
        Offset(0.46, 0.66),
      ]),
      KanaStroke([Offset(0.48, 0.18), Offset(0.40, 0.54), Offset(0.28, 0.82)]),
    ],
  ),
  KanaCharacter(
    id: 'k_yu',
    kana: 'ユ',
    romaji: 'yu',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.34, 0.24), Offset(0.34, 0.56), Offset(0.72, 0.56)]),
      KanaStroke([Offset(0.24, 0.78), Offset(0.78, 0.78)]),
    ],
  ),
  KanaCharacter(
    id: 'k_yo',
    kana: 'ヨ',
    romaji: 'yo',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.32, 0.26), Offset(0.70, 0.26), Offset(0.70, 0.76)]),
      KanaStroke([Offset(0.34, 0.50), Offset(0.68, 0.50)]),
      KanaStroke([Offset(0.32, 0.76), Offset(0.72, 0.76)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 19. KATAKANA RA ROW (ra, ri, ru, re, ro)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'k_ra',
    kana: 'ラ',
    romaji: 'ra',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.34, 0.28), Offset(0.66, 0.28)]),
      KanaStroke([
        Offset(0.28, 0.48),
        Offset(0.72, 0.48),
        Offset(0.58, 0.66),
        Offset(0.34, 0.84),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'k_ri',
    kana: 'リ',
    romaji: 'ri',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.36, 0.28), Offset(0.36, 0.56)]),
      KanaStroke([Offset(0.64, 0.20), Offset(0.64, 0.62), Offset(0.50, 0.84)]),
    ],
  ),
  KanaCharacter(
    id: 'k_ru',
    kana: 'ル',
    romaji: 'ru',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.42, 0.24), Offset(0.30, 0.76)]),
      KanaStroke([
        Offset(0.60, 0.24),
        Offset(0.60, 0.72),
        Offset(0.72, 0.78),
        Offset(0.78, 0.68),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'k_re',
    kana: 'レ',
    romaji: 're',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.36, 0.22), Offset(0.36, 0.78), Offset(0.76, 0.54)]),
    ],
  ),
  KanaCharacter(
    id: 'k_ro',
    kana: 'ロ',
    romaji: 'ro',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.30, 0.28), Offset(0.30, 0.76)]),
      KanaStroke([Offset(0.30, 0.28), Offset(0.72, 0.28), Offset(0.72, 0.76)]),
      KanaStroke([Offset(0.28, 0.76), Offset(0.74, 0.76)]),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 20. KATAKANA WA & N ROW (wa, wo, n)
  // ---------------------------------------------------------------------------
  KanaCharacter(
    id: 'k_wa',
    kana: 'ワ',
    romaji: 'wa',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.30, 0.34), Offset(0.28, 0.58)]),
      KanaStroke([
        Offset(0.30, 0.36),
        Offset(0.74, 0.36),
        Offset(0.62, 0.62),
        Offset(0.36, 0.84),
      ]),
    ],
  ),
  KanaCharacter(
    id: 'k_wo',
    kana: 'ヲ',
    romaji: 'wo',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.26, 0.32), Offset(0.72, 0.32)]),
      KanaStroke([Offset(0.28, 0.52), Offset(0.66, 0.52)]),
      KanaStroke([Offset(0.54, 0.34), Offset(0.48, 0.58), Offset(0.32, 0.82)]),
    ],
  ),
  KanaCharacter(
    id: 'k_n',
    kana: 'ン',
    romaji: 'n',
    type: 'katakana',
    strokes: [
      KanaStroke([Offset(0.32, 0.34), Offset(0.44, 0.42)]),
      KanaStroke([Offset(0.28, 0.76), Offset(0.50, 0.62), Offset(0.74, 0.30)]),
    ],
  ),
];

// =============================================================================
// DAKUTEN & HANDAKUTEN MAPPING SCHEMA
// =============================================================================

class _DerivedKanaEntry {
  final String baseKana;
  final String kana;
  final String romaji;
  final String id;
  final bool isHandakuten;

  const _DerivedKanaEntry(
    this.baseKana,
    this.kana,
    this.romaji,
    this.id, {
    this.isHandakuten = false,
  });
}

const List<_DerivedKanaEntry> _derivedKanaDefinitions = [
  // --- Hiragana Dakuten: Ga Row ---
  _DerivedKanaEntry('か', 'が', 'ga', 'h_ga'),
  _DerivedKanaEntry('き', 'ぎ', 'gi', 'h_gi'),
  _DerivedKanaEntry('く', 'ぐ', 'gu', 'h_gu'),
  _DerivedKanaEntry('け', 'げ', 'ge', 'h_ge'),
  _DerivedKanaEntry('こ', 'ご', 'go', 'h_go'),

  // --- Hiragana Dakuten: Za Row ---
  _DerivedKanaEntry('さ', 'ざ', 'za', 'h_za'),
  _DerivedKanaEntry('し', 'じ', 'ji', 'h_ji'),
  _DerivedKanaEntry('す', 'ず', 'zu', 'h_zu'),
  _DerivedKanaEntry('せ', 'ぜ', 'ze', 'h_ze'),
  _DerivedKanaEntry('そ', 'ぞ', 'zo', 'h_zo'),

  // --- Hiragana Dakuten: Da Row ---
  _DerivedKanaEntry('た', 'だ', 'da', 'h_da'),
  _DerivedKanaEntry('ち', 'ぢ', 'ji', 'h_dji'),
  _DerivedKanaEntry('つ', 'づ', 'zu', 'h_dzu'),
  _DerivedKanaEntry('て', 'で', 'de', 'h_de'),
  _DerivedKanaEntry('と', 'ど', 'do', 'h_do'),

  // --- Hiragana Dakuten: Ba Row ---
  _DerivedKanaEntry('は', 'ば', 'ba', 'h_ba'),
  _DerivedKanaEntry('ひ', 'び', 'bi', 'h_bi'),
  _DerivedKanaEntry('ふ', 'ぶ', 'bu', 'h_bu'),
  _DerivedKanaEntry('へ', 'べ', 'be', 'h_be'),
  _DerivedKanaEntry('ほ', 'ぼ', 'bo', 'h_bo'),

  // --- Hiragana Handakuten: Pa Row ---
  _DerivedKanaEntry('は', 'ぱ', 'pa', 'h_pa', isHandakuten: true),
  _DerivedKanaEntry('ひ', 'ぴ', 'pi', 'h_pi', isHandakuten: true),
  _DerivedKanaEntry('ふ', 'ぷ', 'pu', 'h_pu', isHandakuten: true),
  _DerivedKanaEntry('へ', 'ぺ', 'pe', 'h_pe', isHandakuten: true),
  _DerivedKanaEntry('ほ', 'ぽ', 'po', 'h_po', isHandakuten: true),

  // --- Katakana Dakuten: Ga Row ---
  _DerivedKanaEntry('カ', 'ガ', 'ga', 'k_ga'),
  _DerivedKanaEntry('キ', 'ギ', 'gi', 'k_gi'),
  _DerivedKanaEntry('ク', 'グ', 'gu', 'k_gu'),
  _DerivedKanaEntry('ケ', 'ゲ', 'ge', 'k_ge'),
  _DerivedKanaEntry('コ', 'ゴ', 'go', 'k_go'),

  // --- Katakana Dakuten: Za Row ---
  _DerivedKanaEntry('サ', 'ザ', 'za', 'k_za'),
  _DerivedKanaEntry('シ', 'ジ', 'ji', 'k_ji'),
  _DerivedKanaEntry('ス', 'ズ', 'zu', 'k_zu'),
  _DerivedKanaEntry('セ', 'ゼ', 'ze', 'k_ze'),
  _DerivedKanaEntry('ソ', 'ゾ', 'zo', 'k_zo'),

  // --- Katakana Dakuten: Da Row ---
  _DerivedKanaEntry('タ', 'ダ', 'da', 'k_da'),
  _DerivedKanaEntry('チ', 'ヂ', 'ji', 'k_dji'),
  _DerivedKanaEntry('ツ', 'ヅ', 'zu', 'k_dzu'),
  _DerivedKanaEntry('テ', 'デ', 'de', 'k_de'),
  _DerivedKanaEntry('ト', 'ド', 'do', 'k_do'),

  // --- Katakana Dakuten: Ba Row ---
  _DerivedKanaEntry('ハ', 'バ', 'ba', 'k_ba'),
  _DerivedKanaEntry('ヒ', 'ビ', 'bi', 'k_bi'),
  _DerivedKanaEntry('フ', 'ブ', 'bu', 'k_bu'),
  _DerivedKanaEntry('ヘ', 'ベ', 'be', 'k_be'),
  _DerivedKanaEntry('ホ', 'ボ', 'bo', 'k_bo'),

  // --- Katakana Handakuten: Pa Row ---
  _DerivedKanaEntry('ハ', 'パ', 'pa', 'k_pa', isHandakuten: true),
  _DerivedKanaEntry('ヒ', 'ピ', 'pi', 'k_pi', isHandakuten: true),
  _DerivedKanaEntry('フ', 'プ', 'pu', 'k_pu', isHandakuten: true),
  _DerivedKanaEntry('ヘ', 'ペ', 'pe', 'k_pe', isHandakuten: true),
  _DerivedKanaEntry('ホ', 'ポ', 'po', 'k_po', isHandakuten: true),
];

/// Generates the complete kana list combining base, dakuten, and handakuten characters.
List<KanaCharacter> _buildComprehensiveKanaData() {
  final Map<String, KanaCharacter> baseMap = {
    for (final char in _baseKanaData) char.kana: char,
  };

  final List<KanaCharacter> fullList = List<KanaCharacter>.from(_baseKanaData);

  for (final entry in _derivedKanaDefinitions) {
    final base = baseMap[entry.baseKana];
    if (base == null) continue;

    final diacriticStrokes = entry.isHandakuten
        ? _standardHandakutenStrokes
        : _standardDakutenStrokes;

    fullList.add(
      KanaCharacter(
        id: entry.id,
        kana: entry.kana,
        romaji: entry.romaji,
        type: base.type,
        strokes: List<KanaStroke>.unmodifiable([
          ...base.strokes,
          ...diacriticStrokes,
        ]),
      ),
    );
  }

  return List<KanaCharacter>.unmodifiable(fullList);
}

/// The complete, verified list of Japanese Kana (Basic, Dakuten, and Handakuten).
final List<KanaCharacter> initialKanaData = _buildComprehensiveKanaData();

// =============================================================================
// HIGH-PERFORMANCE O(1) LOOKUP CACHE & EXTENSIONS
// =============================================================================

Map<String, KanaCharacter>? _byKanaMap;
Map<String, KanaCharacter>? _byIdMap;
Map<String, List<KanaCharacter>>? _byTypeMap;

void _ensureLookupCache() {
  if (_byKanaMap != null) return;
  final byKana = <String, KanaCharacter>{};
  final byId = <String, KanaCharacter>{};
  final byType = <String, List<KanaCharacter>>{'hiragana': [], 'katakana': []};

  for (final char in initialKanaData) {
    byKana[char.kana] = char;
    byId[char.id] = char;
    byType[char.type]?.add(char);
  }

  _byKanaMap = byKana;
  _byIdMap = byId;
  _byTypeMap = byType;
}

/// Helper extension providing O(1) indexed lookups over kana data.
extension KanaListExtension on List<KanaCharacter> {
  /// Finds a character by its literal symbol (e.g., 'が' or 'パ') in O(1) time.
  KanaCharacter? findByKana(String kana) {
    _ensureLookupCache();
    return _byKanaMap?[kana];
  }

  /// Finds a character by its unique identifier (e.g., 'h_ga' or 'k_pa') in O(1) time.
  KanaCharacter? findById(String id) {
    _ensureLookupCache();
    return _byIdMap?[id];
  }

  /// Filters characters by writing system ('hiragana' or 'katakana') with cached lists.
  List<KanaCharacter> filterByType(String type) {
    _ensureLookupCache();
    return _byTypeMap?[type] ??
        where((element) => element.type == type).toList();
  }
}
