// lib/data/vocabulary_data.dart

/// Model representing a single vocabulary entry for the Word Builder activity.
class WordBuilderQuestion {
  final String kana; // Kana representation with syllable spaces (e.g. 'む ら')
  final String romaji; // Full Romaji word (e.g. 'mura')
  final String english; // English translation (e.g. 'Village')
  final List<String>
  syllables; // Romaji syllables for tiles (e.g. ['mu', 'ra'])
  final List<String>
  kanaSyllables; // Kana syllables for tiles (e.g. ['む', 'ら'])
  final bool isHiragana; // True for Hiragana, false for Katakana

  const WordBuilderQuestion({
    required this.kana,
    required this.romaji,
    required this.english,
    required this.syllables,
    required this.kanaSyllables,
    this.isHiragana = true,
  });

  /// Total syllable length used for filtering by WordLength
  int get length => kanaSyllables.length;
}

/// Comprehensive vocabulary database for Word Builder practice.
/// You can add hundreds or thousands of additional words here.
const List<WordBuilderQuestion> allVocabulary = [
  // ===========================================================================
  // 1. HIRAGANA - SHORT (2 - 3 Syllables)
  // ===========================================================================
  WordBuilderQuestion(
    kana: 'む ら',
    romaji: 'mura',
    english: 'Village',
    syllables: ['mu', 'ra'],
    kanaSyllables: ['む', 'ら'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'ね こ',
    romaji: 'neko',
    english: 'Cat',
    syllables: ['ne', 'ko'],
    kanaSyllables: ['ね', 'こ'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'い ぬ',
    romaji: 'inu',
    english: 'Dog',
    syllables: ['i', 'nu'],
    kanaSyllables: ['い', 'ぬ'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'あ め',
    romaji: 'ame',
    english: 'Rain / Candy',
    syllables: ['a', 'me'],
    kanaSyllables: ['あ', 'め'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'は な',
    romaji: 'hana',
    english: 'Flower / Nose',
    syllables: ['ha', 'na'],
    kanaSyllables: ['は', 'な'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'そ ら',
    romaji: 'sora',
    english: 'Sky',
    syllables: ['so', 'ra'],
    kanaSyllables: ['そ', 'ら'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'や ま',
    romaji: 'yama',
    english: 'Mountain',
    syllables: ['ya', 'ma'],
    kanaSyllables: ['や', 'ま'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'う み',
    romaji: 'umi',
    english: 'Sea / Ocean',
    syllables: ['u', 'mi'],
    kanaSyllables: ['う', 'み'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'か わ',
    romaji: 'kawa',
    english: 'River',
    syllables: ['ka', 'wa'],
    kanaSyllables: ['か', 'わ'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'つ き',
    romaji: 'tsuki',
    english: 'Moon',
    syllables: ['tsu', 'ki'],
    kanaSyllables: ['つ', 'き'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'ほ し',
    romaji: 'hoshi',
    english: 'Star',
    syllables: ['ho', 'shi'],
    kanaSyllables: ['ほ', 'し'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'み ず',
    romaji: 'mizu',
    english: 'Water',
    syllables: ['mi', 'zu'],
    kanaSyllables: ['み', 'ず'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'ひ と',
    romaji: 'hito',
    english: 'Person',
    syllables: ['hi', 'to'],
    kanaSyllables: ['ひ', 'と'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'く る ま',
    romaji: 'kuruma',
    english: 'Car',
    syllables: ['ku', 'ru', 'ma'],
    kanaSyllables: ['く', 'る', 'ま'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'さ く ら',
    romaji: 'sakura',
    english: 'Cherry blossom',
    syllables: ['sa', 'ku', 'ra'],
    kanaSyllables: ['さ', 'く', 'ら'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'さ か な',
    romaji: 'sakana',
    english: 'Fish',
    syllables: ['sa', 'ka', 'na'],
    kanaSyllables: ['さ', 'か', 'な'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'こ こ ろ',
    romaji: 'kokoro',
    english: 'Heart / Spirit',
    syllables: ['ko', 'ko', 'ro'],
    kanaSyllables: ['こ', 'こ', 'ろ'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'て が み',
    romaji: 'tegami',
    english: 'Letter',
    syllables: ['te', 'ga', 'mi'],
    kanaSyllables: ['て', 'が', 'み'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'と り',
    romaji: 'tori',
    english: 'Bird',
    syllables: ['to', 'ri'],
    kanaSyllables: ['と', 'り'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'さ る',
    romaji: 'saru',
    english: 'Monkey',
    syllables: ['sa', 'ru'],
    kanaSyllables: ['さ', 'る'],
    isHiragana: true,
  ),

  // ===========================================================================
  // 2. HIRAGANA - MEDIUM (4 - 5 Syllables)
  // ===========================================================================
  WordBuilderQuestion(
    kana: 'ほ ん し ゃ',
    romaji: 'honsha',
    english: 'head office; main office',
    syllables: ['ho', 'n', 'sha'],
    kanaSyllables: ['ほ', 'ん', 'しゃ'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'あ さ ご は ん',
    romaji: 'asagohan',
    english: 'Breakfast',
    syllables: ['a', 'sa', 'go', 'ha', 'n'],
    kanaSyllables: ['あ', 'さ', 'ご', 'は', 'ん'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'ひ る ご は ん',
    romaji: 'hirugohan',
    english: 'Lunch',
    syllables: ['hi', 'ru', 'go', 'ha', 'n'],
    kanaSyllables: ['ひ', 'る', 'ご', 'は', 'ん'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'ば ん ご は ん',
    romaji: 'bangohan',
    english: 'Dinner',
    syllables: ['ba', 'n', 'go', 'ha', 'n'],
    kanaSyllables: ['ば', 'ん', 'ご', 'は', 'ん'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'と も だ ち',
    romaji: 'tomodachi',
    english: 'Friend',
    syllables: ['to', 'mo', 'da', 'chi'],
    kanaSyllables: ['と', 'も', 'だ', 'ち'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'せ ん せ い',
    romaji: 'sensei',
    english: 'Teacher',
    syllables: ['se', 'n', 'se', 'i'],
    kanaSyllables: ['せ', 'ん', 'せ', 'い'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'ひ こ う き',
    romaji: 'hikouki',
    english: 'Airplane',
    syllables: ['hi', 'ko', 'u', 'ki'],
    kanaSyllables: ['ひ', 'こ', 'う', 'き'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'ど う ぶ つ',
    romaji: 'doubutsu',
    english: 'Animal',
    syllables: ['do', 'u', 'bu', 'tsu'],
    kanaSyllables: ['ど', 'う', 'ぶ', 'つ'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'じ て ん し ゃ',
    romaji: 'jitensha',
    english: 'Bicycle',
    syllables: ['ji', 'te', 'n', 'sha'],
    kanaSyllables: ['じ', 'て', 'ん', 'しゃ'],
    isHiragana: true,
  ),

  // ===========================================================================
  // 3. HIRAGANA - LONG (6+ Syllables)
  // ===========================================================================
  WordBuilderQuestion(
    kana: 'あ り が と う ご ざ い ま す',
    romaji: 'arigatougozaimasu',
    english: 'Thank you very much',
    syllables: ['a', 'ri', 'ga', 'to', 'u', 'go', 'za', 'i', 'ma', 'su'],
    kanaSyllables: ['あ', 'り', 'が', 'と', 'う', 'ご', 'ざ', 'い', 'ま', 'す'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'お は よ う ご ざ い ま す',
    romaji: 'ohayougozaimasu',
    english: 'Good morning',
    syllables: ['o', 'ha', 'yo', 'u', 'go', 'za', 'i', 'ma', 'su'],
    kanaSyllables: ['お', 'は', 'よ', 'う', 'ご', 'ざ', 'い', 'ま', 'す'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'じ こ し ょ う か い',
    romaji: 'jikoshoukai',
    english: 'Self-introduction',
    syllables: ['ji', 'ko', 'sho', 'u', 'ka', 'i'],
    kanaSyllables: ['じ', 'こ', 'しょ', 'う', 'か', 'い'],
    isHiragana: true,
  ),
  WordBuilderQuestion(
    kana: 'す い ぞ く か ん',
    romaji: 'suizokukan',
    english: 'Aquarium',
    syllables: ['su', 'i', 'zo', 'ku', 'ka', 'n'],
    kanaSyllables: ['す', 'い', 'ぞ', 'く', 'か', 'ん'],
    isHiragana: true,
  ),

  // ===========================================================================
  // 4. KATAKANA - SHORT, MEDIUM & LONG
  // ===========================================================================
  WordBuilderQuestion(
    kana: 'パ ン',
    romaji: 'pan',
    english: 'Bread',
    syllables: ['pa', 'n'],
    kanaSyllables: ['パ', 'ン'],
    isHiragana: false,
  ),
  WordBuilderQuestion(
    kana: 'バ ス',
    romaji: 'basu',
    english: 'Bus',
    syllables: ['ba', 'su'],
    kanaSyllables: ['バ', 'ス'],
    isHiragana: false,
  ),
  WordBuilderQuestion(
    kana: 'ド ア',
    romaji: 'doa',
    english: 'Door',
    syllables: ['do', 'a'],
    kanaSyllables: ['ド', 'ア'],
    isHiragana: false,
  ),
  WordBuilderQuestion(
    kana: 'コ ー ヒ ー',
    romaji: 'koohii',
    english: 'Coffee',
    syllables: ['ko', 'ー', 'hi', 'ー'],
    kanaSyllables: ['コ', 'ー', 'ヒ', 'ー'],
    isHiragana: false,
  ),
  WordBuilderQuestion(
    kana: 'カ メ ラ',
    romaji: 'kamera',
    english: 'Camera',
    syllables: ['ka', 'me', 'ra'],
    kanaSyllables: ['カ', 'メ', 'ラ'],
    isHiragana: false,
  ),
  WordBuilderQuestion(
    kana: 'テ レ ビ',
    romaji: 'terebi',
    english: 'Television',
    syllables: ['te', 're', 'bi'],
    kanaSyllables: ['テ', 'レ', 'ビ'],
    isHiragana: false,
  ),
  WordBuilderQuestion(
    kana: 'レ ス ト ラ ン',
    romaji: 'resutoran',
    english: 'Restaurant',
    syllables: ['re', 'su', 'to', 'ra', 'n'],
    kanaSyllables: ['レ', 'ス', 'ト', 'ラ', 'ン'],
    isHiragana: false,
  ),
  WordBuilderQuestion(
    kana: 'ス ー パ ー マ ー ケ ッ ト',
    romaji: 'suupaamaaketto',
    english: 'Supermarket',
    syllables: ['su', 'ー', 'pa', 'ー', 'ma', 'ー', 'ke', 't', 'to'],
    kanaSyllables: ['ス', 'ー', 'パ', 'ー', 'マ', 'ー', 'ケ', 'ッ', 'ト'],
    isHiragana: false,
  ),
];
