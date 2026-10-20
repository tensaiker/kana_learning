import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import 'quiz_screen.dart';
import 'flashcard_screen.dart';

// --- VOCABULARY IMPORT ---
// Note: If vocabulary_data.dart is inside lib/data/, use '../data/vocabulary_data.dart'
// If placed in the same folder as practice_screen.dart, use 'vocabulary_data.dart'
import '../features/writing/data/vocabulary_data.dart';

// --- COLOR PALETTE ---
class AppColors {
  static const Color cream = Color(0xFFFDF8F3);
  static const Color beige = Color(0xFFEADFD1);
  static const Color sand = Color(0xFFDCC6A8);
  static const Color taupe = Color(0xFFC6B8A5);
  static const Color textDark = Color(0xFF5D534A);
  static const Color textLight = Color(0xFF8B8076);

  // Hiragana Colors (Green)
  static const Color sage = Color(0xFFB7C9B2);
  static const Color lightSage = Color(0xFFE4EFE7);

  // Katakana Colors (Blue)
  static const Color skyBlue = Color(0xFFA5C4E5);
  static const Color lightSkyBlue = Color(0xFFEBF0F5);

  // Difficulty & Feedback Colors
  static const Color ratingAgain = Color(0xFFD88A82); // Soft pastel red
  static const Color ratingHard = Color(0xFFE29E57); // Soft pastel orange
  static const Color ratingGood = Color(0xFF9FB89A); // Sage green
  static const Color ratingEasy = Color(0xFFA5C4E5); // Soft pastel blue
}

// Question types for flashcard learning
enum FlashcardQuestionType { kanaToRomaji, listening, romajiToKana, mix }

// Question types for word builder
enum WordBuilderQuestionType { kanaToRomaji, romajiToKana }

enum WordLength { short, medium, long }

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  // Master toggle: true = Hiragana, false = Katakana
  bool _isHiragana = true;

  // Sub-screen navigation: null = Hub, 'flashcard' = Flashcard Setup, 'word_builder' = Word Builder Setup
  String? _activeSubScreen;

  // Flashcard setup state
  FlashcardQuestionType _selectedQuestionType =
      FlashcardQuestionType.kanaToRomaji;
  String _selectedDifficulty = 'All'; // 'Easy', 'Hard', 'Good', 'Again', 'All'
  bool _showDifficultyFilter = false;
  bool _isRowsExpanded = false;

  // Word Builder setup state
  WordBuilderQuestionType _wbQuestionType =
      WordBuilderQuestionType.romajiToKana;
  WordLength _wbLength = WordLength.short;
  int _wbWordsPerRound = 30;

  // Selected row IDs
  late Set<String> _selectedRowIds;

  // Row Definitions (Hiragana and Katakana)
  final List<Map<String, dynamic>> _basicRows = [
    {
      'id': 'a',
      'h': ['あ', 'い', 'う', 'え', 'お'],
      'k': ['ア', 'イ', 'ウ', 'エ', 'オ'],
      'r': ['a', 'i', 'u', 'e', 'o'],
    },
    {
      'id': 'ka',
      'h': ['か', 'き', 'く', 'け', 'こ'],
      'k': ['カ', 'キ', 'ク', 'ケ', 'コ'],
      'r': ['ka', 'ki', 'ku', 'ke', 'ko'],
    },
    {
      'id': 'sa',
      'h': ['さ', 'し', 'す', 'せ', 'そ'],
      'k': ['サ', 'シ', 'ス', 'セ', 'ソ'],
      'r': ['sa', 'shi', 'su', 'se', 'so'],
    },
    {
      'id': 'ta',
      'h': ['た', 'ち', 'つ', 'て', 'と'],
      'k': ['タ', 'チ', 'ツ', 'テ', 'ト'],
      'r': ['ta', 'chi', 'tsu', 'te', 'to'],
    },
    {
      'id': 'na',
      'h': ['な', 'に', 'ぬ', 'ね', 'の'],
      'k': ['ナ', 'ニ', 'ヌ', 'ネ', 'ノ'],
      'r': ['na', 'ni', 'nu', 'ne', 'no'],
    },
    {
      'id': 'ha',
      'h': ['は', 'ひ', 'ふ', 'へ', 'ほ'],
      'k': ['ハ', 'ヒ', 'フ', 'ヘ', 'ホ'],
      'r': ['ha', 'hi', 'fu', 'he', 'ho'],
    },
    {
      'id': 'ma',
      'h': ['ま', 'み', 'む', 'め', 'も'],
      'k': ['マ', 'ミ', 'ム', 'メ', 'モ'],
      'r': ['ma', 'mi', 'mu', 'me', 'mo'],
    },
    {
      'id': 'ya',
      'h': ['や', '', 'ゆ', '', 'よ'],
      'k': ['ヤ', '', 'ユ', '', 'ヨ'],
      'r': ['ya', '', 'yu', '', 'yo'],
    },
    {
      'id': 'ra',
      'h': ['ら', 'り', 'る', 'れ', 'ろ'],
      'k': ['ラ', 'リ', 'ル', 'レ', 'ロ'],
      'r': ['ra', 'ri', 'ru', 're', 'ro'],
    },
    {
      'id': 'wa',
      'h': ['わ', '', 'を', '', 'ん'],
      'k': ['ワ', '', 'ヲ', '', 'ン'],
      'r': ['wa', '', 'wo', '', 'n'],
    },
  ];

  final List<Map<String, dynamic>> _dakuonRows = [
    {
      'id': 'ga',
      'h': ['が', 'ぎ', 'ぐ', 'げ', 'ご'],
      'k': ['ガ', 'ギ', 'グ', 'ゲ', 'ゴ'],
      'r': ['ga', 'gi', 'gu', 'ge', 'go'],
    },
    {
      'id': 'za',
      'h': ['ざ', 'じ', 'ず', 'ぜ', 'ぞ'],
      'k': ['ザ', 'ジ', 'ズ', 'ゼ', 'ゾ'],
      'r': ['za', 'ji', 'zu', 'ze', 'zo'],
    },
    {
      'id': 'da',
      'h': ['だ', 'ぢ', 'づ', 'で', 'ど'],
      'k': ['ダ', 'ヂ', 'ヅ', 'デ', 'ド'],
      'r': ['da', 'ji', 'zu', 'de', 'do'],
    },
    {
      'id': 'ba',
      'h': ['ば', 'び', 'ぶ', 'べ', 'ぼ'],
      'k': ['バ', 'ビ', 'ブ', 'ベ', 'ボ'],
      'r': ['ba', 'bi', 'bu', 'be', 'bo'],
    },
    {
      'id': 'pa',
      'h': ['ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ'],
      'k': ['パ', 'ピ', 'プ', 'ペ', 'ポ'],
      'r': ['pa', 'pi', 'pu', 'pe', 'po'],
    },
  ];

  final List<Map<String, dynamic>> _yoonRows = [
    {
      'id': 'kya',
      'h': ['きゃ', '', 'きゅ', '', 'きょ'],
      'k': ['キャ', '', 'キュ', '', 'キョ'],
      'r': ['kya', '', 'kyu', '', 'kyo'],
    },
    {
      'id': 'sha',
      'h': ['しゃ', '', 'しゅ', '', 'しょ'],
      'k': ['シャ', '', 'シュ', '', 'ショ'],
      'r': ['sha', '', 'shu', '', 'sho'],
    },
    {
      'id': 'cha',
      'h': ['ちゃ', '', 'ちゅ', '', 'ちょ'],
      'k': ['チャ', '', 'チュ', '', 'チョ'],
      'r': ['cha', '', 'chu', '', 'cho'],
    },
    {
      'id': 'nya',
      'h': ['にゃ', '', 'にゅ', '', 'にょ'],
      'k': ['ニャ', '', 'ニュ', '', 'ニョ'],
      'r': ['nya', '', 'nyu', '', 'nyo'],
    },
    {
      'id': 'hya',
      'h': ['ひゃ', '', 'ひゅ', '', 'ひょ'],
      'k': ['ヒャ', '', 'ヒュ', '', 'ヒョ'],
      'r': ['hya', '', 'hyu', '', 'hyo'],
    },
    {
      'id': 'mya',
      'h': ['みゃ', '', 'みゅ', '', 'みょ'],
      'k': ['ミャ', '', 'ミュ', '', 'ミョ'],
      'r': ['mya', '', 'myu', '', 'myo'],
    },
    {
      'id': 'rya',
      'h': ['りゃ', '', 'りゅ', '', 'りょ'],
      'k': ['リャ', '', 'リュ', '', 'リョ'],
      'r': ['rya', '', 'ryu', '', 'ryo'],
    },
    {
      'id': 'gya',
      'h': ['ぎゃ', '', 'ぎゅ', '', 'ぎょ'],
      'k': ['ギャ', '', 'ギュ', '', 'ギョ'],
      'r': ['gya', '', 'gyu', '', 'gyo'],
    },
    {
      'id': 'ja',
      'h': ['じゃ', '', 'じゅ', '', 'じょ'],
      'k': ['ジャ', '', 'ジュ', '', 'ジョ'],
      'r': ['ja', '', 'ju', '', 'jo'],
    },
    {
      'id': 'bya',
      'h': ['びゃ', '', 'びゅ', '', 'びょ'],
      'k': ['ビャ', '', 'ビュ', '', 'ビョ'],
      'r': ['bya', '', 'byu', '', 'byo'],
    },
    {
      'id': 'pya',
      'h': ['ぴゃ', '', 'ぴゅ', '', 'ぴょ'],
      'k': ['ピャ', '', 'ピュ', '', 'ピョ'],
      'r': ['pya', '', 'pyu', '', 'pyo'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedRowIds = {
      ..._basicRows.map((r) => r['id'] as String),
      ..._dakuonRows.map((r) => r['id'] as String),
      ..._yoonRows.map((r) => r['id'] as String),
    };
  }

  int get _totalSelectedCharactersCount {
    int count = 0;
    void addCount(List<Map<String, dynamic>> rows) {
      for (var row in rows) {
        if (_selectedRowIds.contains(row['id'])) {
          final list = _isHiragana ? (row['h'] as List) : (row['k'] as List);
          count += list.where((c) => (c as String).isNotEmpty).length;
        }
      }
    }

    addCount(_basicRows);
    addCount(_dakuonRows);
    addCount(_yoonRows);
    return count;
  }

  int _selectedCountIn(List<Map<String, dynamic>> rows) {
    return rows.where((r) => _selectedRowIds.contains(r['id'])).length;
  }

  void _toggleAllIn(List<Map<String, dynamic>> rows) {
    final ids = rows.map((r) => r['id'] as String).toSet();
    final bool allSelected = ids.every((id) => _selectedRowIds.contains(id));
    setState(() {
      if (allSelected) {
        _selectedRowIds.removeAll(ids);
      } else {
        _selectedRowIds.addAll(ids);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: _buildActiveScreenContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScreenContent() {
    if (_activeSubScreen == 'flashcard') {
      return _buildFlashcardSetupCard();
    } else if (_activeSubScreen == 'word_builder') {
      return _buildWordBuilderSetupCard();
    }
    return _buildPracticeHubCard();
  }

  // ===========================================================================
  // 1. TOP HEADER & TOGGLE SWITCH
  // ===========================================================================
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: const BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: AppColors.textDark, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Kana Practice',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          _buildToggle(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textDark, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isHiragana = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isHiragana ? AppColors.taupe : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHiragana ? AppColors.textDark : Colors.transparent,
                  width: 2,
                ),
              ),
              child: const Text(
                'あ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isHiragana = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: !_isHiragana ? AppColors.taupe : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !_isHiragana ? AppColors.textDark : Colors.transparent,
                  width: 2,
                ),
              ),
              child: const Text(
                'ア',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. MAIN PRACTICE HUB
  // ===========================================================================
  Widget _buildPracticeHubCard() {
    final systemName = _isHiragana ? 'Hiragana' : 'Katakana';
    final cardBgColor = _isHiragana
        ? AppColors.lightSage
        : AppColors.lightSkyBlue;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textDark, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.textDark,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$systemName Characters',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          _buildActivityCard(
            title: 'Flashcard Learning',
            description: 'Master characters with spaced repetition',
            bgColor: cardBgColor,
            icon: Icons.style_outlined,
            onTap: () => setState(() => _activeSubScreen = 'flashcard'),
          ),
          const SizedBox(height: 18),
          _buildActivityCard(
            title: 'Word Builder',
            description: 'Assemble real vocabulary from kana',
            bgColor: cardBgColor,
            iconWidget: const Text(
              'Aa',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            onTap: () => setState(() => _activeSubScreen = 'word_builder'),
          ),
          const SizedBox(height: 18),
          _buildActivityCard(
            title: '$systemName Quiz',
            description: 'Test your recognition and listening skills',
            bgColor: cardBgColor,
            iconWidget: Text(
              _isHiragana ? 'あ' : 'ア',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    rowTitle: 'Full',
                    writingSystem: systemName,
                    characters: _isHiragana
                        ? [
                            {'kana': 'あ', 'romaji': 'a'},
                            {'kana': 'い', 'romaji': 'i'},
                            {'kana': 'う', 'romaji': 'u'},
                            {'kana': 'え', 'romaji': 'e'},
                            {'kana': 'お', 'romaji': 'o'},
                          ]
                        : [
                            {'kana': 'ア', 'romaji': 'a'},
                            {'kana': 'イ', 'romaji': 'i'},
                            {'kana': 'ウ', 'romaji': 'u'},
                            {'kana': 'エ', 'romaji': 'e'},
                            {'kana': 'オ', 'romaji': 'o'},
                          ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String description,
    required Color bgColor,
    IconData? icon,
    Widget? iconWidget,
    required VoidCallback onTap,
  }) {
    return _Interactive3DCard(
      bgColor: bgColor,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.sage.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textDark, width: 1.5),
            ),
            alignment: Alignment.center,
            child:
                iconWidget ?? Icon(icon, color: AppColors.textDark, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textDark, size: 32),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. FLASHCARD SETUP CARD
  // ===========================================================================
  Widget _buildFlashcardSetupCard() {
    final systemName = _isHiragana ? 'Hiragana' : 'Katakana';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textDark, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.textDark,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.sand,
              border: Border(
                bottom: BorderSide(color: AppColors.textDark, width: 2),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _activeSubScreen = null),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textDark,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Flashcard Learning',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(
                    () => _showDifficultyFilter = !_showDifficultyFilter,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _showDifficultyFilter
                          ? AppColors.taupe
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.textDark,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: _showDifficultyFilter
                ? _buildDifficultySelectionView()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kana',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildAccordionSelector(systemName),
                      const SizedBox(height: 22),
                      const Text(
                        'Question type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFlashcardQuestionTypeGrid(),
                      const SizedBox(height: 24),
                      _buildStartButton(onTap: () => _startFlashcards()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Difficulty type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.beige.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textDark, width: 1.8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircularDifficultyButton('Easy', AppColors.ratingEasy),
                  _buildCircularDifficultyButton('Hard', AppColors.ratingHard),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircularDifficultyButton('Good', AppColors.ratingGood),
                  _buildCircularDifficultyButton(
                    'Again',
                    AppColors.ratingAgain,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: _buildCircularDifficultyButton('All', AppColors.sand),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showDifficultyFilter = false),
            child: const Text(
              'Back to options',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularDifficultyButton(String label, Color color) {
    final bool isSelected = _selectedDifficulty == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = label;
          _showDifficultyFilter = false;
        });
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textDark,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. WORD BUILDER SETUP CARD
  // ===========================================================================
  Widget _buildWordBuilderSetupCard() {
    final systemName = _isHiragana ? 'Hiragana' : 'Katakana';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textDark, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.textDark,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.sand,
              border: Border(
                bottom: BorderSide(color: AppColors.textDark, width: 2),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _activeSubScreen = null),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textDark,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Word Builder',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Kana Row selector
                const Text(
                  'Kana',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                _buildAccordionSelector(systemName),
                const SizedBox(height: 22),

                // 2. Question type (2 cards side by side)
                const Text(
                  'Question type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.beige.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textDark, width: 1.8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSelectablePill(
                          isSelected:
                              _wbQuestionType ==
                              WordBuilderQuestionType.kanaToRomaji,
                          title: '${_isHiragana ? "あ" : "ア"}  ➔  a',
                          subtitle: 'Kana to romaji',
                          onTap: () => setState(
                            () => _wbQuestionType =
                                WordBuilderQuestionType.kanaToRomaji,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSelectablePill(
                          isSelected:
                              _wbQuestionType ==
                              WordBuilderQuestionType.romajiToKana,
                          title: 'a  ➔  ${_isHiragana ? "あ" : "ア"}',
                          subtitle: 'Romaji to kana',
                          onTap: () => setState(
                            () => _wbQuestionType =
                                WordBuilderQuestionType.romajiToKana,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Word length
                const Text(
                  'Word length',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.beige.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textDark, width: 1.8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSelectablePill(
                          isSelected: _wbLength == WordLength.short,
                          title: 'Short',
                          subtitle: '2-3 kana per word',
                          onTap: () =>
                              setState(() => _wbLength = WordLength.short),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSelectablePill(
                          isSelected: _wbLength == WordLength.medium,
                          title: 'Medium',
                          subtitle: '4-5 kana per word',
                          onTap: () =>
                              setState(() => _wbLength = WordLength.medium),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSelectablePill(
                          isSelected: _wbLength == WordLength.long,
                          title: 'Long',
                          subtitle: '6+ kana per word',
                          onTap: () =>
                              setState(() => _wbLength = WordLength.long),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 4. Words per round
                const Text(
                  'Words per round',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.beige.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textDark, width: 1.8),
                  ),
                  child: Row(
                    children: [10, 20, 30, 40].map((count) {
                      final isSelected = _wbWordsPerRound == count;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _wbWordsPerRound = count),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.sand
                                    : AppColors.beige,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.textDark,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textDark,
                                    offset: Offset(0, isSelected ? 1 : 3),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Start Game Button
                _buildStartButton(onTap: () => _startWordBuilder()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectablePill({
    required bool isSelected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sand : AppColors.beige,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textDark,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, isSelected ? 1 : 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // REUSABLE ACCORDION ROW SELECTOR & HELPERS
  // ===========================================================================
  Widget _buildAccordionSelector(String systemName) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textDark, width: 1.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isRowsExpanded = !_isRowsExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.textDark, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: AppColors.textDark,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select $systemName rows',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_totalSelectedCharactersCount $systemName selected',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isRowsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textDark,
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
          if (_isRowsExpanded) ...[
            const Divider(color: AppColors.textDark, height: 1, thickness: 1.5),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySection(
                    title: 'Basic $systemName',
                    currentCount: _selectedCountIn(_basicRows),
                    totalCount: _basicRows.length,
                    rows: _basicRows,
                    onHeaderTap: () => _toggleAllIn(_basicRows),
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySection(
                    title: 'Dakuon $systemName',
                    currentCount: _selectedCountIn(_dakuonRows),
                    totalCount: _dakuonRows.length,
                    rows: _dakuonRows,
                    onHeaderTap: () => _toggleAllIn(_dakuonRows),
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySection(
                    title: 'Yoon $systemName',
                    currentCount: _selectedCountIn(_yoonRows),
                    totalCount: _yoonRows.length,
                    rows: _yoonRows,
                    onHeaderTap: () => _toggleAllIn(_yoonRows),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashcardQuestionTypeGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.beige.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textDark, width: 1.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSelectablePill(
                  isSelected:
                      _selectedQuestionType ==
                      FlashcardQuestionType.kanaToRomaji,
                  title: '${_isHiragana ? "あ" : "ア"}  ➔  a',
                  subtitle: 'Kana to romaji',
                  onTap: () => setState(
                    () => _selectedQuestionType =
                        FlashcardQuestionType.kanaToRomaji,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSelectablePill(
                  isSelected:
                      _selectedQuestionType == FlashcardQuestionType.listening,
                  title: '🔊  ➔  ${_isHiragana ? "あ" : "ア"}ᵃ',
                  subtitle: 'Listening',
                  onTap: () => setState(
                    () =>
                        _selectedQuestionType = FlashcardQuestionType.listening,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildSelectablePill(
                  isSelected:
                      _selectedQuestionType ==
                      FlashcardQuestionType.romajiToKana,
                  title: 'a  ➔  ${_isHiragana ? "あ" : "ア"}',
                  subtitle: 'Romaji to kana',
                  onTap: () => setState(
                    () => _selectedQuestionType =
                        FlashcardQuestionType.romajiToKana,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSelectablePill(
                  isSelected:
                      _selectedQuestionType == FlashcardQuestionType.mix,
                  title: 'Mix',
                  subtitle: 'All three',
                  onTap: () => setState(
                    () => _selectedQuestionType = FlashcardQuestionType.mix,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required int currentCount,
    required int totalCount,
    required List<Map<String, dynamic>> rows,
    required VoidCallback onHeaderTap,
  }) {
    final bool allSelected = currentCount == totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onHeaderTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: allSelected ? AppColors.sand : AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textDark, width: 1.5),
                ),
                child: allSelected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.textDark,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '$currentCount/$totalCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...rows.map((row) {
          final id = row['id'] as String;
          final chars = _isHiragana
              ? (row['h'] as List<String>)
              : (row['k'] as List<String>);
          final bool isSelected = _selectedRowIds.contains(id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildRowItem(
              chars: chars,
              isSelected: isSelected,
              onToggle: () {
                setState(() {
                  if (isSelected) {
                    _selectedRowIds.remove(id);
                  } else {
                    _selectedRowIds.add(id);
                  }
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRowItem({
    required List<String> chars,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.sand.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.textDark, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: List.generate(5, (index) {
                  final text = index < chars.length ? chars[index] : '';
                  return Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: text.isNotEmpty
                          ? AppColors.cream
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: text.isNotEmpty
                          ? Border.all(
                              color: AppColors.textDark.withOpacity(0.5),
                              width: 1,
                            )
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textDark : AppColors.cream,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.textDark, width: 1.5),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton({required VoidCallback onTap}) {
    return _Interactive3DButton(
      label: 'Start',
      icon: Icons.play_arrow,
      bgColor: AppColors.sand,
      onTap: onTap,
    );
  }

  void _startFlashcards() {
    if (_selectedRowIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one row.')),
      );
      return;
    }
    final List<Map<String, String>> activeCards = [];
    void collectFrom(List<Map<String, dynamic>> rows) {
      for (var row in rows) {
        if (_selectedRowIds.contains(row['id'])) {
          final chars = _isHiragana
              ? (row['h'] as List<String>)
              : (row['k'] as List<String>);
          final romajis = row['r'] as List<String>;
          for (int i = 0; i < chars.length; i++) {
            if (chars[i].isNotEmpty) {
              activeCards.add({'kana': chars[i], 'romaji': romajis[i]});
            }
          }
        }
      }
    }

    collectFrom(_basicRows);
    collectFrom(_dakuonRows);
    collectFrom(_yoonRows);
    activeCards.shuffle();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(
          title: '${_isHiragana ? "Hiragana" : "Katakana"} Flashcards',
          cards: activeCards,
          questionType: _selectedQuestionType,
        ),
      ),
    );
  }

  /// Starts the Word Builder session by filtering from the master allVocabulary dataset
  void _startWordBuilder() {
    // 1. Filter by script (Hiragana vs Katakana)
    var filtered = allVocabulary
        .where((w) => w.isHiragana == _isHiragana)
        .toList();

    // 2. Filter by selected word length
    if (_wbLength == WordLength.short) {
      filtered = filtered.where((w) => w.length <= 3).toList();
    } else if (_wbLength == WordLength.medium) {
      filtered = filtered.where((w) => w.length >= 4 && w.length <= 5).toList();
    } else if (_wbLength == WordLength.long) {
      filtered = filtered.where((w) => w.length >= 6).toList();
    }

    // Fallback if the selected length filter yields no results
    if (filtered.isEmpty) {
      filtered = allVocabulary
          .where((w) => w.isHiragana == _isHiragana)
          .toList();
    }

    filtered.shuffle();

    // Navigate to gameplay screen with the filtered dataset
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordBuilderGameScreen(
          isHiragana: _isHiragana,
          questionType: _wbQuestionType,
          totalQuestions: min(_wbWordsPerRound, filtered.length),
          words: filtered,
        ),
      ),
    );
  }
}

// =============================================================================
// 5. WORD BUILDER GAMEPLAY SCREEN
// =============================================================================

class WordBuilderGameScreen extends StatefulWidget {
  final bool isHiragana;
  final WordBuilderQuestionType questionType;
  final int totalQuestions;
  final List<WordBuilderQuestion> words; // Passed filtered dataset

  const WordBuilderGameScreen({
    super.key,
    required this.isHiragana,
    required this.questionType,
    required this.totalQuestions,
    required this.words,
  });

  @override
  State<WordBuilderGameScreen> createState() => _WordBuilderGameScreenState();
}

class _WordBuilderGameScreenState extends State<WordBuilderGameScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  late List<WordBuilderQuestion> _questions;
  int _currentIndex = 0;

  // Player answer state
  late List<String?> _userSlots;
  late List<String> _currentChoices;
  late List<bool> _choiceUsed;

  // Hint & Feedback states
  bool _isHintActive = false;
  bool _hasChecked = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _questions = List.from(widget.words);
    if (_questions.isEmpty) {
      _questions = List.from(
        allVocabulary.where((w) => w.isHiragana == widget.isHiragana),
      );
    }
    _questions.shuffle();
    _loadCurrentQuestion();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ja-JP");
    await _flutterTts.setSpeechRate(0.5);
  }

  void _speakWord(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text.replaceAll(' ', ''));
  }

  void _loadCurrentQuestion() {
    final currentQ = _questions[_currentIndex % _questions.length];
    final bool isRomajiChoices =
        (widget.questionType == WordBuilderQuestionType.kanaToRomaji);
    final targetSyllables = isRomajiChoices
        ? currentQ.syllables
        : currentQ.kanaSyllables;

    _userSlots = List.filled(targetSyllables.length, null);

    // Build choices (correct syllables + distractors)
    final Set<String> choicesPool = Set.from(targetSyllables);
    final distractors = isRomajiChoices
        ? [
            'ma',
            'ru',
            'so',
            'ka',
            'ta',
            'ne',
            'a',
            'ki',
            'shi',
            'to',
            'ha',
            're',
          ]
        : ['あ', 'ら', 'ま', 'る', 'か', 'て', 'す', 'お', 'し', 'と', 'は', 'れ'];

    distractors.shuffle();
    final int targetChoiceCount = max(8, targetSyllables.length);
    for (var d in distractors) {
      if (choicesPool.length >= targetChoiceCount) break;
      choicesPool.add(d);
    }

    _currentChoices = choicesPool.toList()..shuffle();
    _choiceUsed = List.filled(_currentChoices.length, false);
    _isHintActive = false;
    _hasChecked = false;
    _isCorrect = false;

    // Speak audio for question
    _speakWord(currentQ.kana);
  }

  void _onChoiceTapped(int index) {
    if (_hasChecked || _choiceUsed[index]) return;

    // Find first empty slot
    final emptyIndex = _userSlots.indexOf(null);
    if (emptyIndex != -1) {
      setState(() {
        _userSlots[emptyIndex] = _currentChoices[index];
        _choiceUsed[index] = true;
      });
    }
  }

  void _onSlotTapped(int slotIndex) {
    if (_hasChecked || _userSlots[slotIndex] == null) return;

    final value = _userSlots[slotIndex];
    // Return to available choices
    final choiceIndex = _currentChoices.indexOf(value!);
    setState(() {
      _userSlots[slotIndex] = null;
      if (choiceIndex != -1) {
        _choiceUsed[choiceIndex] = false;
      }
    });
  }

  void _checkAnswer() {
    if (_userSlots.contains(null) || _hasChecked) return;

    final currentQ = _questions[_currentIndex % _questions.length];
    final bool isRomajiChoices =
        (widget.questionType == WordBuilderQuestionType.kanaToRomaji);
    final targetSyllables = isRomajiChoices
        ? currentQ.syllables
        : currentQ.kanaSyllables;

    bool match = true;
    for (int i = 0; i < targetSyllables.length; i++) {
      if (_userSlots[i]?.toLowerCase() != targetSyllables[i].toLowerCase()) {
        match = false;
        break;
      }
    }

    setState(() {
      _hasChecked = true;
      _isCorrect = match;
    });

    _speakWord(currentQ.kana);
  }

  void _advanceToNext() {
    if (_currentIndex < widget.totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _loadCurrentQuestion();
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex % _questions.length];
    final bool isRomajiChoices =
        (widget.questionType == WordBuilderQuestionType.kanaToRomaji);
    final targetSyllables = isRomajiChoices
        ? currentQ.syllables
        : currentQ.kanaSyllables;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Header Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(color: AppColors.textDark, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.textDark,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Word Builder',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Gameplay Card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.textDark, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.textDark,
                            offset: Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Progress Text & Bar
                          Text(
                            '${_currentIndex} of ${widget.totalQuestions}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: (_currentIndex) / widget.totalQuestions,
                            backgroundColor: AppColors.beige,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.taupe,
                            ),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 16),

                          // Prompt Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.beige.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.textDark,
                                width: 1.8,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isRomajiChoices
                                          ? 'Choose the correct romaji'
                                          : 'Choose the correct ${widget.isHiragana ? "Hiragana" : "Katakana"}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _speakWord(currentQ.kana),
                                      child: const Icon(
                                        Icons.volume_up_rounded,
                                        color: AppColors.textDark,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isRomajiChoices
                                      ? currentQ.kana
                                      : currentQ.romaji,
                                  style: TextStyle(
                                    fontSize: isRomajiChoices ? 36 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentQ.english,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Target Slots (Green or Red on validation)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    targetSyllables.length,
                                    (i) {
                                      final val = _userSlots[i];
                                      Color borderColor = AppColors.textDark;
                                      Color slotBg = val != null
                                          ? AppColors.cream
                                          : AppColors.sand.withOpacity(0.5);

                                      if (_hasChecked) {
                                        borderColor = _isCorrect
                                            ? Colors.green
                                            : Colors.red;
                                      }

                                      return GestureDetector(
                                        onTap: () => _onSlotTapped(i),
                                        child: Container(
                                          width: 58,
                                          height: 58,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: slotBg,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: borderColor,
                                              width: _hasChecked ? 2.5 : 1.5,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            val ?? '',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 2x4 Grid of Choices (Green border when Hint is tapped)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _currentChoices.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1.0,
                                ),
                            itemBuilder: (context, i) {
                              final text = _currentChoices[i];
                              final isUsed = _choiceUsed[i];

                              final bool isPartOfAnswer = targetSyllables
                                  .map((s) => s.toLowerCase())
                                  .contains(text.toLowerCase());
                              final bool highlightHint =
                                  _isHintActive && isPartOfAnswer && !isUsed;

                              return GestureDetector(
                                onTap: () => _onChoiceTapped(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: isUsed
                                        ? AppColors.beige.withOpacity(0.3)
                                        : AppColors.cream,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: highlightHint
                                          ? Colors.green
                                          : AppColors.textDark,
                                      width: highlightHint ? 2.8 : 1.5,
                                    ),
                                    boxShadow: isUsed
                                        ? []
                                        : const [
                                            BoxShadow(
                                              color: AppColors.textDark,
                                              offset: Offset(0, 3),
                                              blurRadius: 0,
                                            ),
                                          ],
                                  ),
                                  alignment: Alignment.center,
                                  child: isUsed
                                      ? null
                                      : Text(
                                          text,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Action Buttons: 💡 Hint and ✓ Check
                          Row(
                            children: [
                              // Hint Button
                              Expanded(
                                flex: 2,
                                child: _Interactive3DButton(
                                  label: 'Hint',
                                  icon: Icons.lightbulb_outline,
                                  bgColor: AppColors.sand,
                                  onTap: () {
                                    setState(() {
                                      _isHintActive = true;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Check Button
                              Expanded(
                                flex: 3,
                                child: _Interactive3DButton(
                                  label: 'Check',
                                  icon: Icons.check,
                                  bgColor: AppColors.taupe,
                                  onTap: () => _checkAnswer(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Sliding Bottom Feedback Banner (Correct / Not Quite)
            if (_hasChecked)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isCorrect
                        ? const Color(0xFFD3EEDD)
                        : const Color(0xFFF7D2CE),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border.all(color: AppColors.textDark, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.textDark,
                        offset: Offset(0, -3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isCorrect ? Icons.check_circle : Icons.cancel,
                            color: _isCorrect
                                ? const Color(0xFF4A885B)
                                : const Color(0xFFB54C43),
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isCorrect ? 'Correct' : 'Not Quite',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isCorrect
                                  ? const Color(0xFF2E633C)
                                  : const Color(0xFF8C342C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentQ.kana,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        currentQ.syllables.join(' • '),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Continue Button
                      GestureDetector(
                        onTap: () => _advanceToNext(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _isCorrect
                                ? const Color(0xFFA2D3AD)
                                : const Color(0xFFE28B83),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.textDark,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.textDark,
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPER 3D INTERACTIVE BUTTONS
// -----------------------------------------------------------------------------

class _Interactive3DCard extends StatefulWidget {
  final Widget child;
  final Color bgColor;
  final VoidCallback onTap;

  const _Interactive3DCard({
    required this.child,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<_Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<_Interactive3DCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        transform: Matrix4.translationValues(0, _isPressed ? 4.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textDark, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, _isPressed ? 0 : 4.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _Interactive3DButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final VoidCallback onTap;

  const _Interactive3DButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<_Interactive3DButton> createState() => _Interactive3DButtonState();
}

class _Interactive3DButtonState extends State<_Interactive3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        transform: Matrix4.translationValues(0, _isPressed ? 3.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textDark, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, _isPressed ? 0 : 3.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: AppColors.textDark, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
