import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Imports native text-to-speech engine
import 'write_screen.dart'; // Imports the drawing screen
import 'quiz_screen.dart'; // Imports the interactive quiz screen

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
}

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  // Master toggle state: True = Hiragana (Green), False = Katakana (Blue)
  bool _isHiragana = true;

  // Sound toggle state: Controls whether tapping cards plays audio
  bool _isSoundEnabled = true;

  // Native text-to-speech controller instance
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  /// Initializes the speech engine with Japanese language settings
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ja-JP");
    await _flutterTts.setSpeechRate(0.5); // Comfortable learning speed
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Speaks the selected kana character using native device speech synthesis
  Future<void> _speakKana(String kana) async {
    if (!_isSoundEnabled || kana.isEmpty) return;
    await _flutterTts.stop(); // Stop any overlapping speech queues
    await _flutterTts.speak(kana);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.beige,
      child: Column(
        children: [
          _buildTopHeader(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [_buildMainCard(), const SizedBox(height: 40)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: AppColors.textDark, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Kana Learn',
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

  /// Custom rounded pill toggle switch for Hiragana vs Katakana
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
          // Hiragana Option (あ)
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
          // Katakana Option (ア)
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

  /// Builds the large central container holding the progress header and ALL Kana rows.
  Widget _buildMainCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textDark, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.textDark,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TITLE & SPEAKER TOGGLE ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Basic Kana',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    // Sound Master Toggle Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSoundEnabled = !_isSoundEnabled;
                        });
                      },
                      child: Icon(
                        _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                        color: AppColors.textDark,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- BASIC KANA ROWS ---
                _buildKanaRowGroup(
                  'A row',
                  _isHiragana
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
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ka row',
                  _isHiragana
                      ? [
                          {'kana': 'か', 'romaji': 'ka'},
                          {'kana': 'き', 'romaji': 'ki'},
                          {'kana': 'く', 'romaji': 'ku'},
                          {'kana': 'け', 'romaji': 'ke'},
                          {'kana': 'こ', 'romaji': 'ko'},
                        ]
                      : [
                          {'kana': 'カ', 'romaji': 'ka'},
                          {'kana': 'キ', 'romaji': 'ki'},
                          {'kana': 'ク', 'romaji': 'ku'},
                          {'kana': 'ケ', 'romaji': 'ke'},
                          {'kana': 'コ', 'romaji': 'ko'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Sa row',
                  _isHiragana
                      ? [
                          {'kana': 'さ', 'romaji': 'sa'},
                          {'kana': 'し', 'romaji': 'shi'},
                          {'kana': 'す', 'romaji': 'su'},
                          {'kana': 'せ', 'romaji': 'se'},
                          {'kana': 'そ', 'romaji': 'so'},
                        ]
                      : [
                          {'kana': 'サ', 'romaji': 'sa'},
                          {'kana': 'シ', 'romaji': 'shi'},
                          {'kana': 'ス', 'romaji': 'su'},
                          {'kana': 'セ', 'romaji': 'se'},
                          {'kana': 'ソ', 'romaji': 'so'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ta row',
                  _isHiragana
                      ? [
                          {'kana': 'た', 'romaji': 'ta'},
                          {'kana': 'ち', 'romaji': 'chi'},
                          {'kana': 'つ', 'romaji': 'tsu'},
                          {'kana': 'て', 'romaji': 'te'},
                          {'kana': 'と', 'romaji': 'to'},
                        ]
                      : [
                          {'kana': 'タ', 'romaji': 'ta'},
                          {'kana': 'チ', 'romaji': 'chi'},
                          {'kana': 'ツ', 'romaji': 'tsu'},
                          {'kana': 'テ', 'romaji': 'te'},
                          {'kana': 'ト', 'romaji': 'to'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Na row',
                  _isHiragana
                      ? [
                          {'kana': 'な', 'romaji': 'na'},
                          {'kana': 'に', 'romaji': 'ni'},
                          {'kana': 'ぬ', 'romaji': 'nu'},
                          {'kana': 'ね', 'romaji': 'ne'},
                          {'kana': 'の', 'romaji': 'no'},
                        ]
                      : [
                          {'kana': 'ナ', 'romaji': 'na'},
                          {'kana': 'ニ', 'romaji': 'ni'},
                          {'kana': 'ヌ', 'romaji': 'nu'},
                          {'kana': 'ネ', 'romaji': 'ne'},
                          {'kana': 'ノ', 'romaji': 'no'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ha row',
                  _isHiragana
                      ? [
                          {'kana': 'は', 'romaji': 'ha'},
                          {'kana': 'ひ', 'romaji': 'hi'},
                          {'kana': 'ふ', 'romaji': 'fu'},
                          {'kana': 'へ', 'romaji': 'he'},
                          {'kana': 'ほ', 'romaji': 'ho'},
                        ]
                      : [
                          {'kana': 'ハ', 'romaji': 'ha'},
                          {'kana': 'ヒ', 'romaji': 'hi'},
                          {'kana': 'フ', 'romaji': 'fu'},
                          {'kana': 'ヘ', 'romaji': 'he'},
                          {'kana': 'ホ', 'romaji': 'ho'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ma row',
                  _isHiragana
                      ? [
                          {'kana': 'ま', 'romaji': 'ma'},
                          {'kana': 'み', 'romaji': 'mi'},
                          {'kana': 'む', 'romaji': 'mu'},
                          {'kana': 'め', 'romaji': 'me'},
                          {'kana': 'も', 'romaji': 'mo'},
                        ]
                      : [
                          {'kana': 'マ', 'romaji': 'ma'},
                          {'kana': 'ミ', 'romaji': 'mi'},
                          {'kana': 'ム', 'romaji': 'mu'},
                          {'kana': 'メ', 'romaji': 'me'},
                          {'kana': 'モ', 'romaji': 'mo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ya row',
                  _isHiragana
                      ? [
                          {'kana': 'や', 'romaji': 'ya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ゆ', 'romaji': 'yu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'よ', 'romaji': 'yo'},
                        ]
                      : [
                          {'kana': 'ヤ', 'romaji': 'ya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ユ', 'romaji': 'yu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ヨ', 'romaji': 'yo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ra row',
                  _isHiragana
                      ? [
                          {'kana': 'ら', 'romaji': 'ra'},
                          {'kana': 'り', 'romaji': 'ri'},
                          {'kana': 'る', 'romaji': 'ru'},
                          {'kana': 'れ', 'romaji': 're'},
                          {'kana': 'ろ', 'romaji': 'ro'},
                        ]
                      : [
                          {'kana': 'ラ', 'romaji': 'ra'},
                          {'kana': 'リ', 'romaji': 'ri'},
                          {'kana': 'ル', 'romaji': 'ru'},
                          {'kana': 'レ', 'romaji': 're'},
                          {'kana': 'ロ', 'romaji': 'ro'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Wa / N row',
                  _isHiragana
                      ? [
                          {'kana': 'わ', 'romaji': 'wa'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'を', 'romaji': 'wo'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ん', 'romaji': 'n'},
                        ]
                      : [
                          {'kana': 'ワ', 'romaji': 'wa'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ヲ', 'romaji': 'wo'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ン', 'romaji': 'n'},
                        ],
                ),

                const SizedBox(height: 32),

                // --- DAKUON & HANDAKUON ROWS ---
                const Text(
                  'Dakuon',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'G row',
                  _isHiragana
                      ? [
                          {'kana': 'が', 'romaji': 'ga'},
                          {'kana': 'ぎ', 'romaji': 'gi'},
                          {'kana': 'ぐ', 'romaji': 'gu'},
                          {'kana': 'げ', 'romaji': 'ge'},
                          {'kana': 'ご', 'romaji': 'go'},
                        ]
                      : [
                          {'kana': 'ガ', 'romaji': 'ga'},
                          {'kana': 'ギ', 'romaji': 'gi'},
                          {'kana': 'グ', 'romaji': 'gu'},
                          {'kana': 'ゲ', 'romaji': 'ge'},
                          {'kana': 'ゴ', 'romaji': 'go'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Za row',
                  _isHiragana
                      ? [
                          {'kana': 'ざ', 'romaji': 'za'},
                          {'kana': 'じ', 'romaji': 'ji'},
                          {'kana': 'ず', 'romaji': 'zu'},
                          {'kana': 'ぜ', 'romaji': 'ze'},
                          {'kana': 'ぞ', 'romaji': 'zo'},
                        ]
                      : [
                          {'kana': 'ザ', 'romaji': 'za'},
                          {'kana': 'ジ', 'romaji': 'ji'},
                          {'kana': 'ズ', 'romaji': 'zu'},
                          {'kana': 'ゼ', 'romaji': 'ze'},
                          {'kana': 'ゾ', 'romaji': 'zo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Da row',
                  _isHiragana
                      ? [
                          {'kana': 'だ', 'romaji': 'da'},
                          {'kana': 'ぢ', 'romaji': 'ji'},
                          {'kana': 'づ', 'romaji': 'zu'},
                          {'kana': 'で', 'romaji': 'de'},
                          {'kana': 'ど', 'romaji': 'do'},
                        ]
                      : [
                          {'kana': 'ダ', 'romaji': 'da'},
                          {'kana': 'ヂ', 'romaji': 'ji'},
                          {'kana': 'ヅ', 'romaji': 'zu'},
                          {'kana': 'デ', 'romaji': 'de'},
                          {'kana': 'ド', 'romaji': 'do'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ba row',
                  _isHiragana
                      ? [
                          {'kana': 'ば', 'romaji': 'ba'},
                          {'kana': 'び', 'romaji': 'bi'},
                          {'kana': 'ぶ', 'romaji': 'bu'},
                          {'kana': 'べ', 'romaji': 'be'},
                          {'kana': 'ぼ', 'romaji': 'bo'},
                        ]
                      : [
                          {'kana': 'バ', 'romaji': 'ba'},
                          {'kana': 'ビ', 'romaji': 'bi'},
                          {'kana': 'ブ', 'romaji': 'bu'},
                          {'kana': 'ベ', 'romaji': 'be'},
                          {'kana': 'ボ', 'romaji': 'bo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Pa row',
                  _isHiragana
                      ? [
                          {'kana': 'ぱ', 'romaji': 'pa'},
                          {'kana': 'ぴ', 'romaji': 'pi'},
                          {'kana': 'ぷ', 'romaji': 'pu'},
                          {'kana': 'ぺ', 'romaji': 'pe'},
                          {'kana': 'ぽ', 'romaji': 'po'},
                        ]
                      : [
                          {'kana': 'パ', 'romaji': 'pa'},
                          {'kana': 'ピ', 'romaji': 'pi'},
                          {'kana': 'プ', 'romaji': 'pu'},
                          {'kana': 'ペ', 'romaji': 'pe'},
                          {'kana': 'ポ', 'romaji': 'po'},
                        ],
                ),

                const SizedBox(height: 32),

                // --- YOON (Contracted Sounds) ROWS ---
                const Text(
                  'Yoon',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Kya row',
                  _isHiragana
                      ? [
                          {'kana': 'きゃ', 'romaji': 'kya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'きゅ', 'romaji': 'kyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'きょ', 'romaji': 'kyo'},
                        ]
                      : [
                          {'kana': 'キャ', 'romaji': 'kya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'キュ', 'romaji': 'kyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'キョ', 'romaji': 'kyo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Sha row',
                  _isHiragana
                      ? [
                          {'kana': 'しゃ', 'romaji': 'sha'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'しゅ', 'romaji': 'shu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'しょ', 'romaji': 'sho'},
                        ]
                      : [
                          {'kana': 'シャ', 'romaji': 'sha'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'シュ', 'romaji': 'shu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ショ', 'romaji': 'sho'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Cha row',
                  _isHiragana
                      ? [
                          {'kana': 'ちゃ', 'romaji': 'cha'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ちゅ', 'romaji': 'chu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ちょ', 'romaji': 'cho'},
                        ]
                      : [
                          {'kana': 'チャ', 'romaji': 'cha'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'チュ', 'romaji': 'chu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'チョ', 'romaji': 'cho'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Nya row',
                  _isHiragana
                      ? [
                          {'kana': 'にゃ', 'romaji': 'nya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'にゅ', 'romaji': 'nyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'にょ', 'romaji': 'nyo'},
                        ]
                      : [
                          {'kana': 'ニャ', 'romaji': 'nya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ニュ', 'romaji': 'nyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ニョ', 'romaji': 'nyo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Hya row',
                  _isHiragana
                      ? [
                          {'kana': 'ひゃ', 'romaji': 'hya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ひゅ', 'romaji': 'hyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ひょ', 'romaji': 'hyo'},
                        ]
                      : [
                          {'kana': 'ヒャ', 'romaji': 'hya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ヒュ', 'romaji': 'hyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ヒョ', 'romaji': 'hyo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Mya row',
                  _isHiragana
                      ? [
                          {'kana': 'みゃ', 'romaji': 'mya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'みゅ', 'romaji': 'myu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'みょ', 'romaji': 'myo'},
                        ]
                      : [
                          {'kana': 'ミャ', 'romaji': 'mya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ミュ', 'romaji': 'myu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ミョ', 'romaji': 'myo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Rya row',
                  _isHiragana
                      ? [
                          {'kana': 'りゃ', 'romaji': 'rya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'りゅ', 'romaji': 'ryu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'りょ', 'romaji': 'ryo'},
                        ]
                      : [
                          {'kana': 'リャ', 'romaji': 'rya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'リュ', 'romaji': 'ryu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'リョ', 'romaji': 'ryo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Gya row',
                  _isHiragana
                      ? [
                          {'kana': 'ぎゃ', 'romaji': 'gya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ぎゅ', 'romaji': 'gyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ぎょ', 'romaji': 'gyo'},
                        ]
                      : [
                          {'kana': 'ギャ', 'romaji': 'gya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ギュ', 'romaji': 'gyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ギョ', 'romaji': 'gyo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ja row',
                  _isHiragana
                      ? [
                          {'kana': 'じゃ', 'romaji': 'ja'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'じゅ', 'romaji': 'ju'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'じょ', 'romaji': 'jo'},
                        ]
                      : [
                          {'kana': 'ジャ', 'romaji': 'ja'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ジュ', 'romaji': 'ju'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ジョ', 'romaji': 'jo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Bya row',
                  _isHiragana
                      ? [
                          {'kana': 'びゃ', 'romaji': 'bya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'びゅ', 'romaji': 'byu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'びょ', 'romaji': 'byo'},
                        ]
                      : [
                          {'kana': 'ビャ', 'romaji': 'bya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ビュ', 'romaji': 'byu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ビョ', 'romaji': 'byo'},
                        ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Pya row',
                  _isHiragana
                      ? [
                          {'kana': 'ぴゃ', 'romaji': 'pya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ぴゅ', 'romaji': 'pyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ぴょ', 'romaji': 'pyo'},
                        ]
                      : [
                          {'kana': 'ピャ', 'romaji': 'pya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ピュ', 'romaji': 'pyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ピョ', 'romaji': 'pyo'},
                        ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the light green/blue header. Colors and titles dynamically change based on the toggle.
  Widget _buildCardHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isHiragana ? AppColors.lightSage : AppColors.lightSkyBlue,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: const Border(
          bottom: BorderSide(color: AppColors.textDark, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isHiragana ? 'ひらがな' : 'カタカナ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                _isHiragana ? 'Hiragana Row' : 'Katakana Row',
                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '0/104', // 46 basic + 25 dakuon/handakuon + 33 yoon
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 6,
                decoration: BoxDecoration(
                  color: (_isHiragana ? AppColors.sage : AppColors.skyBlue)
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKanaRowGroup(String rowName, List<Map<String, String>> chars) {
    final charBgColor = _isHiragana
        ? AppColors.lightSage
        : AppColors.lightSkyBlue;
    final quizBgColor = _isHiragana ? AppColors.sage : AppColors.skyBlue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textDark, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rowName,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: chars
                .map(
                  (c) => Interactive3DCharButton(
                    kana: c['kana']!,
                    romaji: c['romaji']!,
                    bgColor: charBgColor,
                    isSoundEnabled: _isSoundEnabled,
                    onTapAudio: () => _speakKana(c['kana']!),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Interactive3DActionButton(
                label: 'Write',
                bgColor: AppColors.taupe,
                onTap: () {
                  final validChars = chars
                      .where((c) => c['kana']!.isNotEmpty)
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WriteScreen(
                        rowTitle: rowName,
                        characters: validChars,
                      ),
                    ),
                  );
                },
              ),
              // --- QUIZ BUTTON HOOKUP ---
              Interactive3DActionButton(
                label: 'Quiz',
                bgColor: quizBgColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        rowTitle: rowName,
                        writingSystem: _isHiragana ? "Hiragana" : "Katakana",
                        characters: chars,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// INTERACTIVE BUTTON COMPONENTS
// -----------------------------------------------------------------------------

/// An interactive, 3D animated button for the individual Kana characters.
class Interactive3DCharButton extends StatefulWidget {
  final String kana;
  final String romaji;
  final Color bgColor;
  final bool isSoundEnabled;
  final VoidCallback onTapAudio;

  const Interactive3DCharButton({
    super.key,
    required this.kana,
    required this.romaji,
    required this.bgColor,
    required this.isSoundEnabled,
    required this.onTapAudio,
  });

  @override
  State<Interactive3DCharButton> createState() =>
      _Interactive3DCharButtonState();
}

class _Interactive3DCharButtonState extends State<Interactive3DCharButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.kana.isEmpty) {
      return const SizedBox(width: 48, height: 56);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.isSoundEnabled) {
          widget.onTapAudio(); // Triggers native text-to-speech pronunciation
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        width: 48,
        height: 56,
        transform: Matrix4.translationValues(0, _isPressed ? 4.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textDark, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, _isPressed ? 0 : 4.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.kana,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              widget.romaji,
              style: const TextStyle(fontSize: 10, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}

/// An interactive, 3D animated button for the "Write" and "Quiz" actions.
class Interactive3DActionButton extends StatefulWidget {
  final String label;
  final Color bgColor;
  final VoidCallback onTap;

  const Interactive3DActionButton({
    super.key,
    required this.label,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<Interactive3DActionButton> createState() =>
      _Interactive3DActionButtonState();
}

class _Interactive3DActionButtonState extends State<Interactive3DActionButton> {
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        transform: Matrix4.translationValues(0, _isPressed ? 3.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.textDark, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, _isPressed ? 0 : 3.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
