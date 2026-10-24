import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Imports native text-to-speech engine
import 'package:shared_preferences/shared_preferences.dart'; // Imports SharedPreferences for TTS settings lookup[cite: 11]
import 'write_screen.dart'; // Imports the drawing screen[cite: 11]
import 'quiz_screen.dart'; // Imports the interactive quiz/practice screen[cite: 11]
import '../services/progress_service.dart'; // Imports persistent progress service for real-time mastery counts and row locks[cite: 11]
import '../utils/tactile_feedback.dart'; // Imports tactile stationery mechanical clicks and haptic feedback[cite: 11]

// --- COLOR PALETTE ---
class AppColors {
  static const Color cream = Color(0xFFFDF8F3);
  static const Color beige = Color(0xFFEADFD1);
  static const Color sand = Color(0xFFDCC6A8);
  static const Color taupe = Color(0xFFC6B8A5);
  static const Color textDark = Color(0xFF5D534A);
  static const Color textLight = Color(0xFF8B8076);

  // Hiragana Colors (Green)[cite: 11]
  static const Color sage = Color(0xFFB7C9B2);
  static const Color lightSage = Color(0xFFE4EFE7);

  // Katakana Colors (Blue)[cite: 11]
  static const Color skyBlue = Color(0xFFA5C4E5);
  static const Color lightSkyBlue = Color(0xFFEBF0F5);

  // Celebration & Unlock Gold Accent
  static const Color unlockedGold = Color(0xFFE2B457);
}

/// Kana Learn Screen with Row Unlocking Progression & Celebration Animations.
///
/// Features & Guidelines:
/// 1. Enforces sequential prerequisite locks for Basic Kana, Dakuon, and Yoon sets[cite: 11].
/// 2. Displays a smooth badge bounce and golden glow celebration on row cards when
///    the user returns after completing a prerequisite lesson.
/// 3. Protects locked row action buttons ('Write' & 'Learn') and individual Kana cards
///    with error haptics and helpful prerequisite prompts[cite: 11].
/// 4. Pure lesson flow: navigating to Learn launches the practice quiz directly with
///    `difficulty: 'All'` (no difficulty selection screen)[cite: 11].
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with TickerProviderStateMixin {
  // Sound toggle state: Controls whether tapping cards plays audio[cite: 11]
  bool _isSoundEnabled = true;

  // Native text-to-speech controller instance[cite: 11]
  final FlutterTts _flutterTts = FlutterTts();

  // Tracks unlocked state to trigger animations only when a row transitions from locked -> unlocked
  final Set<String> _knownUnlockedKeys = {};
  String? _celebratedRowKey;

  late AnimationController _unlockAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  // Basic row progression order used to enforce prerequisite completion[cite: 11]
  static const List<String> _basicRowOrder = [
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

  // Static datasets to avoid repeated list allocations during build[cite: 11]
  static const Map<String, List<Map<String, String>>> _basicHiraganaRows = {
    'A row': [
      {'kana': 'あ', 'romaji': 'a'},
      {'kana': 'い', 'romaji': 'i'},
      {'kana': 'う', 'romaji': 'u'},
      {'kana': 'え', 'romaji': 'e'},
      {'kana': 'お', 'romaji': 'o'},
    ],
    'Ka row': [
      {'kana': 'か', 'romaji': 'ka'},
      {'kana': 'き', 'romaji': 'ki'},
      {'kana': 'く', 'romaji': 'ku'},
      {'kana': 'け', 'romaji': 'ke'},
      {'kana': 'こ', 'romaji': 'ko'},
    ],
    'Sa row': [
      {'kana': 'さ', 'romaji': 'sa'},
      {'kana': 'し', 'romaji': 'shi'},
      {'kana': 'す', 'romaji': 'su'},
      {'kana': 'せ', 'romaji': 'se'},
      {'kana': 'そ', 'romaji': 'so'},
    ],
    'Ta row': [
      {'kana': 'た', 'romaji': 'ta'},
      {'kana': 'ち', 'romaji': 'chi'},
      {'kana': 'つ', 'romaji': 'tsu'},
      {'kana': 'て', 'romaji': 'te'},
      {'kana': 'と', 'romaji': 'to'},
    ],
    'Na row': [
      {'kana': 'な', 'romaji': 'na'},
      {'kana': 'に', 'romaji': 'ni'},
      {'kana': 'ぬ', 'romaji': 'nu'},
      {'kana': 'ね', 'romaji': 'ne'},
      {'kana': 'の', 'romaji': 'no'},
    ],
    'Ha row': [
      {'kana': 'は', 'romaji': 'ha'},
      {'kana': 'ひ', 'romaji': 'hi'},
      {'kana': 'ふ', 'romaji': 'fu'},
      {'kana': 'へ', 'romaji': 'he'},
      {'kana': 'ほ', 'romaji': 'ho'},
    ],
    'Ma row': [
      {'kana': 'ま', 'romaji': 'ma'},
      {'kana': 'み', 'romaji': 'mi'},
      {'kana': 'む', 'romaji': 'mu'},
      {'kana': 'め', 'romaji': 'me'},
      {'kana': 'も', 'romaji': 'mo'},
    ],
    'Ya row': [
      {'kana': 'や', 'romaji': 'ya'},
      {'kana': '', 'romaji': ''},
      {'kana': 'ゆ', 'romaji': 'yu'},
      {'kana': '', 'romaji': ''},
      {'kana': 'よ', 'romaji': 'yo'},
    ],
    'Ra row': [
      {'kana': 'ら', 'romaji': 'ra'},
      {'kana': 'り', 'romaji': 'ri'},
      {'kana': 'る', 'romaji': 'ru'},
      {'kana': 'れ', 'romaji': 're'},
      {'kana': 'ろ', 'romaji': 'ro'},
    ],
    'Wa / N row': [
      {'kana': 'わ', 'romaji': 'wa'},
      {'kana': '', 'romaji': ''},
      {'kana': 'を', 'romaji': 'wo'},
      {'kana': '', 'romaji': ''},
      {'kana': 'ん', 'romaji': 'n'},
    ],
  };

  static const Map<String, List<Map<String, String>>> _basicKatakanaRows = {
    'A row': [
      {'kana': 'ア', 'romaji': 'a'},
      {'kana': 'イ', 'romaji': 'i'},
      {'kana': 'ウ', 'romaji': 'u'},
      {'kana': 'エ', 'romaji': 'e'},
      {'kana': 'オ', 'romaji': 'o'},
    ],
    'Ka row': [
      {'kana': 'カ', 'romaji': 'ka'},
      {'kana': 'キ', 'romaji': 'ki'},
      {'kana': 'ク', 'romaji': 'ku'},
      {'kana': 'ケ', 'romaji': 'ke'},
      {'kana': 'コ', 'romaji': 'ko'},
    ],
    'Sa row': [
      {'kana': 'サ', 'romaji': 'sa'},
      {'kana': 'シ', 'romaji': 'shi'},
      {'kana': 'ス', 'romaji': 'su'},
      {'kana': 'セ', 'romaji': 'se'},
      {'kana': 'ソ', 'romaji': 'so'},
    ],
    'Ta row': [
      {'kana': 'タ', 'romaji': 'ta'},
      {'kana': 'チ', 'romaji': 'chi'},
      {'kana': 'ツ', 'romaji': 'tsu'},
      {'kana': 'テ', 'romaji': 'te'},
      {'kana': 'ト', 'romaji': 'to'},
    ],
    'Na row': [
      {'kana': 'ナ', 'romaji': 'na'},
      {'kana': 'ニ', 'romaji': 'ni'},
      {'kana': 'ヌ', 'romaji': 'nu'},
      {'kana': 'ネ', 'romaji': 'ne'},
      {'kana': 'ノ', 'romaji': 'no'},
    ],
    'Ha row': [
      {'kana': 'ハ', 'romaji': 'ha'},
      {'kana': 'ヒ', 'romaji': 'hi'},
      {'kana': 'フ', 'romaji': 'fu'},
      {'kana': 'ヘ', 'romaji': 'he'},
      {'kana': 'ホ', 'romaji': 'ho'},
    ],
    'Ma row': [
      {'kana': 'マ', 'romaji': 'ma'},
      {'kana': 'ミ', 'romaji': 'mi'},
      {'kana': 'ム', 'romaji': 'mu'},
      {'kana': 'メ', 'romaji': 'me'},
      {'kana': 'モ', 'romaji': 'mo'},
    ],
    'Ya row': [
      {'kana': 'ヤ', 'romaji': 'ya'},
      {'kana': '', 'romaji': ''},
      {'kana': 'ユ', 'romaji': 'yu'},
      {'kana': '', 'romaji': ''},
      {'kana': 'ヨ', 'romaji': 'yo'},
    ],
    'Ra row': [
      {'kana': 'ラ', 'romaji': 'ra'},
      {'kana': 'リ', 'romaji': 'ri'},
      {'kana': 'ル', 'romaji': 'ru'},
      {'kana': 'レ', 'romaji': 're'},
      {'kana': 'ロ', 'romaji': 'ro'},
    ],
    'Wa / N row': [
      {'kana': 'ワ', 'romaji': 'wa'},
      {'kana': '', 'romaji': ''},
      {'kana': 'ヲ', 'romaji': 'wo'},
      {'kana': '', 'romaji': ''},
      {'kana': 'ン', 'romaji': 'n'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _initTts();

    // Unlock celebration animation controller (bounce scale + warm golden pulse)
    _unlockAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.035,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.035,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_unlockAnimController);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
    ]).animate(_unlockAnimController);

    _cacheInitialUnlockedRows();
  }

  /// Caches rows that are already unlocked at screen launch to prevent false celebration triggers
  void _cacheInitialUnlockedRows() {
    final ps = ProgressService.instance;
    for (final system in ['Hiragana', 'Katakana']) {
      for (final title in _basicRowOrder) {
        if (ps.isRowUnlocked(writingSystem: system, rowTitle: title)) {
          _knownUnlockedKeys.add('${system}_$title');
        }
      }
      if (ps.isRowUnlocked(writingSystem: system, rowTitle: 'Ga row')) {
        _knownUnlockedKeys.add('${system}_Dakuon');
      }
      if (ps.isRowUnlocked(writingSystem: system, rowTitle: 'Kya row')) {
        _knownUnlockedKeys.add('${system}_Yoon');
      }
    }
  }

  /// Inspects rows and triggers celebration animation when a row is newly cleared
  void _detectNewUnlocks(String writingSystem, ProgressService ps) {
    for (final title in _basicRowOrder) {
      final key = '${writingSystem}_$title';
      final isNowUnlocked = ps.isRowUnlocked(
        writingSystem: writingSystem,
        rowTitle: title,
      );

      if (isNowUnlocked && !_knownUnlockedKeys.contains(key)) {
        _knownUnlockedKeys.add(key);
        _celebratedRowKey = title;

        TactileFeedback.success();
        _unlockAnimController.forward(from: 0.0).then((_) {
          if (!mounted) return;
          Future.delayed(const Duration(milliseconds: 2200), () {
            if (mounted) setState(() => _celebratedRowKey = null);
          });
        });
        break;
      }
    }
  }

  /// Initializes the speech engine synchronized with user audio preferences[cite: 11]
  Future<void> _initTts() async {
    final prefs = await SharedPreferences.getInstance();
    final double rate = prefs.getDouble('settings_speech_rate') ?? 0.5;
    final double volume = prefs.getDouble('settings_speech_volume') ?? 1.0;

    await _flutterTts.setLanguage("ja-JP");
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.setVolume(volume);
    await _flutterTts.setPitch(1.0);
  }

  /// Speaks the selected kana character using native device speech synthesis[cite: 11]
  Future<void> _speakKana(String kana) async {
    if (!_isSoundEnabled || kana.isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.speak(kana);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _unlockAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder ensures the screen responds immediately when ProgressService updates[cite: 11]
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final ps = ProgressService.instance;
        final bool isHiragana = ps.selectedLearnIsHiragana;
        final String writingSystem = isHiragana ? 'Hiragana' : 'Katakana';

        _detectNewUnlocks(writingSystem, ps);

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

  // --- TOP HEADER ---[cite: 11]
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

  /// Custom rounded pill toggle switch synchronized with ProgressService[cite: 11]
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
          // Hiragana Option[cite: 11]
          GestureDetector(
            onTap: () {
              TactileFeedback.toggle();
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
          // Katakana Option[cite: 11]
          GestureDetector(
            onTap: () {
              TactileFeedback.toggle();
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

  /// Builds the large central container holding the progress header and ALL Kana rows[cite: 11].
  Widget _buildMainCard(
    bool isHiragana,
    String writingSystem,
    ProgressService ps,
  ) {
    // Dakuon requires finishing the entire Basic Kana set (Wa / N row)[cite: 11]
    final bool isDakuonLocked =
        !ps.unlockAllRows &&
        !ps.isRowCompleted(
          writingSystem: writingSystem,
          rowTitle: 'Wa / N row',
        );

    // Yoon requires finishing Dakuon rows (Pa row)
    final bool isYoonLocked =
        !ps.unlockAllRows &&
        (!ps.isRowCompleted(
              writingSystem: writingSystem,
              rowTitle: 'Wa / N row',
            ) ||
            !ps.isRowCompleted(
              writingSystem: writingSystem,
              rowTitle: 'Pa row',
            ));

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
                // --- TITLE & SPEAKER TOGGLE ---[cite: 11]
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

                // --- BASIC KANA ROWS ---[cite: 11]
                ..._buildBasicRowsWithPrerequisites(
                  isHiragana,
                  writingSystem,
                  ps,
                ),

                const SizedBox(height: 32),

                // --- DAKUON & HANDAKUON ROWS ---[cite: 11]
                Row(
                  children: [
                    const Text(
                      'Dakuon',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (isDakuonLocked) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.textDark,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '(Finish Wa / N row)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ga row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'が', 'romaji': 'ga'},
                          {'kana': 'ぎ', 'romaji': 'gi'},
                          {'kana': 'ぐ', 'romaji': 'gu'},
                          {'kana': 'げ', 'romaji': 'ge'},
                          {'kana': 'ご', 'romaji': 'go'},
                        ]
                      : const [
                          {'kana': 'ガ', 'romaji': 'ga'},
                          {'kana': 'ギ', 'romaji': 'gi'},
                          {'kana': 'グ', 'romaji': 'gu'},
                          {'kana': 'ゲ', 'romaji': 'ge'},
                          {'kana': 'ゴ', 'romaji': 'go'},
                        ],
                  isLocked: isDakuonLocked,
                  prerequisiteName: 'Wa / N row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Za row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'ざ', 'romaji': 'za'},
                          {'kana': 'じ', 'romaji': 'ji'},
                          {'kana': 'ず', 'romaji': 'zu'},
                          {'kana': 'ぜ', 'romaji': 'ze'},
                          {'kana': 'ぞ', 'romaji': 'zo'},
                        ]
                      : const [
                          {'kana': 'ザ', 'romaji': 'za'},
                          {'kana': 'ジ', 'romaji': 'ji'},
                          {'kana': 'ズ', 'romaji': 'zu'},
                          {'kana': 'ゼ', 'romaji': 'ze'},
                          {'kana': 'ゾ', 'romaji': 'zo'},
                        ],
                  isLocked: isDakuonLocked,
                  prerequisiteName: 'Wa / N row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Da row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'だ', 'romaji': 'da'},
                          {'kana': 'ぢ', 'romaji': 'ji'},
                          {'kana': 'づ', 'romaji': 'zu'},
                          {'kana': 'で', 'romaji': 'de'},
                          {'kana': 'ど', 'romaji': 'do'},
                        ]
                      : const [
                          {'kana': 'ダ', 'romaji': 'da'},
                          {'kana': 'ヂ', 'romaji': 'ji'},
                          {'kana': 'ヅ', 'romaji': 'zu'},
                          {'kana': 'デ', 'romaji': 'de'},
                          {'kana': 'ド', 'romaji': 'do'},
                        ],
                  isLocked: isDakuonLocked,
                  prerequisiteName: 'Wa / N row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ba row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'ば', 'romaji': 'ba'},
                          {'kana': 'び', 'romaji': 'bi'},
                          {'kana': 'ぶ', 'romaji': 'bu'},
                          {'kana': 'べ', 'romaji': 'be'},
                          {'kana': 'ぼ', 'romaji': 'bo'},
                        ]
                      : const [
                          {'kana': 'バ', 'romaji': 'ba'},
                          {'kana': 'ビ', 'romaji': 'bi'},
                          {'kana': 'ブ', 'romaji': 'bu'},
                          {'kana': 'ベ', 'romaji': 'be'},
                          {'kana': 'ボ', 'romaji': 'bo'},
                        ],
                  isLocked: isDakuonLocked,
                  prerequisiteName: 'Wa / N row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Pa row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'ぱ', 'romaji': 'pa'},
                          {'kana': 'ぴ', 'romaji': 'pi'},
                          {'kana': 'ぷ', 'romaji': 'pu'},
                          {'kana': 'ぺ', 'romaji': 'pe'},
                          {'kana': 'ぽ', 'romaji': 'po'},
                        ]
                      : const [
                          {'kana': 'パ', 'romaji': 'pa'},
                          {'kana': 'ピ', 'romaji': 'pi'},
                          {'kana': 'プ', 'romaji': 'pu'},
                          {'kana': 'ペ', 'romaji': 'pe'},
                          {'kana': 'ポ', 'romaji': 'po'},
                        ],
                  isLocked: isDakuonLocked,
                  prerequisiteName: 'Wa / N row',
                ),

                const SizedBox(height: 32),

                // --- YOON (Contracted Sounds) ROWS ---[cite: 11]
                Row(
                  children: [
                    const Text(
                      'Yoon',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (isYoonLocked) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.textDark,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '(Finish Pa row)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Kya row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'きゃ', 'romaji': 'kya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'きゅ', 'romaji': 'kyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'きょ', 'romaji': 'kyo'},
                        ]
                      : const [
                          {'kana': 'キャ', 'romaji': 'kya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'キュ', 'romaji': 'kyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'キョ', 'romaji': 'kyo'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Sha row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'しゃ', 'romaji': 'sha'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'しゅ', 'romaji': 'shu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'しょ', 'romaji': 'sho'},
                        ]
                      : const [
                          {'kana': 'シャ', 'romaji': 'sha'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'シュ', 'romaji': 'shu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ショ', 'romaji': 'sho'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Cha row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'ちゃ', 'romaji': 'cha'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ちゅ', 'romaji': 'chu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ちょ', 'romaji': 'cho'},
                        ]
                      : const [
                          {'kana': 'チャ', 'romaji': 'cha'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'チュ', 'romaji': 'chu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'チョ', 'romaji': 'cho'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Nya row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'にゃ', 'romaji': 'nya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'にゅ', 'romaji': 'nyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'にょ', 'romaji': 'nyo'},
                        ]
                      : const [
                          {'kana': 'ニャ', 'romaji': 'nya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ニュ', 'romaji': 'nyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ニョ', 'romaji': 'nyo'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Hya row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'ひゃ', 'romaji': 'hya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ひゅ', 'romaji': 'hyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ひょ', 'romaji': 'hyo'},
                        ]
                      : const [
                          {'kana': 'ヒャ', 'romaji': 'hya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ヒュ', 'romaji': 'hyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ヒョ', 'romaji': 'hyo'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Mya row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'みゃ', 'romaji': 'mya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'みゅ', 'romaji': 'myu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'みょ', 'romaji': 'myo'},
                        ]
                      : const [
                          {'kana': 'ミャ', 'romaji': 'mya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ミュ', 'romaji': 'myu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ミョ', 'romaji': 'myo'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Rya row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'りゃ', 'romaji': 'rya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'りゅ', 'romaji': 'ryu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'りょ', 'romaji': 'ryo'},
                        ]
                      : const [
                          {'kana': 'リャ', 'romaji': 'rya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'リュ', 'romaji': 'ryu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'リョ', 'romaji': 'ryo'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Gya row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'ぎゃ', 'romaji': 'gya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ぎゅ', 'romaji': 'gyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ぎょ', 'romaji': 'gyo'},
                        ]
                      : const [
                          {'kana': 'ギャ', 'romaji': 'gya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ギュ', 'romaji': 'gyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ギョ', 'romaji': 'gyo'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Ja row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'じゃ', 'romaji': 'ja'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'じゅ', 'romaji': 'ju'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'じょ', 'romaji': 'jo'},
                        ]
                      : const [
                          {'kana': 'ジャ', 'romaji': 'ja'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ジュ', 'romaji': 'ju'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ジョ', 'romaji': 'jo'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Bya row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'びゃ', 'romaji': 'bya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'びゅ', 'romaji': 'byu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'びょ', 'romaji': 'byo'},
                        ]
                      : const [
                          {'kana': 'ビャ', 'romaji': 'bya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ビュ', 'romaji': 'byu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ビョ', 'romaji': 'byo'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
                const SizedBox(height: 16),

                _buildKanaRowGroup(
                  'Pya row',
                  isHiragana,
                  writingSystem,
                  isHiragana
                      ? const [
                          {'kana': 'ぴゃ', 'romaji': 'pya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ぴゅ', 'romaji': 'pyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ぴょ', 'romaji': 'pyo'},
                        ]
                      : const [
                          {'kana': 'ピャ', 'romaji': 'pya'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ピュ', 'romaji': 'pyu'},
                          {'kana': '', 'romaji': ''},
                          {'kana': 'ピョ', 'romaji': 'pyo'},
                        ],
                  isLocked: isYoonLocked,
                  prerequisiteName: 'Pa row',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the basic 10 rows while checking unlock status via ProgressService[cite: 11]
  List<Widget> _buildBasicRowsWithPrerequisites(
    bool isHiragana,
    String writingSystem,
    ProgressService ps,
  ) {
    final basicRowsData = isHiragana ? _basicHiraganaRows : _basicKatakanaRows;
    final List<Widget> widgets = [];

    for (int i = 0; i < _basicRowOrder.length; i++) {
      final rowKey = _basicRowOrder[i];
      bool isLocked = false;
      String prerequisiteName = '';

      // Sequentially verifies previous row completion[cite: 11]
      if (i > 0 && !ps.unlockAllRows) {
        final prevRowKey = _basicRowOrder[i - 1];
        prerequisiteName = prevRowKey;
        final bool prevCompleted = ps.isRowCompleted(
          writingSystem: writingSystem,
          rowTitle: prevRowKey,
        );
        isLocked = !prevCompleted;
      }

      final bool isCelebrated = (_celebratedRowKey == rowKey);

      widgets.add(
        _buildKanaRowGroup(
          rowKey,
          isHiragana,
          writingSystem,
          basicRowsData[rowKey]!,
          isLocked: isLocked,
          prerequisiteName: prerequisiteName,
          isCelebrated: isCelebrated,
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  // --- DYNAMIC CARD HEADER LINKED TO PROGRESS SERVICE ---[cite: 11]
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
    bool isCelebrated = false,
  }) {
    final charBgColor = isHiragana
        ? AppColors.lightSage
        : AppColors.lightSkyBlue;
    final buttonBgColor = isHiragana ? AppColors.sage : AppColors.skyBlue;

    Widget cardBody = AnimatedBuilder(
      animation: _unlockAnimController,
      builder: (context, child) {
        final double glowAlpha = isCelebrated ? _glowAnimation.value : 0.0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCelebrated
                  ? Color.lerp(
                      AppColors.textDark,
                      AppColors.unlockedGold,
                      glowAlpha,
                    )!
                  : AppColors.textDark,
              width: isCelebrated ? 2.5 : 1.5,
            ),
            boxShadow: [
              if (isCelebrated && glowAlpha > 0.05)
                BoxShadow(
                  color: AppColors.unlockedGold.withOpacity(0.4 * glowAlpha),
                  blurRadius: 12 * glowAlpha,
                  spreadRadius: 2 * glowAlpha,
                )
              else
                const BoxShadow(
                  color: AppColors.textDark,
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        rowName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCelebrated) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.unlockedGold,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.textDark,
                              width: 1.2,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_open_rounded,
                                size: 12,
                                color: AppColors.textDark,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'UNLOCKED! 🎉',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isLocked)
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: AppColors.textDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          prerequisiteName.isNotEmpty
                              ? 'Finish $prerequisiteName'
                              : 'Locked',
                          style: const TextStyle(
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
                    isLocked: isLocked,
                    onTap: () {
                      if (isLocked) {
                        TactileFeedback.error();
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
                    isLocked: isLocked,
                    onTap: () {
                      if (isLocked) {
                        TactileFeedback.error();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Finish $prerequisiteName first to unlock!',
                            ),
                          ),
                        );
                        return;
                      }
                      // Navigates directly to the lesson practice quiz without difficulty selectors[cite: 11]
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizScreen(
                            rowTitle: rowName,
                            writingSystem: writingSystem,
                            characters: chars,
                            difficulty: 'All',
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
      },
    );

    if (isCelebrated) {
      return ScaleTransition(scale: _scaleAnimation, child: cardBody);
    }

    return Opacity(opacity: isLocked ? 0.55 : 1.0, child: cardBody);
  }
}

// -----------------------------------------------------------------------------
// INTERACTIVE BUTTON COMPONENTS WITH TACTILE CLICKS & HAPTICS[cite: 11]
// -----------------------------------------------------------------------------

/// An interactive, 3D animated button for the individual Kana characters[cite: 11].
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
        TactileFeedback.press();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.isLocked) return;
        setState(() => _isPressed = false);
        if (widget.isSoundEnabled) {
          widget.onTapAudio();
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

/// An interactive, 3D animated button for the "Write" and "Learn" actions[cite: 11].
class Interactive3DActionButton extends StatefulWidget {
  final String label;
  final Color bgColor;
  final bool isLocked;
  final VoidCallback onTap;

  const Interactive3DActionButton({
    super.key,
    required this.label,
    required this.bgColor,
    this.isLocked = false,
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
        if (widget.isLocked) return;
        TactileFeedback.press();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.isLocked) {
          widget.onTap(); // Triggers the locked feedback callback
          return;
        }
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        transform: Matrix4.translationValues(
          0,
          (!widget.isLocked && _isPressed) ? 3.0 : 0.0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.isLocked
              ? widget.bgColor.withOpacity(0.45)
              : widget.bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.textDark, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, (!widget.isLocked && _isPressed) ? 0 : 3.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isLocked) ...[
              const Icon(
                Icons.lock_outline,
                size: 14,
                color: AppColors.textDark,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
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
