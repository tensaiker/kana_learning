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

  /// Total syllable length used for filtering by WordLength.
  int get length => kanaSyllables.length;

  /// Returns the raw kana string stripped of spacing (e.g. 'むら').
  String get plainKana => kana.replaceAll(' ', '');

  /// Checks if every character or syllable in this word is unlocked.
  ///
  /// Optimization:
  /// Uses [isKanaUnlocked] to check each syllable or individual kana character.
  /// Special characters such as the Katakana long vowel mark 'ー' and small tsu 'ッ'
  /// are treated as neutral extensions and automatically pass.
  bool isUnlocked(bool Function(String characterOrSyllable) isKanaUnlocked) {
    for (final s in kanaSyllables) {
      if (s == 'ー' || s == 'ッ' || s == 'っ') continue;
      if (!isKanaUnlocked(s)) return false;
    }
    return true;
  }

  /// Returns a list of prerequisite characters in this word that are still locked.
  List<String> getMissingPrerequisites(
    bool Function(String characterOrSyllable) isKanaUnlocked,
  ) {
    final List<String> missing = [];
    for (final s in kanaSyllables) {
      if (s == 'ー' || s == 'ッ' || s == 'っ') continue;
      if (!isKanaUnlocked(s) && !missing.contains(s)) {
        missing.add(s);
      }
    }
    return missing;
  }
}

/// Helper lookup map associating Kana characters/syllables to their parent lesson row title.
/// Used to dynamically check whether the character is unlocked via [ProgressService.isRowUnlocked].
const Map<String, String> kanaToRowTitleMap = {
  // --- Hiragana Basic Rows ---
  'あ': 'A row', 'い': 'A row', 'う': 'A row', 'え': 'A row', 'お': 'A row',
  'か': 'Ka row', 'き': 'Ka row', 'く': 'Ka row', 'け': 'Ka row', 'こ': 'Ka row',
  'さ': 'Sa row', 'し': 'Sa row', 'す': 'Sa row', 'せ': 'Sa row', 'そ': 'Sa row',
  'た': 'Ta row', 'ち': 'Ta row', 'つ': 'Ta row', 'て': 'Ta row', 'と': 'Ta row',
  'な': 'Na row', 'に': 'Na row', 'ぬ': 'Na row', 'ね': 'Na row', 'の': 'Na row',
  'は': 'Ha row', 'ひ': 'Ha row', 'ふ': 'Ha row', 'へ': 'Ha row', 'ほ': 'Ha row',
  'ま': 'Ma row', 'み': 'Ma row', 'む': 'Ma row', 'め': 'Ma row', 'も': 'Ma row',
  'や': 'Ya row', 'ゆ': 'Ya row', 'よ': 'Ya row',
  'ら': 'Ra row', 'り': 'Ra row', 'る': 'Ra row', 'れ': 'Ra row', 'ろ': 'Ra row',
  'わ': 'Wa / N row', 'を': 'Wa / N row', 'ん': 'Wa / N row',

  // --- Hiragana Dakuon & Handakuon Rows ---
  'が': 'Ga row', 'ぎ': 'Ga row', 'ぐ': 'Ga row', 'げ': 'Ga row', 'ご': 'Ga row',
  'ざ': 'Za row', 'じ': 'Za row', 'ず': 'Za row', 'ぜ': 'Za row', 'ぞ': 'Za row',
  'だ': 'Da row', 'ぢ': 'Da row', 'づ': 'Da row', 'で': 'Da row', 'ど': 'Da row',
  'ば': 'Ba row', 'び': 'Ba row', 'ぶ': 'Ba row', 'べ': 'Ba row', 'ぼ': 'Ba row',
  'ぱ': 'Pa row', 'ぴ': 'Pa row', 'ぷ': 'Pa row', 'ぺ': 'Pa row', 'ぽ': 'Pa row',

  // --- Hiragana Yoon Rows ---
  'きゃ': 'Kya row', 'きゅ': 'Kya row', 'きょ': 'Kya row',
  'しゃ': 'Sha row', 'しゅ': 'Sha row', 'しょ': 'Sha row',
  'ちゃ': 'Cha row', 'ちゅ': 'Cha row', 'ちょ': 'Cha row',
  'にゃ': 'Nya row', 'にゅ': 'Nya row', 'にょ': 'Nya row',
  'ひゃ': 'Hya row', 'ひゅ': 'Hya row', 'ひょ': 'Hya row',
  'みゃ': 'Mya row', 'みゅ': 'Mya row', 'みょ': 'Mya row',
  'りゃ': 'Rya row', 'りゅ': 'Rya row', 'りょ': 'Rya row',
  'ぎゃ': 'Gya row', 'ぎゅ': 'Gya row', 'ぎょ': 'Gya row',
  'じゃ': 'Ja row', 'じゅ': 'Ja row', 'じょ': 'Ja row',
  'びゃ': 'Bya row', 'びゅ': 'Bya row', 'びょ': 'Bya row',
  'ぴゃ': 'Pya row', 'ぴゅ': 'Pya row', 'ぴょ': 'Pya row',

  // --- Katakana Basic Rows ---
  'ア': 'A row', 'イ': 'A row', 'ウ': 'A row', 'エ': 'A row', 'オ': 'A row',
  'カ': 'Ka row', 'キ': 'Ka row', 'ク': 'Ka row', 'ケ': 'Ka row', 'コ': 'Ka row',
  'サ': 'Sa row', 'シ': 'Sa row', 'ス': 'Sa row', 'セ': 'Sa row', 'ソ': 'Sa row',
  'タ': 'Ta row', 'チ': 'Ta row', 'ツ': 'Ta row', 'テ': 'Ta row', 'ト': 'Ta row',
  'ナ': 'Na row', 'ニ': 'Na row', 'ヌ': 'Na row', 'ネ': 'Na row', 'ノ': 'Na row',
  'ハ': 'Ha row', 'ヒ': 'Ha row', 'フ': 'Ha row', 'ヘ': 'Ha row', 'ホ': 'Ha row',
  'マ': 'Ma row', 'ミ': 'Ma row', 'ム': 'Ma row', 'メ': 'Ma row', 'モ': 'Ma row',
  'ヤ': 'Ya row', 'ユ': 'Ya row', 'ヨ': 'Ya row',
  'ラ': 'Ra row', 'リ': 'Ra row', 'ル': 'Ra row', 'レ': 'Ra row', 'ロ': 'Ra row',
  'ワ': 'Wa / N row', 'ヲ': 'Wa / N row', 'ン': 'Wa / N row',

  // --- Katakana Dakuon & Handakuon Rows ---
  'ガ': 'Ga row', 'ギ': 'Ga row', 'グ': 'Ga row', 'ゲ': 'Ga row', 'ゴ': 'Ga row',
  'ザ': 'Za row', 'ジ': 'Za row', 'ズ': 'Za row', 'ゼ': 'Za row', 'ゾ': 'Za row',
  'ダ': 'Da row', 'ヂ': 'Da row', 'ヅ': 'Da row', 'デ': 'Da row', 'ド': 'Da row',
  'バ': 'Ba row', 'ビ': 'Ba row', 'ブ': 'Ba row', 'ベ': 'Ba row', 'ボ': 'Ba row',
  'パ': 'Pa row', 'ピ': 'Pa row', 'プ': 'Pa row', 'ペ': 'Pa row', 'ポ': 'Pa row',

  // --- Katakana Yoon Rows ---
  'キャ': 'Kya row', 'キュ': 'Kya row', 'キョ': 'Kya row',
  'シャ': 'Sha row', 'シュ': 'Sha row', 'ショ': 'Sha row',
  'チャ': 'Cha row', 'チュ': 'Cha row', 'チョ': 'Cha row',
  'ニャ': 'Nya row', 'ニュ': 'Nya row', 'ニョ': 'Nya row',
  'ヒャ': 'Hya row', 'ヒュ': 'Hya row', 'ヒョ': 'Hya row',
  'ミャ': 'Mya row', 'ミュ': 'Mya row', 'ミョ': 'Mya row',
  'リャ': 'Rya row', 'リュ': 'Rya row', 'リョ': 'Rya row',
  'ギャ': 'Gya row', 'ギュ': 'Gya row', 'ギョ': 'Gya row',
  'ジャ': 'Ja row', 'ジュ': 'Ja row', 'ジョ': 'Ja row',
  'ビャ': 'Bya row', 'ビュ': 'Bya row', 'ビョ': 'Bya row',
  'ピャ': 'Pya row', 'ピュ': 'Pya row', 'ピョ': 'Pya row',
};

/// Comprehensive vocabulary database for Word Builder practice.
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
