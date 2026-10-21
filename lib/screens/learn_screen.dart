import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Imports native text-to-speech engine[cite: 23]
import 'write_screen.dart'; // Imports the drawing screen[cite: 23]
import 'quiz_screen.dart'; // Imports the interactive quiz/practice screen[cite: 23]
import '../services/progress_service.dart'; // Imports persistent progress service for real-time mastery counts and row locks[cite: 23]
import '../utils/tactile_feedback.dart'; // Imports tactile stationery mechanical clicks and haptic feedback

// --- COLOR PALETTE ---
class AppColors {
  static const Color cream = Color(0xFFFDF8F3);
  static const Color beige = Color(0xFFEADFD1);
  static const Color sand = Color(0xFFDCC6A8);
  static const Color taupe = Color(0xFFC6B8A5);
  static const Color textDark = Color(0xFF5D534A);
  static const Color textLight = Color(0xFF8B8076);

  // Hiragana Colors (Green)[cite: 23]
  static const Color sage = Color(0xFFB7C9B2);
  static const Color lightSage = Color(0xFFE4EFE7);

  // Katakana Colors (Blue)[cite: 23]
  static const Color skyBlue = Color(0xFFA5C4E5);
  static const Color lightSkyBlue = Color(0xFFEBF0F5);
}

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  // Sound toggle state: Controls whether tapping cards plays audio[cite: 23]
  bool _isSoundEnabled = true;

  // Native text-to-speech controller instance[cite: 23]
  final FlutterTts _flutterTts = FlutterTts();

  // Basic row progression order used to enforce prerequisite completion
  final List<String> _basicRowOrder = [
    'A row',
    'Ka row',
    'Sa row',
    'Ta row',
    'Na row',
    'Ha row',
    'Ma row',
    'Ya row',
    'Ra row',
    'Wa / N row',
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  /// Initializes the speech engine with Japanese language settings[cite: 23]
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ja-JP");
    await _flutterTts.setSpeechRate(
      0.5,
    ); // Comfortable learning speed[cite: 23]
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Speaks the selected kana character using native device speech synthesis[cite: 23]
  Future<void> _speakKana(String kana) async {
    if (!_isSoundEnabled || kana.isEmpty) return;
    await _flutterTts.stop(); // Stop any overlapping speech queues[cite: 23]
    await _flutterTts.speak(kana);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder ensures the screen responds immediately when ProgressService updates
    // (such as when switching from Home via "Continue Katakana" or when finishing a quiz row)
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final ps = ProgressService.instance;
        final bool isHiragana = ps.selectedLearnIsHiragana;
        final String writingSystem = isHiragana ? 'Hiragana' : 'Katakana';

        return Container(
          color: AppColors.beige,
          child: Column(
            children: [
              _buildTopHeader(isHiragana),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  children: [
                    _buildMainCard(isHiragana, writingSystem, ps),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- UNTOUCHED ORIGINAL TOP HEADER ---
  Widget _buildTopHeader(bool isHiragana) {
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
          _buildToggle(isHiragana),
        ],
      ),
    );
  }

  /// Custom rounded pill toggle switch synchronized with ProgressService[cite: 23]
  Widget _buildToggle(bool isHiragana) {
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
          // Hiragana Option (あ)[cite: 23]
          GestureDetector(
            onTap: () {
              TactileFeedback.toggle(); // Tactile tick on script switch
              ProgressService.instance.setLearnScript(isHiragana: true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isHiragana ? AppColors.taupe : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHiragana ? AppColors.textDark : Colors.transparent,
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
          // Katakana Option (ア)[cite: 23]
          GestureDetector(
            onTap: () {
              TactileFeedback.toggle(); // Tactile tick on script switch
              ProgressService.instance.setLearnScript(isHiragana: false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: !isHiragana ? AppColors.taupe : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !isHiragana ? AppColors.textDark : Colors.transparent,
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

  /// Builds the large central container holding the progress header and ALL Kana rows[cite: 23].
  Widget _buildMainCard(
    bool isHiragana,
    String writingSystem,
    ProgressService ps,
  ) {
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
          _buildCardHeader(isHiragana, ps),

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
                    // Sound Master Toggle Button[cite: 23]
                    GestureDetector(
                      onTap: () {
                        TactileFeedback.toggle();
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

                // --- BASIC KANA ROWS (SEQUENTIALLY UNLOCKED) ---
                ..._buildBasicRowsWithPrerequisites(
                  isHiragana,
                  writingSystem,
                  ps,
                ),

                const SizedBox(height: 32),

                // --- DAKUON & HANDAKUON ROWS ---[cite: 23]
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? [
                          {'kana': 'だ', 'romaji': 'da'},
                          {'kana': 'ぢ', 'romaji': 'ji'},
                          {'kana': 'づ', 'romaji': 'zu'},
                          {'kana': 'de', 'romaji': 'de'},
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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

                // --- YOON (Contracted Sounds) ROWS ---[cite: 23]
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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
                  isHiragana,
                  writingSystem,
                  isHiragana
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

  /// Builds the basic 10 rows while enforcing sequential locks based on prerequisite completion
  List<Widget> _buildBasicRowsWithPrerequisites(
    bool isHiragana,
    String writingSystem,
    ProgressService ps,
  ) {
    final Map<String, List<Map<String, String>>> basicRowsData = {
      'A row': isHiragana
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
      'Ka row': isHiragana
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
      'Sa row': isHiragana
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
      'Ta row': isHiragana
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
      'Na row': isHiragana
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
      'Ha row': isHiragana
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
      'Ma row': isHiragana
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
      'Ya row': isHiragana
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
      'Ra row': isHiragana
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
      'Wa / N row': isHiragana
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
    };

    List<Widget> widgets = [];

    for (int i = 0; i < _basicRowOrder.length; i++) {
      final rowKey = _basicRowOrder[i];
      bool isLocked = false;
      String prerequisiteName = '';

      // First row ('A row') is always unlocked; subsequent rows require the previous row finished
      if (i > 0) {
        final prevRowKey = _basicRowOrder[i - 1];
        prerequisiteName = prevRowKey;
        final bool prevCompleted = ps.isRowCompleted(
          writingSystem: writingSystem,
          rowTitle: prevRowKey,
        );
        isLocked = !prevCompleted;
      }

      widgets.add(
        _buildKanaRowGroup(
          rowKey,
          isHiragana,
          writingSystem,
          basicRowsData[rowKey]!,
          isLocked: isLocked,
          prerequisiteName: prerequisiteName,
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  // --- DYNAMIC CARD HEADER LINKED TO PROGRESS SERVICE ---[cite: 23]
  Widget _buildCardHeader(bool isHiragana, ProgressService ps) {
    final int currentMastered = isHiragana
        ? ps.masteredHiraganaCount
        : ps.masteredKatakanaCount;
    final double progressFraction = (currentMastered / 104).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHiragana ? AppColors.lightSage : AppColors.lightSkyBlue,
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
                isHiragana ? 'ひらがな' : 'カタカナ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                isHiragana ? 'Hiragana Row' : 'Katakana Row',
                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentMastered/104',
                style: const TextStyle(
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
                  color: (isHiragana ? AppColors.sage : AppColors.skyBlue)
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progressFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.textDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKanaRowGroup(
    String rowName,
    bool isHiragana,
    String writingSystem,
    List<Map<String, String>> chars, {
    bool isLocked = false,
    String prerequisiteName = '',
  }) {
    final charBgColor = isHiragana
        ? AppColors.lightSage
        : AppColors.lightSkyBlue;
    final buttonBgColor = isHiragana ? AppColors.sage : AppColors.skyBlue;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textDark, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rowName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLocked)
                  const Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.textDark,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Locked',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
              ],
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
                      isSoundEnabled: _isSoundEnabled && !isLocked,
                      isLocked: isLocked,
                      prerequisiteName: prerequisiteName,
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
                    if (isLocked) {
                      TactileFeedback.error(); // Haptic error vibration on locked item tap
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Finish $prerequisiteName first to unlock!',
                          ),
                        ),
                      );
                      return;
                    }
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
                Interactive3DActionButton(
                  label: 'Learn',
                  bgColor: buttonBgColor,
                  onTap: () {
                    if (isLocked) {
                      TactileFeedback.error(); // Haptic error vibration on locked item tap
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Finish $prerequisiteName first to unlock!',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(
                          rowTitle: rowName,
                          writingSystem: writingSystem,
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
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// INTERACTIVE BUTTON COMPONENTS WITH TACTILE CLICKS & HAPTICS[cite: 23]
// -----------------------------------------------------------------------------

/// An interactive, 3D animated button for the individual Kana characters.
class Interactive3DCharButton extends StatefulWidget {
  final String kana;
  final String romaji;
  final Color bgColor;
  final bool isSoundEnabled;
  final bool isLocked;
  final String prerequisiteName;
  final VoidCallback onTapAudio;

  const Interactive3DCharButton({
    super.key,
    required this.kana,
    required this.romaji,
    required this.bgColor,
    required this.isSoundEnabled,
    this.isLocked = false,
    this.prerequisiteName = '',
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
      onTapDown: (_) {
        if (widget.isLocked) {
          TactileFeedback.error();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Finish ${widget.prerequisiteName} first to unlock!',
              ),
            ),
          );
          return;
        }
        TactileFeedback.press(); // Physical tactile click down
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.isLocked) return;
        setState(() => _isPressed = false);
        if (widget.isSoundEnabled) {
          widget
              .onTapAudio(); // Triggers native text-to-speech pronunciation[cite: 23]
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

/// An interactive, 3D animated button for the "Write" and "Learn" actions.
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
      onTapDown: (_) {
        TactileFeedback.press(); // Physical tactile mechanical press down
        setState(() => _isPressed = true);
      },
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
