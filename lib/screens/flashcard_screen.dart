import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Loads user's custom TTS audio settings
import 'dart:math' as math;
import 'practice_screen.dart'; // Imports FlashcardQuestionType enum[cite: 13]
import '../services/progress_service.dart'; // Imports persistence service for kana mastery and review counts
import '../utils/tactile_feedback.dart'; // Imports tactile haptics and mechanical sound feedback

// --- COLOR PALETTE ---[cite: 13]
class AppColors {
  static const Color cream = Color(0xFFFDF8F3);
  static const Color beige = Color(0xFFEADFD1);
  static const Color sand = Color(0xFFDCC6A8);
  static const Color taupe = Color(0xFFC6B8A5);
  static const Color textDark = Color(0xFF5D534A);
  static const Color textLight = Color(0xFF8B8076);

  // 3D Rating button colors matching the cozy palette[cite: 13]
  static const Color ratingAgain = Color(
    0xFFE8A0A0,
  ); // Soft pastel red[cite: 13]
  static const Color ratingHard = Color(
    0xFFE8C396,
  ); // Soft pastel orange[cite: 13]
  static const Color ratingGood = Color(0xFFB7C9B2); // Sage green[cite: 13]
  static const Color ratingEasy = Color(
    0xFFA5C4E5,
  ); // Soft pastel blue[cite: 13]
}

class FlashcardScreen extends StatefulWidget {
  final String title;
  final List<Map<String, String>> cards;
  final FlashcardQuestionType questionType;

  const FlashcardScreen({
    super.key,
    required this.title,
    this.cards = const [
      {'kana': 'あ', 'romaji': 'a'},
      {'kana': 'い', 'romaji': 'i'},
      {'kana': 'う', 'romaji': 'u'},
      {'kana': 'え', 'romaji': 'e'},
      {'kana': 'お', 'romaji': 'o'},
    ],
    this.questionType = FlashcardQuestionType.kanaToRomaji,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late List<Map<String, String>> _flashcards;
  int _currentIndex = 0;
  bool _isFlipped = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Integrated native speech engine[cite: 13]
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _flashcards = List.from(widget.cards);
    if (_flashcards.isEmpty) {
      _flashcards = [
        {'kana': 'あ', 'romaji': 'a'},
      ];
    }

    _initTts();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // If initial question mode is audio-only, speak immediately[cite: 13]
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPlayCurrentCardAudio(isInitial: true);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _flipController.dispose();
    super.dispose();
  }

  /// Initializes TTS with user preferences saved from the Profile & Settings tab
  Future<void> _initTts() async {
    final prefs = await SharedPreferences.getInstance();
    final rate = prefs.getDouble('settings_speech_rate') ?? 0.5;
    final volume = prefs.getDouble('settings_speech_volume') ?? 1.0;

    await _flutterTts.setLanguage("ja-JP");
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.setVolume(volume);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speakKana(String kana) async {
    if (kana.isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.speak(kana);
  }

  void _checkAndPlayCurrentCardAudio({bool isInitial = false}) {
    final currentType = _resolveQuestionTypeForCurrentCard();
    if (currentType == FlashcardQuestionType.listening) {
      _speakKana(_flashcards[_currentIndex]['kana'] ?? '');
    }
  }

  /// Determines question type (handles mix mode dynamically per card index)[cite: 13]
  FlashcardQuestionType _resolveQuestionTypeForCurrentCard() {
    if (widget.questionType == FlashcardQuestionType.mix) {
      final modes = [
        FlashcardQuestionType.kanaToRomaji,
        FlashcardQuestionType.listening,
        FlashcardQuestionType.romajiToKana,
      ];
      return modes[_currentIndex % modes.length];
    }
    return widget.questionType;
  }

  void _toggleFlip() {
    if (_flipController.isAnimating) return;

    // Tactile tick when flipping card
    TactileFeedback.toggle();

    setState(() => _isFlipped = !_isFlipped);
    if (_isFlipped) {
      _flipController.forward();
      // Speak audio when card flips to reveal answer[cite: 13]
      _speakKana(_flashcards[_currentIndex]['kana'] ?? '');
    } else {
      _flipController.reverse();
    }
  }

  /// Rates memory recall, logs activity in ProgressService, and unlocks characters
  void _rateCard(String rating) {
    // 1. Always record reviewed card count in persistent storage
    ProgressService.instance.recordFlashcardReviewed();

    final currentKana = _flashcards[_currentIndex]['kana'] ?? '';

    // 2. If remembered ('Good' or 'Easy'), mark character as mastered and play success haptic
    if (rating == 'Good' || rating == 'Easy') {
      if (currentKana.isNotEmpty) {
        ProgressService.instance.markKanaMastered(currentKana);
      }
      TactileFeedback.success();
    } else {
      // Gentle error bump for 'Again' or 'Hard'
      TactileFeedback.error();
    }

    if (_currentIndex < _flashcards.length - 1) {
      _flipController.reverse().then((_) {
        setState(() {
          _currentIndex++;
          _isFlipped = false;
        });
        _checkAndPlayCurrentCardAudio();
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.textDark, width: 2),
        ),
        title: const Text(
          'Lesson Complete! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'You finished reviewing your selected kana cards.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textDark),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          GestureDetector(
            onTap: () {
              TactileFeedback.press();
              Navigator.pop(context); // Close dialog
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Return to practice setup
              } else {
                setState(() {
                  _currentIndex = 0;
                  _isFlipped = false;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.taupe,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.textDark, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.textDark,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Text(
                'Back to Practice',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentType = _resolveQuestionTypeForCurrentCard();

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar[cite: 13]
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
                    onPressed: () {
                      TactileFeedback.toggle();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentIndex + 1}/${_flashcards.length}',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Flippable 3D Flashcard[cite: 13]
            GestureDetector(
              onTap: () {
                if (!_isFlipped) _toggleFlip();
              },
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * math.pi;
                  final isFrontVisible = angle < (math.pi / 2);

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // 3D perspective depth[cite: 13]
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isFrontVisible
                        ? _buildCardSide(isFront: true, type: currentType)
                        : Transform(
                            transform: Matrix4.identity()..rotateY(math.pi),
                            alignment: Alignment.center,
                            child: _buildCardSide(
                              isFront: false,
                              type: currentType,
                            ),
                          ),
                  );
                },
              ),
            ),

            const Spacer(flex: 1),

            // Bottom Area: Instruction text vs 3D Rating buttons[cite: 13]
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _isFlipped
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const Padding(
                padding: EdgeInsets.only(bottom: 40.0),
                child: Text(
                  'Tap the card to reveal answer',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              secondChild: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Column(
                  children: [
                    const Text(
                      'How well did you remember it?',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _build3DRatingButton(
                          'Again',
                          AppColors.ratingAgain,
                          Icons.refresh,
                        ),
                        _build3DRatingButton(
                          'Hard',
                          AppColors.ratingHard,
                          Icons.sentiment_dissatisfied,
                        ),
                        _build3DRatingButton(
                          'Good',
                          AppColors.ratingGood,
                          Icons.sentiment_satisfied,
                        ),
                        _build3DRatingButton(
                          'Easy',
                          AppColors.ratingEasy,
                          Icons.sentiment_very_satisfied,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds Front or Back card view depending on current active question type[cite: 13]
  Widget _buildCardSide({
    required bool isFront,
    required FlashcardQuestionType type,
  }) {
    final currentCard = _flashcards[_currentIndex];
    final kana = currentCard['kana'] ?? '';
    final romaji = currentCard['romaji'] ?? '';

    Widget content;

    if (isFront) {
      // Front View[cite: 13]
      switch (type) {
        case FlashcardQuestionType.kanaToRomaji:
          content = Text(
            kana,
            style: const TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          );
          break;

        case FlashcardQuestionType.romajiToKana:
          content = Text(
            romaji,
            style: const TextStyle(
              fontSize: 90,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          );
          break;

        case FlashcardQuestionType.listening:
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 72,
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.textDark,
                ),
                onPressed: () {
                  TactileFeedback.press();
                  _speakKana(kana);
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to listen again',
                style: TextStyle(color: AppColors.textLight, fontSize: 14),
              ),
            ],
          );
          break;

        case FlashcardQuestionType.mix:
          content = Text(
            kana,
            style: const TextStyle(fontSize: 120, color: AppColors.textDark),
          );
          break;
      }
    } else {
      // Back View: Shows full character, romaji translation, and audio replay[cite: 13]
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            kana,
            style: const TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                romaji,
                style: const TextStyle(
                  fontSize: 32,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  TactileFeedback.press();
                  _speakKana(kana);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textDark, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.textDark,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      width: 290,
      height: 380,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textDark, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.textDark,
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(child: content),
    );
  }

  /// 3D tactile button for spaced repetition ratings[cite: 13]
  Widget _build3DRatingButton(String label, Color color, IconData icon) {
    return _Interactive3DRatingButton(
      label: label,
      color: color,
      icon: icon,
      onTap: () => _rateCard(label),
    );
  }
}

class _Interactive3DRatingButton extends StatefulWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _Interactive3DRatingButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_Interactive3DRatingButton> createState() =>
      _Interactive3DRatingButtonState();
}

class _Interactive3DRatingButtonState
    extends State<_Interactive3DRatingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        TactileFeedback.press();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            width: 62,
            height: 62,
            transform: Matrix4.translationValues(0, _isPressed ? 4.0 : 0.0, 0),
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textDark, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark,
                  offset: Offset(0, _isPressed ? 0 : 4.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(widget.icon, color: AppColors.textDark, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
